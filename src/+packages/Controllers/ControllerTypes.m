% This class has the different types of controllers that can be used.
% The user can add his own controls.
classdef ControllerTypes
    enumeration
        WavenetPID % Proportional, Integral and Derivative
        WavenetPMR % Proportional multiresolution
        ClassicalPID % Estatic Proportional, Integral and Derivative
    end
end