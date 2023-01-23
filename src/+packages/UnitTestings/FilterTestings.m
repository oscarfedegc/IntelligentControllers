classdef FilterTestings < handle
    properties (Access = public)
        instance = [];
    end
    
    methods (Access = public)
        function self = FilterTestings()
            return            
        end
        
        function run(self)
            inputs = 2;
            feedbacks = 4;
            feedforwards = 5;
            
            pSignal = 1e-3;
            
            tFinal = 15;
            period = 0.005;
            samples = round(tFinal/period);
            
            self.instance = IFilter(inputs, feedbacks, feedforwards, pSignal);
            self.instance.setLearningRates(rand(1,2));
            self.instance.initPerformance(samples)
            
            for i = 1:samples
                self.instance.evaluate(rand(1,2))
                self.instance.setPerformance(i)
                self.instance.update(0.001*rand(2,feedbacks), 0.001*rand(2,feedforwards))
            end
            
            self.instance.charts()
        end
    end
end