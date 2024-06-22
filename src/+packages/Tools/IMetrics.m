% This class generate a simple table with the metrics from simulation data
classdef IMetrics < handle
    methods (Static = true)
        function rst = ISE(vector, period)
            rst = 0;
            % rst = sum(period .* vector.^2);
            for i = 2:length(vector)
                rst = rst + period * (vector(i)^2 + vector(i-1)^2);
            end
            rst = rst / 2;
        end
        
        function rst = ITSE(vector, period)
            rst = 0;
            for i = 2:length(vector)
                rst = rst + period * (i-1) * (vector(i)^2 + vector(i-1)^2);
            end
            rst = rst / 2;
        end

        function rst = IAE(vector, period)
            % rst = sum(period .* abs(vector));
            rst = 0;
            for i = 2:length(vector)
                rst = rst + period * abs(vector(i) + vector(i-1));
            end
            rst = rst / 2;
        end
        
        function rst = IATE(vector, period)
            rst = 0;
            for i = 2:length(vector)
                rst = rst + period * (i-1) * abs(vector(i) + vector(i-1));
            end
            rst = rst / 2;
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

        function showPerformance()
            clc, format shortG
            RST_WAVELETS = sprintf('src/+repositories/results/WAVENET-IIR PID/FLATTOP2-J03-M04-N02-G03-T060-T01-Y/FLATTOP2-J03-M04-N02-G03-T060-T01-Y PERFMODEL.csv');
            RST_CLASSICAL = sprintf('src/+repositories/results/CLASSICAL PID/POLYWOG3-J03-M04-N02-G03-T060-T01-Y/POLYWOG3-J03-M04-N02-G03-T060-T01-Y PERFMODEL.csv');

            wavelets = readtable(RST_WAVELETS);
            classical = readtable(RST_CLASSICAL);

            metrics = zeros(4,6);
            period = 0.005;

            % Pitch and yaw tracking error
            errors = [wavelets.epsilonpitch, wavelets.epsilonyaw, classical.epsilonpitch, classical.epsilonyaw];

            for col = 1:4
                ISE  = IMetrics.ISE(errors(:,col), period);
                ITSE = IMetrics.ITSE(errors(:,col), period);
                IAE  = IMetrics.IAE(errors(:,col), period);
                IATE = IMetrics.IATE(errors(:,col), period);

                metrics(:,col) = [ISE, ITSE, IAE, IATE]';
            end

            metrics(:,5) = 100 * (metrics(:,3) - metrics(:,1)) ./ metrics(:,3);
            metrics(:,6) = 100 * (metrics(:,4) - metrics(:,2)) ./ metrics(:,4);
            IMetrics.printTableRst(metrics)
        end

        function printTableRst(metrics)
            IMetrics.printRow('ISE', metrics(1,:))
            IMetrics.printRow('ITSE', metrics(2,:))
            IMetrics.printRow('IAE', metrics(3,:))
            IMetrics.printRow('IATE', metrics(4,:))
        end

        function printRow(metric, values)
            fprintf('%4s ', metric)

            for i = 1:length(values)
                if i < 5
                    fprintf('& \\num{%05.2f} ', values(i))
                else
                    fprintf('& \\qty{%05.2f}{\\percent} ', values(i))
                end
            end

            fprintf('\\\\\n')
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