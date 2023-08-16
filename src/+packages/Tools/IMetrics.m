% This class generate a simple table with the metrics from simulation data
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
        
        function rst = MAE(target, estimated)
            difference = abs(target - estimated);
            rst = sum(difference) / length(target);
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

        function showMetadata(ID, PREFIX)
            clc
            RESULTS = sprintf('src/+repositories/results/WAVENET-IIR %s', PREFIX);

            queryDirectory = sprintf('%s', RESULTS);
            queryFiles = dir(sprintf('%s/*/*%s METRICS.csv', queryDirectory, ID));

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
            
            samples = length(data.Configuration);
            
            fprintf('PITCH R2 Identification\n')
            for i = 1:2:samples
                funcs = split(data.Configuration(i),"-");
                fprintf('(%s, %f)\n', string(funcs(1)), data.R2idfPITCH(i))
            end
            
            fprintf('\nYAW R2 Identification\n')
            for i = 1:2:samples
                funcs = split(data.Configuration(i),"-");
                fprintf('(%s, %f)\n', string(funcs(1)), data.R2idfYAW(i))
            end
            
            fprintf('\nPITCH RMSE Identification\n')
            for i = 2:2:samples
                funcs = split(data.Configuration(i),"-");
                a = rad2deg(data.R2idfPITCH(i));
                b = rad2deg(data.R2idfYAW(i));
                c = 0.5 * (a + b);
                
                fprintf('%15s & %.4f & %.4f & %.4f \\\\\n', string(funcs(1)), a,b,c)
            end
            
            disp(' ')
        end
        
        function [R2, RMSE, MAE, AVG] = getInfoMetrics(target, estimated)
            error = target - estimated;
            
            R2 = IMetrics.R2(target, estimated);
            RMSE = IMetrics.RMSE(target, estimated);
            MAE = IMetrics.MAE(target, estimated);
            AVG = sum(error)/length(error);
        end
        
        function printInfoMetrics(title, R2, RMSE, MEA, AVG)
            fprintf(':: Metrics -- %s ::\n', title)
            fprintf('\t\tR2 = %8.5f\t\tRMSE = %8.5f\t\tMEA = %8.5f\t\tAVG = %8.5f\n',...
                R2, RMSE, MEA, AVG)
        end
    end
end