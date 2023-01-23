% This abstract class represents the control strategies and their
% components: the plant (or model to be controled) and its desired
% trajectories, the neural network topology, and the control schemes.
classdef Strategy < handle
    properties (Access = protected)
        model % {must be Plant}
        controllers % {must be Controller}
        neuralNetwork % {must be NetworkScheme}
        trajectories % {must be ITrajectories}
    end
    
    % Theses functions must be implemented in all inherited classes, and have
    % to be called in the following order.
    methods (Abstract = true)
        setup();
        builder();
        execute();
        saveCSV();
        charts();
    end
end