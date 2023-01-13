classdef Plant < handle
    properties (Access = public)
        name
        nStates {mustBeInteger}
        states, approximation, period {mustBeNumeric}
    end
    
    methods (Abstract = true)
        measured();
    end
    
    methods (Access = public)
        function initStates(self, samples, initial)
            self.states = zeros(samples, self.nStates);
            self.states(1,:) = initial;
            self.approximation = self.states;
        end
        
        function setPeriod(self, period)
            self.period = period;
        end
    end
end