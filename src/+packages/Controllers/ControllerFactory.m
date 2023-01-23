% This class represents a "Factory" of Controllers and needs the
% ControllerTypes class.
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
                case ControllerTypes.PID
                    product = IPIDController();
                case ControllerTypes.PMR
                    product = IPMRController();
            end
        end
    end
end