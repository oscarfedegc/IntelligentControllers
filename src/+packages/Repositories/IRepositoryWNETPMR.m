classdef IRepositoryWNETPMR < Repository
    properties (Access = public)
        FOLDER = 'WNET PMR';
    end
    
    methods (Access = public)
        function self = IRepositoryWNETPMR()
            return
        end

        function writeConfiguration(self)
            instance = self.neuralNetwork.getHiddenNeuronLayer();
            
            neurons = instance.getNeurons();

            rates = [instance.getLearningRates() ...
                self.neuralNetwork.getLearningRateWeigtht()];

            data = array2table([neurons rates]);
            
            writetable(data, self.configurationpath)
        end
        
        function writeModelFiles(self)
            instants = self.trajectories.getInstants();
            desired = rad2deg(self.trajectories.getAllReferences());
            measurement = rad2deg(self.model.getPerformance());
            approximation = rad2deg(self.neuralNetwork.getBehaviorApproximation());
            trackingError = desired - measurement;
            identifError = measurement - approximation;
            
            instants = instants(self.indexes);
            desired = desired(self.indexes,:);
            measurement = measurement(self.indexes,:);
            approximation = approximation(self.indexes,:);
            trackingError = trackingError(self.indexes,:);
            identifError = identifError(self.indexes,:);
            
            filename_ = [self.directory self.filename ' PERFMODEL.csv'];
            
            tags = {'ref', 'mes', 'est', 'epsilon', 'error'};
            labels = self.model.getLabels();
            
            T = [instants, desired, measurement, approximation, trackingError, identifError];
            T = array2table(T, 'VariableNames', self.getVarNames(tags, labels));
            
            writetable(T, filename_)
        end
        
        function  writeNeuralNetworkFiles(self)
            instants = self.trajectories.getInstants();
            instants = instants(self.indexes);
            labels = self.model.getLabels();
            
            self.writeHiddenNeuronLayer(instants)
            self.writeSynapticWeights(instants, labels)
        end
        
        function writeControllerFiles(self)
            instants = self.trajectories.getInstants();
            instants = instants(self.indexes);
            labels = self.model.getLabels();
            
            for i = 1:length(self.controllers)
                performance = self.controllers(i).getPerformance();
                performance = [instants performance(self.indexes,:)];

                self.writeParameterFile(performance, ...
                    upper(sprintf('perfcontroller %s', string(labels(i)))))
            end
        end

        function writeFinalParameters(~)
        end
    end
    
    methods (Access = protected)        
        function writeHiddenNeuronLayer(self, instants)
            instance = self.neuralNetwork.getHiddenNeuronLayer();
            
            [scales, shifts, tau, funcOutput, dfuncOutput] = instance.getPerformance();
            
            scale = [instants scales(self.indexes,:)];
            shift = [instants shifts(self.indexes,:)];
            tau_ = [instants tau(self.indexes,:)];
            outputs = [instants funcOutput(self.indexes,:)];
            derivatives = [instants dfuncOutput(self.indexes,:)];
            
            self.writeParameterFile(scale, 'PERFSCALES')
            self.writeParameterFile(shift, 'PERFSHIFTS')
            self.writeParameterFile(tau_, 'PERFTAU')
            self.writeParameterFile(outputs, 'PERFPSI')
            self.writeParameterFile(derivatives, 'PERFDERIVATIVES')
        end
        
        function writeSynapticWeights(self, instants, labels)
            idxs = self.indexes;
            network = self.neuralNetwork;
            synaptics = network.getPerfSynapticWeights();
            instance = network.getHiddenNeuronLayer();
            
            outputs_ = network.getAmountOutputs();
            neurons = instance.getNeurons();
            
            for i = 1:outputs_
                cols = [(i-1)*neurons + 1, i*neurons];
                data = [instants synaptics(idxs,cols)];
                
                self.writeParameterFile(data, ...
                    upper(sprintf('perfweights %s', string(labels(i)))))
            end
        end
        
        function writeParameterFile(self, var, parameter)
            T = array2table(var);
            filename = [self.directory self.filename ' ' parameter '.csv'];
            
            writetable(T, filename)
        end
    end
end