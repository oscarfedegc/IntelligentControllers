% This class calls the functions from a specific control strategy.
classdef Algorithm < handle
    properties (Access = protected)
        algorithm = IWIIRPID(); % Default control 
    end
    
    methods (Access = public)
        function setAlgorithm(self, algorithm)
            self.algorithm = algorithm;
        end
        
        function algorithm = getalgorithm(self)
            algorithm = self.algorithm;
        end
        
        function setup(self)
            self.algorithm.setup();
        end
        
        function builder(self)
            self.algorithm.builder();
        end
        
        function execute(self)
            self.algorithm.execute();
        end
        
        function charts(self)
            self.algorithm.charts();
        end
        
        function saveCSV(self)
            self.algorithm.saveCSV();
        end
    end
end