classdef AbstractRepository < handle
    properties (Constant)
        FILEPATH = 'src/+repositories';
    end
    
    methods (Abstract = true)
        init();
        save();
        read();
        update();
    end
    
    methods (Access = protected)
        function str = generateFilename(self, activationFunction, args)
        end
    end
end