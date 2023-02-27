classdef WavenetIIRScheme < handle
    properties (Access = public)
        allLearningRates {mustBeNumeric}
        outputIIRLayer, outputNetworkLayer {mustBeNumeric}
        inputLayer, filterOutputLayer, inputs, outputs, numberSynapticWeights {mustBeNumeric}
        synapticWeights, perfSynapticWeights, perfOutputNL {mustBeNumeric}
        functionMemory, derivativeMemory, outputLayer, synapticRange, perfWavenet {mustBeNumeric}
        hiddenNeuronLayer % {must be AbstractActivationFunction}
        filterLayer % {must be ImplementFilters}
        optimizer % {must be IOptimizer)
        isTraining % {must be Boolean}
    end
    
    methods (Abstract = true)
        evaluate();
        updateGradientDescent();
        getBehaviorApproximation();
    end
    
    methods (Abstract = true, Access = protected)
        calculateNetworkOutput();
        calculateCostFunction();
        calculateGradients();
        synapticWeightsCharts();
    end
    
    methods (Access = public)
        function setStatus(self, isTraining)
            if isTraining
                self.isTraining = 'X';
            else
                self.isTraining = 'Y';
            end
        end
        
        function status = getStatus(self)
            status = self.isTraining;
        end
        
        function setLearningRates(self, rates)
            self.allLearningRates = rates;
        end
        
        function rates = getLearningRates(self)
            rates = self.allLearningRates;
        end
        
        function charts(self)
            self.hiddenNeuronLayer.charts();
            self.filterLayer.charts();
            self.plotSynapticWeights();
        end
        
        function setInputs(self, values)
            self.inputLayer = values;
        end
        
        function weights = getSynapticWeights(self)
            weights = self.synapticWeights;
        end
        
        function setWnetIIROutputs(self, WnetVals, IITVals)
            self.outputIIRLayer = IITVals;
            self.outputNetworkLayer = WnetVals;
        end
        
        function perf = getBehaviorNeuronNetwork(self)
            perf = self.perfOutputNL;
        end
        
        function outputs = getOutputs(self)
            outputs = self.outputIIRLayer;
        end
        
        function [Gamma, Rho] = getApproximation(self)
            [Gamma, Rho] = self.filterLayer.getApproximation();
        end
        
        function instance = getHiddenNeuronLayer(self)
            instance = self.hiddenNeuronLayer;
        end
        
        function bootPerformance(self, samples)
            self.perfSynapticWeights = zeros(samples, self.outputs * self.hiddenNeuronLayer.getNeurons());
            self.perfWavenet = zeros(samples, self.outputs);
            self.hiddenNeuronLayer.bootPerformance(samples);
            self.filterLayer.bootPerformance(samples);
        end
        
        function setPerformance(self, iteration)
            cols = self.numberSynapticWeights;
            for item = 1:length(cols)-1
            	self.perfSynapticWeights(iteration, cols(item)+1:cols(item+1)) = self.synapticWeights(item,:);
            end
            self.perfWavenet(iteration,:) = self.outputNetworkLayer;
            self.hiddenNeuronLayer.setPerformance(iteration);
            self.filterLayer.setPerformance(iteration)
        end
        
        function buildNeuronLayer(self, functionType, functionSelected, neurons, inputs, outputs)
            self.hiddenNeuronLayer = FunctionFactory.create(functionType, functionSelected, neurons);
            
            self.inputs = inputs;
            self.outputs = outputs;
            self.numberSynapticWeights = 0:self.hiddenNeuronLayer.getNeurons(): neurons*outputs;
            self.inputLayer = zeros(1,inputs);
            self.filterOutputLayer = zeros(1,outputs);
            self.initialize();
        end
        
        function setNeuronInitialValues(self, scales, shifts)
            self.hiddenNeuronLayer.initialize(scales, shifts)
        end
        
        function setInitialValues(self, scales, shifts, weights, feedbacks, feedforwards)
            self.synapticWeights = weights;
            self.hiddenNeuronLayer.initialize(scales, shifts)
            self.filterLayer.update(feedbacks, feedforwards)
        end
        
        function perf = getPerfSynapticWeights(self)
            perf = self.perfSynapticWeights;
        end
        
        function perf = getPerfWavenet(self)
            perf = self.perfWavenet;
        end
        
        function outputs = getAmountOutputs(self)
            outputs = self.outputs;
        end
        
        function setSynapticRange(self, range)
            self.synapticRange = range;
        end
        
        function bootOptimazer(self, neurons, outputs, coeffsM, coeffsN)
            self.optimizer = IOptimizer(neurons, outputs, coeffsM, coeffsN);
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
        
        function setOutputs(self, filterOutputLayer)
            self.filterOutputLayer = filterOutputLayer;
        end
    end
end