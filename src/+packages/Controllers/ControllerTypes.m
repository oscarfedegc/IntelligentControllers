% This class has the different types of controllers that can be used.
% The user can add his own controls.
classdef ControllerTypes
    enumeration
        ClassicalPID % Estatic Proportional, Integral and Derivative
        WavenetPID % Proportional-Integral-Derivative with a WNET-IIR
        WavenetPMR % Proportional multi-resolution with a WNET-IIR
    end
end