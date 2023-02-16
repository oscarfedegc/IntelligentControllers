classdef ISamplePopulation < handle
    methods (Static = true)
        function interval = getIndexes(population)
            sampleSize = ISamplePopulation.getSize(population);
            interval = round(population / sampleSize);
        end
    end

    methods (Static = true, Access = protected)
        function size = getSize(population)
            if population < 2000
                size = population;
                return
            end

            marginError = 0.01;
            possibility = 0.5;
            alfa = 1.96; % Corresponds to NC = 95 percent

            temp = alfa^2 * possibility * (1 - possibility);
            
            size = (population * temp)/(marginError^2 * (population-1) + temp);
        end
    end
end