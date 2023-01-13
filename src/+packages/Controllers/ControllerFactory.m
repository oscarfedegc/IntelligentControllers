classdef ControllerFactory
    methods (Static)
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