classdef WavenetScheme < handle
    properties (Access = protected)
        inputLayer, outputLayer, synapticRange {mustBeNumeric}
        synapticWeights, sWeightLearningRate {mustBeNumeric}
        inputs, outputs, numberSynapticWeights {mustBeInteger}
        perfSynapticWeights, perfWavenet {mustBeNumeric}
        hiddenNeuronLayer % {must be AbstractActivationFunction}
    end
    
    methods (Abstract = true)
        setLearningRates();
        evaluate();
        update();
        getBehaviorApproximation();
        charts();
    end
    
    methods (Abstract = true, Access = protected)
        calculateNetworkOutput();
        calculateCostFunction();
        calculateGradients();
        synapticWeightsCharts();
        setBehavior();
        bootBehavior();
    end
    
    methods (Access = public)
        function rst = getCostFunction(self, error)
            rst = self.calculateCostFunction(error);
        end

        function [scales, shifts] = getCurrentValues(self)
            scales = self.hiddenNeuronLayer.getScales();
            shifts = self.hiddenNeuronLayer.getShifts();
        end
        
        function instance = getHiddenNeuronLayer(self)
            instance = self.hiddenNeuronLayer;
        end
            
        function setInputs(self, values)
            self.inputLayer = values;
        end
        
        function setSynapticWeights(self, weights)
            self.synapticWeights = weights;
        end
        
        function weights = getSynapticWeights(self)
            weights = self.synapticWeights;
        end
        
        function rate = getLearningRateWeigtht(self)
            rate = self.sWeightLearningRate;
        end
        
        function setNetworkOutputs(self, values)
            self.outputLayer = values;
        end
        
        function values = getOutputs(self)
            values = self.outputLayer;
        end
        
        function perf = getBehaviorWavenet(self)
            perf = self.perfWavenet;
        end
        
        function perf = getPerfSynapticWeights(self)
            perf = self.perfSynapticWeights;
        end
        
        function outputs = getAmountOutputs(self)
            outputs = self.outputs;
        end
        
        function setSynapticRange(self, range)
            self.synapticRange = range;
        end
        
        function bootPerformance(self, samples)
            self.perfSynapticWeights = zeros(samples, self.outputs * self.hiddenNeuronLayer.getNeurons());
            self.perfWavenet = zeros(samples, self.outputs);
            self.hiddenNeuronLayer.bootPerformance(samples);
            self.bootBehavior(samples);
        end
        
        function setPerformance(self, iteration)
            cols = self.numberSynapticWeights;
            for item = 1:length(cols)-1
            	self.perfSynapticWeights(iteration, cols(item)+1:cols(item+1)) = self.synapticWeights(item,:);
            end
            self.perfWavenet(iteration,:) = self.getOutputs();
            self.hiddenNeuronLayer.setPerformance(iteration);
            self.setBehavior(iteration);
        end
        
        function buildNeuronLayer(self, functionType, functionSelected, neurons, inputs, outputs)
            self.hiddenNeuronLayer = FunctionFactory.create(functionType, functionSelected, neurons);
            
            self.inputs = inputs;
            self.outputs = outputs;
            self.numberSynapticWeights = 0:self.hiddenNeuronLayer.getNeurons(): neurons*outputs;
            self.inputLayer = zeros(1,inputs);
            self.initialize();
        end
        
        function setNeuronInitialValues(self, scales, shifts)
            self.hiddenNeuronLayer.initialize(scales, shifts);
        end
    end
    
    methods (Access = protected)
        function initialize(self)
            self.synapticWeights = self.getInitialValues();
            self.hiddenNeuronLayer.initialize();
        end
        
        function synapticWeights = getInitialValues(self)
            randd = @(a,b,f,c) a + (b-a)*rand(f,c);
            
            if isempty(self.synapticRange)
                value = 0.01;
            else
                value = self.synapticRange;
            end
            
            synapticWeights = randd(value, -value, self.outputs, self.hiddenNeuronLayer.getNeurons());
        end
    end
end