% This class has the different types of controllers that can be used.
% The user can add his own controls.
classdef ControllerTypes
    enumeration
        PID % Proportional, Integral and Derivative
        PMR % Proportional multiresolution
        ClassicalPID
    end
end