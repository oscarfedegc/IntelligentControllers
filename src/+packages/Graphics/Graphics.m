classdef Graphics < handle
    properties (Access = protected)
        
    end
    
    methods (Abstract = true)
        hiddenLayer();
        filterLayer();
        tracking();
        synapticWeights();
        controlSignals();
        estimation();
    end
end