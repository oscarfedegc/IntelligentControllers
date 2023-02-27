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
        
        function rst = MSE(target, estimated)
            difference = target - estimated;
            rst = sum(difference.^2) / length(target);
        end
        
        function rst = RMSE(target, estimated)            
            rst = sqrt(IMetrics.MSE(target, estimated));
        end
        
        function rst = SSE(val_target, val_estimated)
            rst = sum((val_target - val_estimated).^2);
        end
        
        function rst = SSY(val_target)
            average = sum(val_target)/length(val_target);
            rst = sum((val_target - average).^2);
        end
        
        function rst = R2(val_target, val_estimated)
            R2 = IMetrics.SSE(val_target, val_estimated) / IMetrics.SSY(val_target);
            
            rst = 1 - R2;
        end
        
        function rst = R2ANN(val_target, val_estimated)
            average = sum(val_target)/length(val_target);
            
            SSY = sum((val_target - average).^2);
            SSX = sum((val_estimated - average).^2);
            
            rst = 1 - SSY/SSX;
        end

        function showMedata()
            RESULTS = 'src/+repositories/results/WAVENET-IIR PMR';

            queryDirectory = sprintf('%s', RESULTS);
            queryFiles = dir(sprintf('%s/*/*X METRICS.csv', queryDirectory));

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
                sku_ = [sku_; cell(folder); cell(folder)];
            end

            varnames = [{'Configuration'}, varnames];
            data = [sku_, data];
            data = cell2table(data, 'VariableNames', varnames);
            disp(data)
        end
    end
end