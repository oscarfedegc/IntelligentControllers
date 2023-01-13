classdef Controller < handle
    properties
        currentGains, currentSignal, eTrackingMemory, updateRates {mustBeNumeric}
    end
    
    methods (Abstract)
        evaluate();
        autotune();
        updateMemory();
    end
    
    methods (Access = public)
        function setGains(self, gains)
            self.currentGains = gains;
        end
        
        function setUpdateRates(self, rates)
            self.updateRates = rates;
        end
        
        function signal = getSignal(self)
            signal = self.currentSignal;
        end
    end
end