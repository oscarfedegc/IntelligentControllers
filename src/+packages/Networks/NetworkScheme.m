classdef NetworkScheme < handle
    properties (Access = public)
        inputLayer, outputNetworkLayer, filterOutputLayer {mustBeNumeric}
        synapticWeights, sWeightLearningRate {mustBeNumeric}
        inputs, outputs, numberSynapticWeights {mustBeInteger}
        hiddenNeuronLayer % {must be AbstractActivationFunction}
        filterLayer % {must be ImplementFilters}
    end
    
    methods (Abstract = true)
        evaluate();
        update();
    end
    
    methods (Access = public)
        function setInputs(self, values)
            self.inputLayer = values;
        end
        
        function setSynapticWeights(self, weights)
            self.synapticWeights = weights;
        end
        
        function setLearningRates(self, rates)
            self.sWeightLearningRate = rates(3);
            self.hiddenNeuronLayer.setLearningRates(rates(1:2));
            self.filterLayer.setLearningRates(rates(4:5));
        end
        
        function setNetworkOutputs(self, values)
            self.outputNetworkLayer = values;
        end
        
        function values = getNetworkOutputs(self)
            values = self.outputNetworkLayer;
        end
        
        function outputs = getOutputs(self)
            outputs = self.filterOutputLayer;
        end
        
%         function initPerformanceArrays(self, samples)
%             self.perfSynapticWeights = zeros(samples, self.outputs * self.hiddenNeuronLayer.neurons);
%             self.hiddenNeuronLayer.initPerformanceArrays(samples);
%             self.filters.initPerformanceArrays(samples);
%         end
%         
%         function savePerformance(self, index)
%             cols = 0:self.hiddenNeuronLayer.neurons:self.elements;
%             for item = 1:length(cols)-1
%             	self.perfSynapticWeights(index, cols(item)+1:cols(item+1)) = self.synapticWeights(item,:);
%             end
%             self.hiddenNeuronLayer.savePerformance(index);
%             self.filters.savePerformance(index);
%         end
        
        function buildNeuronLayer(self, functionType, functionSelected, neurons, inputs, outputs)
            self.hiddenNeuronLayer = FunctionFactory.create(functionType, functionSelected, neurons);
            
            self.inputs = inputs;
            self.outputs = outputs;
            self.numberSynapticWeights = neurons * outputs;
            self.inputLayer = zeros(1,inputs);
            self.filterOutputLayer = zeros(1,outputs);
            self.initialize(outputs, neurons);
        end
        
        function setNeuronInitialValues(self, scales, shifts)
            self.hiddenNeuronLayer.initialize(scales, shifts);
        end
        
        function buildFilterLayer(self, inputs, coeffsN, coeffsM, pSignal)
            self.filterLayer = IFilter(inputs, coeffsN, coeffsM, pSignal);
        end
        
        function setFilterInitialValues(self, feedbacks, feedforwards, pSignal)
            self.filterLayer.initialize(feedbacks, feedforwards, pSignal);
        end
    end
    
    methods (Access = protected)
        function initialize(self, neurons, outputs)
            randd = @(a,b,f,c) a + (b-a)*rand(f,c);
            
            self.setSynapticWeights(randd(-1,1,neurons,outputs));
        end
        
        function setOutputs(self, filterOutputLayer)
            self.filterOutputLayer = filterOutputLayer;
        end
    end
end