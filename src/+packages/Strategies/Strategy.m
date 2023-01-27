% This abstract class represents the control strategies and their
% components: the plant (or model to be controled) and its desired
% trajectories, the neural network topology, and the control schemes.
classdef Strategy < handle
    properties (Access = protected)
        model % {must be Plant}
        controllers % {must be Controller}
        neuralNetwork % {must be NetworkScheme}
        trajectories % {must be ITrajectories}
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
        
        function plotting(self, fNormErrors)
            figure('Name','Identification process','NumberTitle','off','units','normalized',...
                'outerposition',[0 0 1 1]);
            
            tag = {'Pitch'; 'Yaw'};
            lbl = {'theta'; 'phi'};
            sub = {'Gamma', 'Phi'};
            samples = self.trajectories.getSamples();
            references = rad2deg(self.trajectories.getAllReferences());
            measurement = rad2deg(self.model.getPerformance());
            approximation = rad2deg(self.neuralNetwork.getBehaviorOutputs());
            trackingError = references - measurement;
            identifError = measurement - approximation;
            rows = 3;
            cols = length(references(1,:));
            
            for item = 1:cols
                subplot(rows, cols, item)
                yyaxis left
                hold on
                plot(references(:,item),'k--','LineWidth',1)
                plot(measurement(:,item),'b:','LineWidth',1)
                ylabel(sprintf('%s (y_{r_\\%s}, y_\\%s)', string(tag(item)), string(lbl(item)), string(lbl(item))))
                yyaxis right
                plot(trackingError(:,item),'r-.','LineWidth',1)
                ylabel(sprintf('\\epsilon_\\%s', string(lbl(item))))
                legend(sprintf('Reference, y_{r_\\%s}', string(lbl(item))), ...
                    sprintf('Measurement, y_{\\%s}', string(lbl(item))), ...
                    sprintf('Tracking error, \\epsilon_{\\%s}', string(lbl(item))))
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
                legend(sprintf('Measurement, y_{\\%s}', string(lbl(item))), ...
                    sprintf('Approximation, y_{\\%s}^\\Gamma', string(lbl(item))), ...
                    sprintf('Identification error, e_{\\%s}', string(lbl(item))))
                xlim([1 samples])
            end
            
            for item = 1:cols
                subplot(rows, cols, item + 2*cols)
                plot(fNormErrors(:,item),'r','LineWidth',1)
                ylabel(sprintf('||\\%s - \\%s_{est}||', string(sub(item)), string(sub(item))))
                xlim([1 samples])
            end
        end
    end
end