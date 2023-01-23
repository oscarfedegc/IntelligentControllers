classdef FunctionTestings < handle
    properties (Access = public)
        instance = [];
    end
    
    methods (Access = public)
        function self = FunctionTestings()
            return            
        end
        
        function run(self)
            neurons = 4;
            type = FunctionList.window;
            option = WindowList.hanning;
            tFinal = 15;
            period = 0.005;
            samples = round(tFinal/period);
            
            self.instance = FunctionFactory.create(type, option, neurons);
            self.instance.setLearningRates(rand(1,2))
            self.instance.initPerformance(samples)
            
            for i = 1:samples
                self.instance.evaluate(i * 0.005)
                self.instance.setPerformance(i)
                self.instance.update(0.001*rand(1,neurons), 0.001*rand(1,neurons))
            end
            
            self.instance.charts()
        end
    end
end