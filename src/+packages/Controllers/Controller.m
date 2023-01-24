% This abstract class represents the controller schemes and their
% components: the gains, the update rates, the control signals, and the
% tracking error memory for autotune.
classdef Controller < handle
    properties (Access = protected)
        gains, signal, eTrackingMemory, updateRates {mustBeNumeric}
        performance {mustBeNumeric}
    end
    
    % Theses functions must be implemented in all inherited classes, and have
    % to be called in the following order.
    methods (Abstract)
        setGains();
        evaluate();
        autotune();
        updateMemory();
        charts();
    end
    
    methods (Access = public)
        % Theses functions are the getters and setter to access the protected properties.
        function gains = getGains(self)
            gains = self.gains;
        end
        
        function setUpdateRates(self, rates)
            self.updateRates = rates;
        end
        
        function signal = getSignal(self)
            signal = self.signal;
        end
        
        % Initializes the arrays to store the controller behavior.
        %
        %   @param {int} samples Indicates the number of samples to be run in 
        %                        the simulation.
        %
        function initPerformance(self, samples)
            self.performance = zeros(samples, length(self.gains) + 1);
        end
        
        % Stores the current property values.
        %
        %   @param {int} iteration Indicates the current number of the sample.
        %
        function setPerformance(self, iteration)
            self.performance(iteration,:) = [self.gains, self.signal];
        end
        
        % Gets the all behavior for the generated simulation.
        %
        %   @returns {float[][]} performance Indicates the resulting matrix.
        %
        function performance = getPerformance(self)
            performance = self.performance;
        end
    end
end