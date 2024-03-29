% This abstract class represents the plants and their components: name,
% labels, number of states, and so on.
classdef Plant < handle
    properties (Access = protected)
        name, labels, symbols % {must Be String}
        nStates {mustBeInteger}
        states, Gamma, approximation, period {mustBeNumeric}
        perfTerms, nTerms {mustBeNumeric}
    end
    
    % Theses functions must be implemented in all inherited classes.
    methods (Abstract = true)
        measured();
        getCurrentState();
        addNoise();
        addPerturbation();
    end
    
    methods (Access = public)
        function setInitialStates(self, samples, initial)
            self.states = zeros(samples, self.nStates);
            self.states(1,:) = initial;
            self.approximation = self.states;
            self.perfTerms = zeros(samples, self.nTerms);
        end
        
        function setStateIter(self, state, iter)
            self.states(iter,:) = state;
        end
        
        function positions = reads(self, degree)
            positions = self.states(:,degree);
        end
        
        function positions = getPerformance(self, states)
            n = length(self.states(:,1)) - 1;
            positions = self.states(1:n, states);
        end
        
        function terms = getTerms(self)
            terms = self.perfTerms;
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