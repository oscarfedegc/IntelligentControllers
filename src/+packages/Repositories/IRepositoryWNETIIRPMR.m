classdef IRepositoryWNETIIRPMR < Repository
    properties (Access = public)
        FOLDER = 'WNET IIR PMR';
    end
    
    methods (Access = public)
        function self = IRepositoryWNETIIRPMR()
            return
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
            
            filename_ = lower([self.directory self.filename ' perfmodel.csv']);
            
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
            self.writeFilterLayer(instants, labels)
        end
        
        function writeControllerFiles(self)
            instants = self.trajectories.getInstants();
            instants = instants(self.indexes);
            labels = self.model.getLabels();
            
            for i = 1:length(self.controllers)
                performance = self.controllers(i).getPerformance();
                performance = [instants performance(self.indexes,:)];

                self.writeParameterFile(performance, ...
                    sprintf('perfcontroller %s', string(labels(i))))
            end
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
            
            self.writeParameterFile(scale, 'perfscales')
            self.writeParameterFile(shift, 'perfshifts')
            self.writeParameterFile(tau_, 'perftau')
            self.writeParameterFile(outputs, 'perfpsi')
            self.writeParameterFile(derivatives, 'perfderivatives')
        end
        
        function writeSynapticWeights(self, instants, labels)
            idxs = self.indexes;
            network = self.neuralNetwork;
            synaptics = network.getPerfSynapticWeights();
            instance = network.getHiddenNeuronLayer();
            
            outputs_ = network.getAmountOutputs();
            neurons = instance.getNeurons();
            
            for i = 1:outputs_
                cols = (i-1)*neurons + 1 : i*neurons;
                data = [instants synaptics(idxs,cols)];
                
                self.writeParameterFile(data, ...
                    sprintf('perfweights %s', string(labels(i))))
            end
        end
        
        function writeFilterLayer(self, instants, labels)
            [perfFeedbacks, perfFeedforwards, perfGamma, perfRho, perfOutputs] = ...
                self.neuralNetwork.filterLayer.getPerformance();
            
            outputs_ = self.neuralNetwork.filterLayer.outputs;
            amountN = self.neuralNetwork.filterLayer.coeffsM;
            amountM = self.neuralNetwork.filterLayer.coeffsN;
            
            for i = 1:outputs_
                cols = [(i-1)*amountN + 1, i*amountN];
                feedbacks_ = [instants perfFeedbacks(self.indexes,cols)];
                
                cols = [(i-1)*amountM + 1, i*amountM];
                forwards_ = [instants perfFeedforwards(self.indexes,cols)];
                
                self.writeParameterFile(feedbacks_, ...
                    sprintf('perffeedbacks %s', string(labels(i))))
                self.writeParameterFile(forwards_, ...
                    sprintf('perfforwards %s', string(labels(i))))
            end
            
            approximation = [instants perfGamma(self.indexes,:), ...
                perfRho(self.indexes,:), perfOutputs(self.indexes,:)];
            
            self.writeParameterFile(approximation, 'perfapprox')
        end
        
        function writeParameterFile(self, var, parameter)
            T = array2table(var);
            filename = lower([self.directory self.filename ' ' parameter '.csv']);
            
            writetable(T, filename)
        end
    end
end