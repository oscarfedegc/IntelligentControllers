classdef PlantFactory
    methods (Static)
        function product = create()
            product = Helicopter2DOF();
        end
    end
end