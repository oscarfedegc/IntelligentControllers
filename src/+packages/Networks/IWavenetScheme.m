classdef IWavenetScheme < NetworkScheme
    properties (Access = public)
        functionMemory, derivativeMemory {mustBeNumeric}
    end
    
    methods (Access = public)
        function self = IWavenetScheme()
        end
        
        function initInternalMemory(self)
            self.functionMemory = zeros(self.filterLayer.coeffsM, self.hiddenNeuronLayer.neurons);
            self.derivativeMemory = self.functionMemory;
        end
        
        function updateInternalMemory(self)
            self.functionMemory = self.updateMatrix(self.functionMemory, self.hiddenNeuronLayer.getFuncOutput());
            self.derivativeMemory = self.updateMatrix(self.functionMemory, self.hiddenNeuronLayer.getDerivative());
        end
        
        function evaluate(self, instant, inputs)
            self.setInputs(inputs);
            self.hiddenNeuronLayer.evaluate(instant);
            self.setNetworkOutputs(sum(inputs) * self.hiddenNeuronLayer.getFuncOutput() * self.synapticWeights');
            self.filterLayer.evaluate(self.getNetworkOutputs());
            self.setOutputs(self.filterLayer.getOutputs());
            self.updateInternalMemory();
        end
        
        function update(self, controlSignals, identificationErrors)
            self.paramterGradient(controlSignals, identificationErrors);
        end
    end
    
    methods (Access = protected)
        function rst = getCostFunction(~,error)
            rst = 0.5 * sum(error .^ 2);
        end
        
        function output = updateMatrix(~, matrix, newValues)
            [a,~] = size(matrix);
            output = [newValues; matrix(1:a-1,:)];
        end
        
        function paramterGradient(self, controlSignals, error)
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