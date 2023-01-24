classdef Plant < handle
    properties (Access = protected)
        name
        nStates {mustBeInteger}
        states, Gamma, approximation, period {mustBeNumeric}
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
        
        function period = getPeriod(self)
            period = self.period;
        end
        
        function [Rho, Gamma] = getApproximation(self)
            Rho = self.approximation(1:2);
            Gamma = self.approximation(3:4);
        end
    end
end