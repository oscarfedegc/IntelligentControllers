classdef ControllerTestings < handle
    properties (Access = public)
        instance = [];
    end
    
    methods (Access = public)
        function self = ControllerTestings()
            return            
        end
        
        function run(self)
            tFinal = 15;
            period = 0.005;
            samples = round(tFinal/period);
            
            self.instance = ControllerFactory.create(ControllerTypes.PID);
            
            self.instance.setGains([10 .1 10]);
            self.instance.setUpdateRates([1 1 1]);
            self.instance.initPerformance(samples);
            
            for iter = 1:samples
                self.instance.evaluate();
                self.instance.setPerformance(iter);
                self.instance.autotune(0.1*rand(1,1), 0.1*rand(1,1), 0.1*rand(1,1))
            end
            
            self.instance.charts('Controller')
        end
    end
end