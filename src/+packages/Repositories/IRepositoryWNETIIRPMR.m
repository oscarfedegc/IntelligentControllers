classdef IRepositoryWNETIIRPMR < Repository
    properties (Access = public)
        FOLDER;
    end
    
    methods (Access = public)
        function self = IRepositoryWNETIIRPMR(folder)
            self.FOLDER = upper(folder);
            self.isCutOffResults = false;
        end

        function writeConfiguration(self)
            instance = self.neuralNetwork.getHiddenNeuronLayer();

            ctrls_ = length(self.controllers);
            
            neurons = instance.getNeurons();
            feedbacks = self.neuralNetwork.filterLayer.getCoeffsM();
            forwards = self.neuralNetwork.filterLayer.getCoeffsN();
            pSignal = self.neuralNetwork.filterLayer.getPersistentSignal();
            rates = self.neuralNetwork.getLearningRates();
            gains = [];

            for i = 1:ctrls_
                gains = [gains self.controllers(i).getGains()];
                rates = [rates self.controllers(i).getUpdateRates()];
            end

            gains_ = length(gains)/ctrls_;

            tags = {'gain ', 'Rate'};
            labels = self.model.getLabels();
            values = [neurons feedbacks forwards pSignal gains rates];
            varNames = self.getHeaderNames('iir', ctrls_, gains_, tags, labels);
            
            data = array2table(values,'VariableNames',varNames);
            
            writetable(data, self.configurationpath)
        end
        
        function writeModelFiles(self, states)
            instants = self.trajectories.getInstants();
            desired = rad2deg(self.trajectories.getAllReferences());
            measurement = rad2deg(self.model.getPerformance(states));
            approximation = rad2deg(self.neuralNetwork.getBehaviorApproximation());
            trackingError = desired - measurement;
            identifError = measurement - approximation;
            
            instants = instants(self.indexes);
            desired = desired(self.indexes,:);
            measurement = measurement(self.indexes,:);
            approximation = approximation(self.indexes,:);
            trackingError = trackingError(self.indexes,:);
            identifError = identifError(self.indexes,:);
            
            tags = {'ref', 'mes', 'est', 'epsilon', 'error'};
            labels = self.model.getLabels();
            
            T = [instants, desired, measurement, approximation, trackingError, identifError];
            T = array2table(T, 'VariableNames', self.getVarNames(tags, labels));
            
            self.writeParameterFile(T, 'PERFMODEL')
        end
        
        function  writeNeuralNetworkFiles(self)
            instants = self.trajectories.getInstants();
            instants = instants(self.indexes);
            labels = self.model.getLabels();
            
            self.writeHiddenNeuronLayer(instants)
            self.writeSynapticWeights(instants, labels)
            self.writeFilterLayer(instants, labels)
        end
        
        function writeControllerFiles(self, offsets)
            instants = self.trajectories.getInstants();
            instants = instants(self.indexes);
            labels = self.model.getLabels();
            
            for i = 1:length(self.controllers)
                temp = offsets(i) * ones(length(self.indexes),1);
                performance = self.controllers(i).getPerformance();
                performance(self.indexes,2) = performance(self.indexes,2) + temp;
                
                performance = [instants performance(self.indexes,:)];

                self.writeParameterFile(performance, ...
                    upper(sprintf('perfcontroller %s', string(labels(i)))))
            end
        end

        function writeFinalParameters(self)
            instance = self.neuralNetwork.getHiddenNeuronLayer();
            
            Scales = instance.getScales();
            Shifts = instance.getShifts();
            Weights = self.neuralNetwork.getSynapticWeights();
            Feedbacks = self.neuralNetwork.filterLayer.getFeedbacks();
            Forwards = self.neuralNetwork.filterLayer.getFeedforwards();
            
            self.writeArrayParameterFile(Scales,'SCALES')
            self.writeArrayParameterFile(Shifts,'SHIFTS')
            self.writeArrayParameterFile(Weights,'WEIGHTS')
            self.writeArrayParameterFile(Feedbacks,'FEEDBACKS')
            self.writeArrayParameterFile(Forwards,'FORWARDS')
        end
        
        function [scales, shifts, weights, feedbacks, feedforwards] = readParameters(self)
            scales = self.readArrayParameterFile('SCALES');
            shifts = self.readArrayParameterFile('SHIFTS');
            weights = self.readArrayParameterFile('WEIGHTS');
            feedbacks = self.readArrayParameterFile('FEEDBACKS');
            feedforwards = self.readArrayParameterFile('FORWARDS');
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