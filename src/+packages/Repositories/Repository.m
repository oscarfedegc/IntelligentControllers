classdef Repository < handle
    properties (Access = protected)
        RESULTS = 'src/+repositories/results/';
        CONFIGURATIONS = 'src/+repositories/configurations/' ;
    end
    
    properties (Access = protected)
        model % {must be Plant}
        controllers % {must be Controller}
        neuralNetwork % {must be NetworkScheme}
        trajectories % {must be ITrajectories}
        
        configurationpath
        directory, filename, functionname
        indexes
    end
    
    methods (Abstract = true)
        writeModelFiles();
        writeNeuralNetworkFiles();
        writeControllerFiles();
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
        
        function write(self, variation, metrics)
            self.setIndexes(variation)
            self.setFolderPath()
            self.writeModelFiles()
            self.writeNeuralNetworkFiles()
            self.writeControllerFiles()
            self.writeMetrics(metrics)
        end
        
        function writeConfiguration(self)
            neurons = self.neuralNetwork.hiddenNeuronLayer.getNeurons();
            backs = self.neuralNetwork.filterLayer.getCoeffsM();
            forwards = self.neuralNetwork.filterLayer.getCoeffsN();
            rates = [self.neuralNetwork.hiddenNeuronLayer.getLearningRates() ...
                self.neuralNetwork.sWeightLearningRate ...
                self.neuralNetwork.filterLayer.learningRates];
            pSignals = self.neuralNetwork.filterLayer.persistentSignal;
            
            data = [neurons backs forwards rates pSignals];
            
            writematrix(data, self.configurationpath)
        end
        
        function configuration = readConfiguration(self)            
            configuration = readmatrix(self.configurationpath);
        end
        
        function writeMetrics(self, values)
            metrics = {'ISE','IAE','IATE'};
            tags = {'idf','trk'};
            labels = self.model.getLabels();
            
            varnames = {'time'};
            
            for i = 1:length(labels)
                for j = 1:length(metrics)
                    for k = 1:length(tags)
                        varnames = strcat(varnames, '-', cellstr(metrics(j)), cellstr(tags(k)), upper(cellstr(labels(i))));
                    end
                end
            end
            varnames = split(varnames(:),'-');
            varnames = horzcat(varnames(2:length(varnames)))';
            
            T = array2table(values, 'VariableNames', varnames);
            writematrix(values, lower([self.directory self.filename ' metrics.csv']))
            clc
            disp(T)
        end
        
        function setFolderPath(self)
            switch class(self.neuralNetwork.hiddenNeuronLayer)
                case 'IWavelet'
                    name = string((self.neuralNetwork.hiddenNeuronLayer.wavelet));
                case 'IWindow'
                    name = string((self.neuralNetwork.hiddenNeuronLayer.window));
                case 'IAtomic'
                    name = 'atomic';
            end
            
            self.configurationpath = lower(sprintf('%s%s', self.CONFIGURATIONS, name));
            
            neurons = self.neuralNetwork.hiddenNeuronLayer.getNeurons();
            backs = self.neuralNetwork.filterLayer.getCoeffsM();
            forwards = self.neuralNetwork.filterLayer.getCoeffsN();
            
            suffix = lower(sprintf('/%s %02d%02d%02d/', name, neurons, backs, forwards));
            self.filename = lower(sprintf('/%s %02d%02d%02d', name, neurons, backs, forwards));
            self.directory = lower([self.RESULTS, self.FOLDER, suffix]);
            
            
            if exist(self.directory,'dir') == 0
                mkdir(self.directory)
            end
        end
    end
    
    methods (Access = protected)
        function setIndexes(self, variation)
            self.indexes = 1:variation:self.trajectories.getSamples();
        end
        
        function writeTableFile(~, matrix, directory, filename, parameter)
            T = array2table(matrix);
            filename = lower([directory filename ' ' parameter '.csv']);
            
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
    end
end