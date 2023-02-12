classdef FilterTestings < handle
    properties (Access = public)
        instance = [];
    end
    
    methods (Access = public)
        function self = FilterTestings()
            return            
        end
        
        function run(self)
            randd = @(a,b,f,c) a + (b-a)*rand(f,c);
            
            inputs = 2;
            feedbacks = 4;
            feedforwards = 5;
            
            pSignal = 1e-3;
            
            tFinal = 15;
            period = 0.005;
            samples = round(tFinal/period);
            
            self.instance = IFilter(inputs, feedbacks, feedforwards, pSignal);
            self.instance.setLearningRates(ones(1,2));
            self.instance.initPerformance(samples)
            
            for iter = 1:samples
                inputs = randd(-5,5,1,2);
                fb_ = randd(-1,1,2,feedbacks);
                ff_ = randd(-1,1,2,feedforwards);
                self.instance.evaluate(inputs)
                self.instance.setPerformance(iter)
                self.instance.update(fb_, ff_)
            end
            
            self.instance.charts()
        end
    end
end