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
                
            fNormErrors(iter,:) = [norm(Gamma-GammaIIR), norm(Rho-RhoIIR)];
        end
        
        function plotting(self, fNormErrors)
            figure('Name','Identification process','NumberTitle','off','units','normalized',...
                'outerposition',[0 0 1 1]);
            
            tag = {'Pitch'; 'Yaw'};
            lbl = {'theta'; 'phi'};
            sub = {'Gamma', 'Phi'};
            samples = self.trajectories.getSamples();
            identification = self.neuralNetwork.getBehaviorOutputs();
            rows = 3;
            cols = 2;
            
            for item = 1:cols
                subplot(rows, cols, item)
                hold on
                plot(rad2deg(self.trajectories.getTrajectory(item)),'k--','LineWidth',1)
                plot(rad2deg(self.model.reads(item)),'r','LineWidth',1)
                legend('Reference','Measured')
                ylabel(sprintf('%s, \\%s', string(tag(item)), string(lbl(item))))
                xlim([1 samples])
            end
            
            for item = 1:cols
                subplot(rows, cols, item + cols)
                hold on
                plot(rad2deg(self.model.reads(item)),'k-.','LineWidth',1)
                plot(identification(:,item),'r','LineWidth',1)
                legend('Measured','Estimated')
                ylabel(sprintf('%s, \\%s', string(tag(item)), string(lbl(item))))
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