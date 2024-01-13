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
        isSuccessfully % {must be Bolean}
        isTraining % {must be Boolean}
    end
    
    properties (Access = protected)
        tFinal, period {mustBeNumeric}
        plantType % {must be PlantList}
        controllerType % {must be ControllerTypes}
        references, controllerGains, controllerRates % {must be Structure}
        typeReference % {mustBeString}
        
        nnaType % {must be NetworkList}
        functionType % {must be FuntionList}
        functionSelected % {must be WaveletList, WindowList or []}
        amountFunctions, feedbacks, feedforwards, inputs, outputs {mustBeInteger}
        learningRates, learningBetas, persistentSignal, initialStates {mustBeNumeric}
        offsets {mustBeNumeric}
        
        fNormApprox, fNormErrors {mustBeNumeric}
        
        directory, filename % {must be String or path}
        metrics, rangeSynapticWeights, idxStates {mustBeNumeric}
    end
    
    % Theses functions must be implemented in all inherited classes, and have
    % to be called in the following order.
    methods (Abstract = true)
        setup();
        builder();
        execute();
        saveCSV();
        showCharts();
    end
    
    methods (Access = public)
        % This function calls a method to save the simulation results into a
        % csv file
        function writeCSV(self)
            if ~self.isSuccessfully
                return
            end
            self.saveCSV();
            
            try
                population = self.trajectories.getSamples();
                index = ISamplePopulation.getIndexes(population);
                fprintf('Sample = %06d, indexes = %02d therefore sample size = %06d\n', ...
                    population, index, round(population/index))
            catch
            end
        end
        
        % This function calls a custom method to plot the behavior of the
        % controller parameters and Wavenet during simulation
        function charts(self)
            if ~self.isSuccessfully
            end
            self.showCharts();
        end
    end
    
    methods (Access = protected)
        % This function calculates and stores the approximation error norm
        % of the nonlinear model
        function fNormErrors = setNormError(self, fNormErrors, iter)
            [Rho, Gamma] = self.model.getApproximation();
            [RhoIIR, GammaIIR] = self.neuralNetwork.getApproximation();
            
            order = length(Rho);
            
            RhoIIR = RhoIIR(1:order);
            GammaIIR = GammaIIR(1:order);
                
            fNormErrors(iter,:) = [norm(Gamma-GammaIIR), norm(Rho-RhoIIR)];
        end
        
        % This function plots the simualtions results for the tracking
        % performance and identification performance
        function plottingV2(self)
            if ~self.isSuccessfully
                return
            end
            
            figure('Name','Identification process','NumberTitle','off','units','normalized',...
                'outerposition',[0 0 1 1]);
            
            tag = {'Pitch'; 'Yaw'};
            lbl = {'theta'; 'phi'};
            samples = self.trajectories.getSamples();
            desired = self.trajectories.getAllReferences();
            measurement = self.model.getPerformance();
            approximation = self.neuralNetwork.getBehaviorApproximation();
            trackingError = desired - measurement;
            identifError = measurement - approximation;
            time = 0:self.period:self.tFinal;
            time = time(1:samples);
            rows = 2;
            cols = length(desired(1,:)) * 2;
            
            % Tracking charts
            for item = 1:cols/2
                subplot(rows, cols, item)
                hold on
                plot(time, desired(:,item),'k--','LineWidth',1)
                plot(time, measurement(:,item),'b:','LineWidth',1.5)
                xlabel(sprintf('Time, t [sec]'))
                ylabel(sprintf('%s (y_{r_\\%s}, y_\\%s)', string(tag(item)), string(lbl(item)), string(lbl(item))))
                lgd = legend(sprintf('y_{r_\\%s}', string(lbl(item))), ...
                    sprintf('y_{\\%s}', string(lbl(item))), 'Location','northoutside');
                lgd.NumColumns = 2;
                xlim([1 self.tFinal])
            end
            
            % Identification charts
            for item = 1:cols/2
                subplot(rows, cols, item + cols/2)
                hold on
                plot(time, measurement(:,item),'b:','LineWidth',1.5)
                plot(time, approximation(:,item),'k-.','LineWidth',1)
                xlabel(sprintf('Time, t [sec]'))
                ylabel(sprintf('%s (y_{r_\\%s}, y_\\%s)', string(tag(item)), string(lbl(item)), string(lbl(item))))
                lgd = legend(sprintf('y_{\\%s}', string(lbl(item))), ...
                    sprintf('y_{\\%s}^\\Gamma', string(lbl(item))), 'Location','northoutside');
                lgd.NumColumns = 2;
                xlim([1 self.tFinal])
            end
            
            % Tracking errors chart
            for item = 1:cols/2
                subplot(rows, cols, item + cols)
                hold on
                plot(time, trackingError(:,item),'r-.','LineWidth',1)
                xlabel(sprintf('Time, t [sec]'))
                legend(sprintf('\\epsilon_{\\%s}', string(lbl(item))),'Location','northoutside');
                xlim([1 self.tFinal])
            end
            
            % Identification errors chart
            for item = 1:cols/2
                subplot(rows, cols, item + 3*cols/2)
                hold on
                plot(time, identifError(:,item),'r-.','LineWidth',1)
                xlabel(sprintf('Time, t [sec]'))
                ylabel(sprintf('e_\\%s', string(lbl(item))))
                legend(sprintf('e_{\\%s}', string(lbl(item))),'Location','northoutside');
                xlim([1 self.tFinal])
            end
        end
        
        % This function plots the simualtions results for the tracking
        % performance and identification performance. The graphs using
        % doubles scales.
        function plotting(self)
            if ~self.isSuccessfully
                return
            end
            
            figure('Name','Identification process','NumberTitle','off','units','normalized',...
                'outerposition',[0 0 1 1]);
            
            tag = {'Pitch'; 'Yaw'};
            lbl = {'theta'; 'phi'};
            
            instants = self.trajectories.getInstants();
            desired = self.trajectories.getAllReferences();
            measurement = self.model.getPerformance(self.idxStates);
            approximation = self.neuralNetwork.getBehaviorApproximation();
            
            rows = 2;
            cols = length(desired(1,:));
            
            trackingError = desired - measurement;
            identifError = measurement - approximation;
            
            % Tracking and tracking errors
            for item = 1:cols
                subplot(rows, cols, item)
                yyaxis left
                hold on
                plot(instants,desired(:,item),'k','LineWidth',1)
                plot(instants,measurement(:,item),'LineWidth',1.5)
                ylabel(sprintf('%s (y_{r_\\%s}, y_\\%s)', string(tag(item)), string(lbl(item)), string(lbl(item))))
                yyaxis right
                plot(instants,trackingError(:,item),'LineWidth',1)
                ylabel(sprintf('\\epsilon_\\%s', string(lbl(item))))
                lgd = legend(...
                    sprintf('Reference, y_{r_\\%s}', string(lbl(item))), ...
                    sprintf('Measurement, y_{\\%s}', string(lbl(item))), ...
                    sprintf('Tracking error, \\epsilon_{\\%s}', string(lbl(item))), ...
                    'Location','northoutside');
                lgd.NumColumns = 3;
                xlabel('Time, kT [sec]')
            end
            
            % Identification and identification errors
            for item = 1:cols
                subplot(rows, cols, item + cols)
                yyaxis left
                hold on
                plot(instants,measurement(:,item),'k','LineWidth',1)
                plot(instants,approximation(:,item),'LineWidth',1)
                ylabel(sprintf('%s (y_{\\%s}, y_\\%s^\\Gamma)', string(tag(item)), string(lbl(item)), string(lbl(item))))
                yyaxis right
                plot(instants,identifError(:,item),'LineWidth',1)
                ylabel(sprintf('e_\\%s', string(lbl(item))))
                lgd = legend(...
                    sprintf('Measurement, y_{\\%s}', string(lbl(item))), ...
                    sprintf('Approximation, y_{\\%s}^\\Gamma', string(lbl(item))), ...
                    sprintf('Identification error, e_{\\%s}', string(lbl(item))), ...
                    'Location','northoutside');
                lgd.NumColumns = 3;
                xlabel('Time, kT [sec]')
            end
        end
        
        % This functions calls a class to calculate different metrics for
        % the tracking and identification process
        function setMetrics(self, states)
            if ~self.isSuccessfully
                return
            end
            
            desired = self.trajectories.getAllReferences();
            measurement = self.model.getPerformance(states);
            approximation = self.neuralNetwork.getBehaviorApproximation();
            
            initial = 500;
            samples = length(desired(:,1));
            desired = rad2deg(desired(initial:samples,:));
            measurement = rad2deg(measurement(initial:samples,:));
            approximation = rad2deg(approximation(initial:samples,:));

            self.metrics = [];

            for i = 1:2
                temp = [IMetrics.R2(desired(:,i), measurement(:,i)), ...
                        IMetrics.R2(measurement(:,i), approximation(:,i)); ...
                        IMetrics.RMSE(desired(:,i), measurement(:,i)), ...
                        IMetrics.RMSE(measurement(:,i), approximation(:,i))];
                    
                self.metrics = [self.metrics temp];
            end
        end
    end
end