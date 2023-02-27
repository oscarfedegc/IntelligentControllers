classdef IHLR < handle
    methods (Static = true)
        function result = getValue(instant, beta)
            M = 21;
            Omega = 2*pi/M;
            result = (0.005 + 0.005*cos(Omega*instant)) ./ beta;
        end
    end
end