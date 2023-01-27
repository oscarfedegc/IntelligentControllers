classdef IActorCriticScheme < NetworkScheme
    properties (Access = public)
        functionMemory, derivativeMemory, errorTD, rewardSignal, criticOutput {mustBeNumeric}
        perfErrorTD, perfRewardSignal, perfCriticOutput, actorOutputs {mustBeNumeric}
    end
    
    methods (Access = public)
        function self = IActorCriticScheme()
            return
        end
        
        function initInternalMemory(self)
            self.functionMemory = zeros(self.filterLayer.getCoeffsM(), self.hiddenNeuronLayer.getNeurons());
            self.derivativeMemory = self.functionMemory;
        end
        
        function updateInternalMemory(self)
            self.functionMemory = self.updateMatrix(self.functionMemory, self.hiddenNeuronLayer.getFuncOutput());
            self.derivativeMemory = self.updateMatrix(self.functionMemory, self.hiddenNeuronLayer.getDerivative());
        end
        
        function evaluate(self, instant, inputs)
            items = self.outputs;
            
            self.setInputs(inputs);
            self.hiddenNeuronLayer.evaluate(instant)
            
            networkOutputs = sum(inputs) * self.hiddenNeuronLayer.getFuncOutput() * self.getSynapticWeights();
            self.filterLayer.evaluate(self.getNetworkOutputs())
            filterOutputs = self.filterLayer.getOutputs();
            
            self.actorOutputs = filterOutputs(1:items-1);
            self.criticOutput = networkOutputs(items);
            
            self.setOutputs([self.actorOutputs self.criticOutputs]);
            self.updateInternalMemory();
        end
        
        function update(self, controlSignals, identificationErrors)
            self.paramGradients(controlSignals, identificationErrors);
        end
        
        function initBehavior(~,~)
        end
        
        function setBehavior(~,~)
        end
        
        function gamma = getGamma(self)
            gamma = self.filterLayer.getGamma();
        end
        
        function output = getCriticOutput(self)
            output = self.criticOutput;
        end
        
        function outputs = getActorOutputs(self)
            outputs = self.actorOutputs;
        end
        
        function plotSynapticWeights(self)
            cols = self.outputs;
            rows = self.hiddenNeuronLayer.getNeurons();
            weigths = self.perfSynapticWeights;
            
            tag = {'theta'; 'phi'};
            
            figure('Name','Synaptic weigths','NumberTitle','off','units','normalized','outerposition',[0 0 1 1]);
            
            for col = 1:cols
                for row = 1:rows
                    subplot(rows, cols, 1 + cols*(row-1))
                end
            end
            
            for row = 1:rows
                subplot(rows, cols, 1 + cols*(row-1))
                    plot(weigths(:, row + (col-1)),'r','LineWidth',1)
                    ylabel(sprintf('w_{\\%s_%i}', string(tag(col)), row))
                    
                if row == rows; xlabel('Samples, k'); end
                
                subplot(rows, cols, 2 + cols*(row-1))
                    plot(weigths(:,row),'r','LineWidth',1)
                    ylabel(sprintf('w_{\\%s_%i}', string(tag(2)), row))
            end
            xlabel('Samples, k')
        end
    end
    
    methods (Access = protected)
        function rst = getCostFunction(~,error)
            rst = 0.5 * sum(error .^ 2);
        end
        
        function calculateRewardSignal(~)
        end
        
        function calculateTemporalDifference(~)
        end
        
        function output = updateMatrix(~, matrix, newValues)
            [a,~] = size(matrix);
            output = [newValues; matrix(1:a-1,:)];
        end
        
        function paramGradients(self, controlSignals, error)
            U = sum(controlSignals);
            Ie = diag(error,0);
            If = error;
            tau = self.hiddenNeuronLayer.getTau();
            C = self.filterLayer.getFeedbacks();
            A = self.functionMemory;
            B = self.derivativeMemory;
            Z = self.filterLayer.iMemory;
            Y = self.filterLayer.oMemory;
            p = self.filterLayer.persistentSignal;
            
            DeltaW = U .* Ie * C * A;
            Deltab = U * If *(C * B);
            Deltaa = Deltab .* tau;
            DeltaC = U * Ie * Z;
            DeltaD = p .* Ie * Y;
            
            self.synapticWeights = self.synapticWeights - self.sWeightLearningRate .* DeltaW;
            self.hiddenNeuronLayer.update(Deltaa, Deltab);
            self.filterLayer.update(DeltaC, DeltaD);
        end
    end
end