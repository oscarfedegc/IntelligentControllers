classdef IRepositoryWNETIIRPMR < Repository
    properties (Access = public)
        FOLDER;
    end
    
    methods (Access = public)
        function self = IRepositoryWNETIIRPMR(folder)
            self.FOLDER = upper(folder);
        end

        function writeConfiguration(self)
            instance = self.neuralNetwork.getHiddenNeuronLayer();

            ctrls_ = length(self.controllers);
            
            neurons = instance.getNeurons();
            feedbacks = self.neuralNetwork.filterLayer.getCoeffsM();
            forwards = self.neuralNetwork.filterLayer.getCoeffsN();
            pSignal = self.neuralNetwork.filterLayer.getPersistentSignal();
            rates = [instance.getLearningRates() ...
                self.neuralNetwork.getLearningRateWeigtht() ...
                self.neuralNetwork.filterLayer.getLearningRates()];
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
            
            filename_ = [self.resultspath self.sku ' PERFMODEL.csv'];
            
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
                cols = [(i-1)*amountN + 1, i*amountN];
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
        
        function writeParameterFile(self, var, parameter)
            T = array2table(var);
            filename = [self.resultspath self.sku ' ' parameter '.csv'];
            
            writetable(T, filename)
        end
    end
end