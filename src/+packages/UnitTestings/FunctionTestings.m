classdef FunctionTestings < handle
    properties (Access = public)
        instance = [];
    end
    
    methods (Access = public)
        function self = FunctionTestings()
            return            
        end
        
        function run(self)
            neurons = 5;
            tFinal = 30;
            period = 0.005;
            samples = round(tFinal/period);
            type = FunctionList.wavelet;
            option = WaveletList.rasp2;
            learningRates = [0.1 0.1];
            
            self.instance = FunctionFactory.create(type, option, neurons);
            self.instance.setLearningRates(learningRates)
            self.instance.initPerformance(samples)
            self.instance.setScales(ones(1,neurons))
            self.instance.setShifts(rand(1,neurons))
            
            self.instance.getNeurons()
            self.instance.getScales()
            self.instance.getShifts()
            self.instance.evaluate(period)
            self.instance.getFuncOutput()
            self.instance.getTau()
            
%             for i = 1:samples
%                 self.instance.evaluate(i * period)
%                 self.instance.setPerformance(i)
%                 self.instance.update(rand(1,neurons), rand(1,neurons))
%             end
%             
%             self.instance.charts()
        end
    end
end