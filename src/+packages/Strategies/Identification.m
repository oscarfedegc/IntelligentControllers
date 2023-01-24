% This class that calls the other classes and generates the simulations
classdef Identification < Strategy
    properties (Access = private)
        tFinal, period {mustBeNumeric}
        plantType % {must be PlantList}
        references % {must be Structure}
        
        nnaType % {must be NetworkList}
        functionType % {must be FuntionList}
        functionSelected % {must be WaveletList, WindowList or []}
        amountFunctions, feedbacks, feedforwards, inputs, outputs {mustBeInteger}
        learningRates, persistentSignal, initialStates {mustBeNumeric}
        
        controlSignals {mustBeNumeric}
        fNormErrors {mustBeNumeric}
    end
    
    methods (Access = public)
        % Class constructor
        function self = Identification()
            return
        end
        
        % In this function, the user must give the simulations parameters
        function setup(self)
            % Time parameters
            self.tFinal = 10; % Simulation time [sec]
            
            % Plant parameters
            self.plantType = PlantList.helicopter2DOF;
            self.period = 0.005; % Plant sampling period [sec]
            self.initialStates = [-40 0 0 0];
            
            % Trajectory parameters (positions in degrees)
            self.references = struct('pitch', [0 0 10 10 10 0 0], ...
                                     'yaw', [0 0 -20 -20 0 0 20 10 10 0 0]);
            
            % Wavenet-IIR parameters
            self.functionType = FunctionList.wavelet;
            self.functionSelected = WaveletList.rasp2;
            self.amountFunctions = 9;
            
            self.feedbacks = 4;
            self.feedforwards = 6;
            self.persistentSignal = 5e-5;
            
            self.nnaType = NetworkList.Wavenet;
            self.inputs = 2;
            self.outputs = 2;
            
            self.learningRates = [7e-15 6e-15 6e-15 1e-12 3e-12];
        end
        
        % This funcion calls the class to generates the objects for the simulation.
        function builder(self)
            % Building the trajectories
            self.trajectories = ITrajectory(self.tFinal, self.period);
            self.trajectories.add(self.references.pitch)
            self.trajectories.add(self.references.yaw)
            
            % Bulding the plant
            samples = self.trajectories.getSamples();
            
            t = linspace(0,self.tFinal,samples);
            x = 20*sin(0.2*pi*t);
            y = -12*sin(0.1*pi*t);
            
            self.controlSignals = [x', y'];
            
            self.model = PlantFactory.create(self.plantType);
            self.model.setPeriod(self.period);
            self.model.setInitialStates(samples, deg2rad(self.initialStates))
            
            % Building the Wavenet-IIR
            self.neuralNetwork = NetworkFactory.create(self.nnaType);
            self.neuralNetwork.buildNeuronLayer(self.functionType, ...
                self.functionSelected, self.amountFunctions, self.inputs, self.outputs);
            self.neuralNetwork.buildFilterLayer(self.inputs, self.feedbacks, ...
                self.feedforwards, self.persistentSignal);
            self.neuralNetwork.setLearningRates(self.learningRates);
            self.neuralNetwork.initInternalMemory();
            self.neuralNetwork.initPerformance(samples);
            
            self.fNormErrors = zeros(samples,2);
        end
        
        % Executes the algorithm.
        function execute(self)            
            for iter = 1:self.trajectories.getSamples()
                kT = self.trajectories.getTime(iter);
                yRef = self.trajectories.getReferences(iter);
                
                up = self.controlSignals(iter,1);
                uy = self.controlSignals(iter,2);
                u = [up uy];
                
                self.neuralNetwork.evaluate(kT, u)
                
                yMes = self.model.measured(u, iter);
                yEst = self.neuralNetwork.getOutputs();
                
                eTracking = yRef - yMes;
                eIdentification = yMes - yEst;
                
                self.setNormError(iter)
                
                self.neuralNetwork.update(u, eIdentification)
                self.neuralNetwork.setPerformance(iter)
                
                self.log(kT, yRef, yMes, yEst, eTracking, eIdentification, u)
            end
        end
        
        function saveCSV(self)
        end
        
        function charts(self)
            self.neuralNetwork.charts()
            self.identification();
        end
    end
    
    methods (Access = protected)
        % This function 
        function setNormError(self, iter)
            [Rho, Gamma] = self.model.getApproximation();
            [RhoIIR, GammaIIR] = self.neuralNetwork.getApproximation();
                
            self.fNormErrors(iter,:) = [norm(Gamma-GammaIIR), norm(Rho-RhoIIR)];
        end
        
        % Display the algorithm behavior by means of the console messages.
        %
        %   @param {float} kT Instant of the time.
        %
        function log(~, kT, reference, measured, estimated, tracking, identification, control)
            clc
            fprintf(' :: PMR CONTROLLER ::\n TIME >> %6.3f seconds \n', kT);
            fprintf('PITCH >> yRef = %+6.4f   yMes = %+6.3f   yEst = %+6.4f   eTrackig = %+6.4f   eIdentification = %+6.4f   ctrlSignal = %+6.3f\n', ...
                reference(1), measured(1), estimated(1), tracking(1), identification(1), control(1))
            fprintf('  YAW >> yRef = %+6.4f   yMes = %+6.3f   yEst = %+6.4f   eTrackig = %+6.4f   eIdentification = %+6.4f   ctrlSignal = %+6.3f\n', ...
                reference(2), measured(2), estimated(2), tracking(2), identification(2), control(2))
        end
        
        function identification(self)
            figure('Name','Identification process','NumberTitle','off','units','normalized',...
                'outerposition',[0 0 1 1]);
            
            sub = {'Gamma', 'Phi'};
            tag = {'Pitch'; 'Yaw'};
            samples = self.trajectories.getSamples();
            rows = 3;
            cols = 2;
            
            perfOutputs = self.neuralNetwork.getBehaviorOutputs();
            
            for item = 1:cols
                subplot(rows, cols, item)
                hold on
                plot(self.model.reads(item),'r','LineWidth',1)
                plot(perfOutputs(:,item),'b','LineWidth',1)
                legend('Measured','Estimated')
                ylabel(sprintf('%s', string(tag(item))))
                xlim([1 samples])
            end
            
            for item = 1:cols
                subplot(rows, cols, item + cols)
                plot(self.fNormErrors(:,item),'r','LineWidth',1)
                ylabel(sprintf('||\\%s - \\%s_{est}||', string(sub(item)), string(sub(item))))
                xlim([1 samples])
            end
            
            for item = 1:cols
                subplot(rows, cols, item + 2*cols)
                plot(self.controlSignals(:,item),'r','LineWidth',1)
                
                ylabel(sprintf('Control signal of %s', string(tag(item))))
                xlim([1 samples])
            end
        end
    end
end