classdef IMetrics < handle
    methods (Static = true)
        function rst = ISE(vector, period)
            rst = sum(period .* vector.^2);
        end
        
        function rst = IAE(vector, period)
            rst = sum(period .* abs(vector));
        end
        
        function rst = IATE(vector, period)            
            for i = 1:length(vector)
                k = i-1;
                vector(i) = period * k * abs(vector(i));
            end
            rst = sum(vector);
        end
    end
end