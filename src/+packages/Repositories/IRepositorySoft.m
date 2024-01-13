classdef IRepositorySoft < Repository
    properties (Access = public)
        FOLDER;
    end
    
    methods (Access = public)
        function self = IRepositorySoft(folder)
            self.FOLDER = upper(folder);
            self.isCutOffResults = false;
        end

        function writeConfiguration(~)
            return
        end
        
        function writeResults(self, period, samples, measurement, controls)
            labels = {'1', '2', '3'};
            instants = (0:period:(samples-1)*period)';
            self.indexes = 1:1:samples;
            
            self.writeModelFiles(instants, measurement, controls, labels)
            self.writeNeuralNetworkFiles(instants, labels)
        end
        
        function writeModelFiles(self, instants, measurement, controls, labels)            
            approximation = rad2deg(self.neuralNetwork.getBehaviorApproximation());
            identifError = measurement - approximation;
            
            instants = instants(self.indexes);
            measurement = measurement(self.indexes,:);
            approximation = approximation(self.indexes,:);
            identifError = identifError(self.indexes,:);
            
            tags = {'mes', 'est', 'epsilon', 'tau'};
            
            T = [instants, measurement, approximation, identifError, controls];
            T = array2table(T, 'VariableNames', self.getVarNames(tags, labels));
            
            self.writeParameterFile(T, 'PERFMODEL')
        end
        
        function writeNeuralNetworkFiles(self, instants, labels)
            self.writeHiddenNeuronLayer(instants)
            self.writeSynapticWeights(instants, labels)
            self.writeFilterLayer(instants, labels)
        end
        
        function writeControllerFiles(~,~)
            return
        end

        function writeFinalParameters(~)
            return
        end
        
        function [scales, shifts, weights, feedbacks, feedforwards] = readParameters(~)
            scales = [];
            shifts = [];
            weights = [];
            feedbacks = [];
            feedforwards = [];
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
                cols = (i-1)*neurons + 1 : i*neurons;
                data = [instants synaptics(idxs,cols)];
                
                self.writeParameterFile(data, ...
                    upper(sprintf('perfweights %s', string(labels(i)))))
            end
        end
        
        function writeFilterLayer(self, instants, labels)
            [perfFeedbacks, perfFeedforwards, perfGamma, perfRho, perfOutputs] = ...
                self.neuralNetwork.filterLayer.getPerformance();
            
            outputs_ = self.neuralNetwork.filterLayer.outputs;
            amountN = self.neuralNetwork.filterLayer.coeffsM;
            amountM = self.neuralNetwork.filterLayer.coeffsN;
            
            for i = 1:outputs_
                cols = [(i-1)*amountN + 1: i*amountN];
                feedbacks_ = [instants perfFeedbacks(self.indexes,cols)];
                
                cols = [(i-1)*amountM + 1, i*amountM];
                forwards_ = [instants perfFeedforwards(self.indexes,cols)];
                
                self.writeParameterFile(feedbacks_, ...
                    upper(sprintf('perffeedbacks %s', string(labels(i)))))
                self.writeParameterFile(forwards_, ...
                    upper(sprintf('perfforwards %s', string(labels(i)))))
            end
            
            approximation = [instants perfGamma(self.indexes,:), ...
                perfRho(self.indexes,:), perfOutputs(self.indexes,:)];
            
            self.writeParameterFile(approximation, 'PERFAPPROX')
        end
    end
end