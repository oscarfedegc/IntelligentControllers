% This abstract class represents the methods to generate the plot from
% simulation data.
classdef Graphics < handle
    
    % Theses functions must be implemented in all inherited classes.
    methods (Abstract = true)
        hiddenLayer();
        filterLayer();
        tracking();
        synapticWeights();
        controlSignals();
        estimation();
    end
end