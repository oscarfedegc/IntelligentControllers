classdef IFunctionRepository < AbstractRepository
    properties (Access = public)
        prefix
        perfScales, perfShifts, perfTau, perfFunc, perfdFunc {mustBeNumeric}
    end
    
    methods (Access = public)
        function self = IFunctionRepository(prefix)
            self.prefix = string(prefix);
        end
        
        function init(self, samples, neurons)
            self.perfScales = zeros(samples, neurons);
            self.perfShifts = self.perfScales;
            self.perfTau = self.perfScales;
            self.perfFunc = self.perfScales;
            self.perfdFunc = self.perfScales;
        end
        
        function read(self)
        end
        
        function update(self, index, args)
            self.perfScales(index,:) = args(1,:);
            self.perfShifts(index,:) = args(2,:);
            self.perfTau(index,:) = args(3,:);
            self.perfFunc(index,:) = args(4,:);
            self.perfdFunc(index,:) = args(5,:);
        end
        
        function save(self, time, currentValue)
            
        end
    end
end