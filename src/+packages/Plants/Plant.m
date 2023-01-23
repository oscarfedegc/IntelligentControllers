classdef Plant < handle
    properties (Access = protected)
        name
        nStates {mustBeInteger}
        states, approximation, period {mustBeNumeric}
    end
    
    methods (Abstract = true)
        measured();
    end
    
    methods (Access = public)
        function setInitialStates(self, samples, initial)
            self.states = zeros(samples, self.nStates);
            self.states(1,:) = initial;
            self.approximation = self.states;
        end
        
        function positions = reads(self, degree)
            positions = self.states(:,degree);
        end
        
        function setPeriod(self, period)
            self.period = period;
        end
    end
end