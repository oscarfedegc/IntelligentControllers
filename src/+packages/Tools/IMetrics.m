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

        function showMedata()
            RESULTS = 'src/+repositories/results/WAVENET-IIR PMR';

            queryDirectory = sprintf('%s', RESULTS);
            queryFiles = dir(sprintf('%s/*/*METRICS.csv', queryDirectory));

            items = size(queryFiles,1);
            data = {};
            sku_ = {};
            varnames = [];

            for item = 1:items
                filename = queryFiles(item).name;
                folder = split(filename,' ');
                folder = folder(1);
                info = readtable(sprintf('%s/%s/%s', RESULTS, string(folder), filename));
                
                if item == 1
                    varnames = info.Properties.VariableNames;
                end
                data = [data; table2cell(info)];
                sku_ = [sku_; cell(folder)];
            end

            varnames = [{'Configuration'}, varnames];
            data = [sku_, data];
            data = cell2table(data, 'VariableNames', varnames);
            disp(data)
        end
    end
end