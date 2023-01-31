% This abstract class represents the control strategies and their
% components: the plant (or model to be controled) and its desired
% trajectories, the neural network topology, and the control schemes.
classdef Strategy < handle    
    properties (Access = protected)
        model % {must be Plant}
        controllers % {must be Controller}
        neuralNetwork % {must be NetworkScheme}
        trajectories % {must be ITrajectories}
        repository % {must be IRepository}
    end
    
    properties (Access = protected)
        tFinal, period {mustBeNumeric}
        plantType % {must be PlantList}
        controllerType % {must be ControllerTypes}
        references, controllerGains, controllerRates % {must be Structure}
        
        nnaType % {must be NetworkList}
        functionType % {must be FuntionList}
        functionSelected % {must be WaveletList, WindowList or []}
        amountFunctions, feedbacks, feedforwards, inputs, outputs {mustBeInteger}
        learningRates, persistentSignal, initialStates {mustBeNumeric}
        
        fNormApprox, fNormErrors, indexes {mustBeNumeric}
        
        directory, filename % {must be String or path}
        metrics {mustBeNumeric}
    end
    
    % Theses functions must be implemented in all inherited classes, and have
    % to be called in the following order.
    methods (Abstract = true)
        setup();
        builder();
        execute();
        saveCSV();
        charts();
    end
    
    methods (Access = protected)
        % This function 
        function fNormErrors = setNormError(self, fNormErrors, iter)
            [Rho, Gamma] = self.model.getApproximation();
            [RhoIIR, GammaIIR] = self.neuralNetwork.getApproximation();
            
            order = length(Rho);
            
            RhoIIR = RhoIIR(1:order);
            GammaIIR = GammaIIR(1:order);
                
            fNormErrors(iter,:) = [norm(Gamma-GammaIIR), norm(Rho-RhoIIR)];
        end
        
        function plotting(self, ~)
            figure('Name','Identification process','NumberTitle','off','units','normalized',...
                'outerposition',[0 0 1 1]);
            
            tag = {'Pitch'; 'Yaw'};
            lbl = {'theta'; 'phi'};
            samples = self.trajectories.getSamples();
            desired = rad2deg(self.trajectories.getAllReferences());
            measurement = rad2deg(self.model.getPerformance());
            approximation = rad2deg(self.neuralNetwork.getBehaviorOutputs());
            trackingError = desired - measurement;
            identifError = measurement - approximation;
            rows = 2;
            cols = length(desired(1,:));
            
            for item = 1:cols
                subplot(rows, cols, item)
                yyaxis left
                hold on
                plot(desired(:,item),'k--','LineWidth',1)
                plot(measurement(:,item),'b:','LineWidth',1)
                ylabel(sprintf('%s (y_{r_\\%s}, y_\\%s)', string(tag(item)), string(lbl(item)), string(lbl(item))))
                yyaxis right
                plot(trackingError(:,item),'r-.','LineWidth',1)
                ylabel(sprintf('\\epsilon_\\%s', string(lbl(item))))
                lgd = legend(sprintf('Reference, y_{r_\\%s}', string(lbl(item))), ...
                    sprintf('Measurement, y_{\\%s}', string(lbl(item))), ...
                    sprintf('Tracking error, \\epsilon_{\\%s}', string(lbl(item))), ...
                    'Location','northoutside');
                lgd.NumColumns = 3;
                ylim([min(trackingError(:,item)) max(trackingError(:,item))])
                xlim([1 samples])
            end
            
            for item = 1:cols
                subplot(rows, cols, item + cols)
                yyaxis left
                hold on
                plot(measurement(:,item),'b:','LineWidth',1)
                plot(approximation(:,item),'k--','LineWidth',1)
                ylabel(sprintf('%s (y_{\\%s}, y_\\%s^\\Gamma)', string(tag(item)), string(lbl(item)), string(lbl(item))))
                yyaxis right
                plot(identifError(:,item),'r-.','LineWidth',1)
                ylabel(sprintf('e_\\%s', string(lbl(item))))
                lgd = legend(sprintf('Measurement, y_{\\%s}', string(lbl(item))), ...
                    sprintf('Approximation, y_{\\%s}^\\Gamma', string(lbl(item))), ...
                    sprintf('Identification error, e_{\\%s}', string(lbl(item))), ...
                    'Location','northoutside');
                lgd.NumColumns = 3;
                ylim([min(identifError(:,item)) max(identifError(:,item))])
                xlim([1 samples])
            end
        end
        
        function setMetrics(self)
            desired = rad2deg(self.trajectories.getAllReferences());
            measurement = rad2deg(self.model.getPerformance());
            approximation = rad2deg(self.neuralNetwork.getBehaviorOutputs());
            
            trackingError = desired - measurement;
            identifError = measurement - approximation;
            T = self.period;
            
            self.metrics = [self.ISE(identifError(:,1),T), self.ISE(trackingError(:,1),T), ...
                self.IAE(identifError(:,1),T), self.IAE(trackingError(:,1),T), ...
                self.IATE(identifError(:,1),T), self.IATE(trackingError(:,1),T)...
                self.ISE(identifError(:,2),T), self.ISE(trackingError(:,2),T), ...
                self.IAE(identifError(:,2),T), self.IAE(trackingError(:,2),T), ...
                self.IATE(identifError(:,2),T), self.IATE(trackingError(:,2),T)];
        end
        
        function rst = ISE(~, vector, period)
            rst = sum(period .* vector.^2);
        end
        
        function rst = IAE(~, vector, period)
            rst = sum(period .* abs(vector));
        end
        
        function rst = IATE(~, vector, period)            
            for i = 1:length(vector)
                k = i-1;
                vector(i) = period * k * abs(vector(i));
            end
            rst = sum(vector);
        end
    end
end