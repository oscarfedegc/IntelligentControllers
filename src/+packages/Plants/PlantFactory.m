classdef PlantFactory
    methods (Static)
        function product = create(type)
            switch type
                case PlantList.helicopter2DOF
                    product = Helicopter2DOF();
                case PlantList.crazyflie6DOF
                    product = Crazyflie6DOF();
            end
        end
    end
end