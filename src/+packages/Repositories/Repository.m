% This abstract class represents the strategies for generating output
% files: system behavior and initial values.
classdef Repository < handle
    properties (Access = protected)
        RESULTS = 'src/+repositories/results/';
        CONFIGURATIONS = 'src/+repositories/configurations/';
        VALUES = 'src/+repositories/values/';
        TIME_LIMIT = 10;
    end
    
    % Theses functions must be implemented in all inherited classes.
    properties (Access = protected)
        model % {must be Plant}
        controllers % {must be Controller}
        neuralNetwork % {must be NetworkScheme}
        trajectories % {must be ITrajectories}
        
        configurationpath, valuespath, resultspath, cutrstspath, skuResults, skuParams % {must be String}
        indexes {mustBeInteger}
        isCutOffResults % {must be Boolean}
    end
    
    % Theses functions must be implemented in all inherited classes to
    % write the data to the output files.
    methods (Abstract = true)
        writeConfiguration()
        writeModelFiles()
        writeNeuralNetworkFiles()
        writeControllerFiles()
        writeFinalParameters()
        readParameters()
    end
    
    methods (Access = public)
        function setModel(self,model)
            self.model = model;
        end
        
        function setControllers(self, controllers)
            self.controllers = controllers;
        end
        
        function setNeuralNetwork(self, network)
            self.neuralNetwork = network;
        end
        
        function setTrajectories(self, trajectories)
            self.trajectories = trajectories;
        end
        
        function setCutOffResults(self, option)
            self.isCutOffResults = option;
            self.setIndexes()
        end
        
        function write(self, metrics, states, offsets)
            self.setFolderPath()
            self.writeModelFiles(states)
            self.writeNeuralNetworkFiles()
            self.writeControllerFiles(offsets)
            self.writeMetrics(metrics)
        end

        function configuration = readConfiguration(self)
            configuration = readmatrix(self.configurationpath);
        end
        
        function writeMetrics(self, values)
            varnames = self.getMetricHeaders(2);
            
            T = array2table(values, 'VariableNames', varnames);
            writetable(T,[self.resultspath self.skuResults ' METRICS.csv'])
            
            if ~self.isCutOffResults
                disp(' '), disp(T)
            end
        end
        
        function setFolderPath(self)
            self.getFoldersName()
            
            if exist(self.resultspath,'dir') == 0
                mkdir(self.resultspath)
            end
            
            if exist(self.cutrstspath,'dir') == 0
                mkdir(self.cutrstspath)
            end

            if exist(self.valuespath,'dir') == 0
                mkdir(self.valuespath)
            end

            if exist(self.CONFIGURATIONS,'dir') == 0
                mkdir(self.CONFIGURATIONS)
            end
        end
    end
    
    methods (Access = protected)
        function getFoldersName(self)
            self.getSKU()
            
            self.configurationpath = sprintf('%s%s-SETUP.csv',  self.CONFIGURATIONS, self.skuResults);
            self.valuespath = sprintf('%s/%s%s/', self.VALUES, self.FOLDER, self.skuParams);
            self.resultspath = sprintf('%s%s%s/', self.RESULTS, self.FOLDER, self.skuResults);
            self.cutrstspath = sprintf('%s%s%s-C010/', self.RESULTS, self.FOLDER, self.skuResults);
        end

        function getSKU(self)
            instance = self.neuralNetwork.getHiddenNeuronLayer();
            status = self.neuralNetwork.getStatus();
            
            switch class(instance)
                case 'IWavelet'
                    name = string((instance.wavelet));
                case 'IWindow'
                    name = string((instance.window));
                case 'IAtomic'
                    name = 'atomic';
            end

            neurons = instance.getNeurons();
            samples = self.trajectories.getSamples();
            finalTime = self.trajectories.getTime(samples);

            var = 'G';
            fixed = 0;

            if isa(self.controllers(1), 'IWavenetPMR')
                var = 'L';
                fixed = 1;
            end

            try
                gains = length(self.controllers(1).getGains());
            catch
                gains = 0;
            end
            
            try
                feedbacks = self.neuralNetwork.filterLayer.getCoeffsM();
                forwards = self.neuralNetwork.filterLayer.getCoeffsN();

                temp = sprintf('/%s-J%02d-M%02d-N%02d', name, neurons, feedbacks, forwards);
            catch
                temp = sprintf('/%s-J%02d', name, neurons);
            end

            self.skuParams = upper(sprintf('%s', temp));
            self.skuResults = upper(sprintf('%s-%s%02d-T%04d-%s', temp, var, gains-fixed, finalTime, status));
        end

        function setIndexes(self)
            samples = self.trajectories.getSamples();
            tFinal = self.trajectories.getInstants();
            tFinal = tFinal(samples);
            
            if self.isCutOffResults
                if self.TIME_LIMIT > tFinal
                    self.TIME_LIMIT = tFinal;
                end
                self.indexes = 1:2:round(self.TIME_LIMIT/self.model.getPeriod());
            else
                variation = ISamplePopulation.getIndexes(samples);
                self.indexes = 1:variation:samples;
            end
        end
        
        function writeTableFile(~, matrix, directory, filename, parameter)
            T = array2table(matrix);
            filename = upper([directory filename ' ' parameter '.csv']);
            
            writetable(T, filename)
        end
        
        function varnames = getVarNames(~, params, labels)
            varnames = {'time'};
            
            for i = 1:length(params)
                for j = 1:length(labels)
                    varnames = strcat(varnames, '-', cellstr(params(i)), cellstr(labels(j)));
                end
            end
            
            varnames = split(varnames(:),'-');
            varnames = horzcat(varnames(:))';
        end

        function varnames = getHeaderNames(~, type, controls, gains, params, labels)
            if strcmp(type,'iir')
                varnames = {'neurons-feedbacks-feedforwards-persistent'};
                varrates = {'scaleRate', 'shiftRate', 'synapticRate', 'feedbackRate', 'forwardRate'};
            else
                varnames = {'neurons'};
                varrates = {'neuron rate'};
            end

            for i = 1:controls
                for j = 1:gains
                    varnames = strcat(varnames, '-', cellstr(labels(i)), string(j));
                end
            end

            for i = 1:length(varrates)
                varnames = strcat(varnames, '-', cellstr(varrates(i)));
            end

            for i = 1:controls
                for j = 1:gains
                    varnames = strcat(varnames, '-', cellstr(labels(i)), cellstr(params(2)), string(j));
                end
            end

            varnames = varnames(1);
            varnames = split(varnames(:),'-');
            varnames = horzcat(varnames(:))';
        end

        function varnames = getMetricHeaders(self, first)
            metrics = {'R2'};
            tags = {'trk','idf'};
            labels = self.model.getLabels();
            
            varnames = {'name'};
            
            for i = 1:length(labels)
                for j = 1:length(metrics)
                    for k = 1:length(tags)
                        varnames = strcat(varnames, '-', cellstr(metrics(j)), cellstr(tags(k)), upper(cellstr(labels(i))));
                    end
                end
            end
            varnames = split(varnames(:),'-');
            varnames = horzcat(varnames(first:length(varnames)))';
        end
        
        function writeParameterFile(self, data, parameter)
            if isa(data,'table')
                T = data;
            else
                T = array2table(data);
            end
            
            if self.isCutOffResults
                filename = [self.cutrstspath self.skuResults ' ' parameter '.csv'];
            else
                filename = [self.resultspath self.skuResults ' ' parameter '.csv'];
            end
            
            writetable(T, filename)
        end
        
        function writeArrayParameterFile(self, data, parameter)
            filename = [self.VALUES self.FOLDER self.skuParams self.skuParams ' ' parameter '.csv'];
            writematrix(data, filename)
        end
        
        function data = readArrayParameterFile(self, parameter)
            filename = [self.VALUES self.FOLDER self.skuParams self.skuParams ' ' parameter '.csv'];
            data = load(filename);
        end
    end
end