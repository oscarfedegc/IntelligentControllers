classdef Context < handle
    properties (Access = private)
        strategy = IWIIRPID(); % Default value
    end
    
    methods (Access = public)        
        function trajectoryBuilder(self, tFinal, period, pitchReference, yawReference)
            self.strategy.trajectoryBuilder(tFinal, period, pitchReference, yawReference);
        end
        
        function modelBuilder(self, period, initialPositions)
            self.strategy.modelBuilder(period, initialPositions);
        end
        
        function controllerBuilder(self)
            self.strategy.controllerBuilder();
        end
        
        function networkBuilder(self, functionType, selection, neurons, inputs, outputs, coeffsM, coeffsN)
            self.strategy.networkBuilder(functionType, selection, neurons, inputs, outputs, coeffsM, coeffsN);
        end
        
        function execute(self)
            self.strategy.execute();
        end
        
        function setStrategy(self, strategy)
            self.strategy = strategy;
        end
        
        function strategy = getStrategy(self)
            strategy = self.strategy;
        end
    end
end