% This class represents a "Factory" of Controllers and needs the
% ControllerTYpes class.
classdef ControllerFactory
    methods (Static)
        % Calls a specific implementation of controller.
        %
        %   @params {ControllerTypes} controllerType Indicates the controller
        %                                            to implements.
        %   @returns {Controller} product Indicates the object created by the factory.
        %
        function product = create(controllerType)
            switch controllerType
                case ControllerTypes.WavenetPID
                    product = IWavenetControllerPID();
                case ControllerTypes.WavenetPMR
                    product = IWavenetControllerPMR();
                case ControllerTypes.ClassicalPID
                    product = IClassicalControllerPID();
            end
        end
    end
end