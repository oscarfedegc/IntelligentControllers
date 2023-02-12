classdef FunctionTestings < handle
    properties (Access = public)
        instance = [];
    end
    
    methods (Access = public)
        function self = FunctionTestings()
            return            
        end
        
        function run(self)
            randd = @(a,b,f,c) a + (b-a)*rand(f,c);
            
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
            
            temp = 0;
            
            for i = 1:samples
                self.instance.evaluate(i * period)
                self.instance.setPerformance(i)
                
                if temp == 200
                    a_  = randd(-1,1,1,neurons);
                    b_  = randd(-1,1,1,neurons);
                    temp = 0;
                else
                    a_  = randd(0,0,1,neurons);
                    b_  = randd(0,0,1,neurons);
                end
                temp = temp + 1;
                self.instance.update(a_, b_)
            end
            
            self.instance.charts()
        end
    end
end