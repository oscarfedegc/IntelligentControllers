% This class that calls the other classes and generates the simulations
classdef IWIIRPID < Strategy
    properties (Access = private)
%         plantType % {must be PlantList}
%         controllerType % {must be ControllerTypes}
%         references, controllerGains, controllerRates % {must be Structure}
%         
%         nnaType % {must be NetworkList}
%         functionType % {must be FuntionList}
%         functionSelected % {must be WaveletList, WindowList or []}
%         amountFunctions, feedbacks, feedforwards, inputs, outputs {mustBeInteger}
%         learningRates, persistentSignal, initialStates {mustBeNumeric}
    end
    
    methods (Access = public)
        % Class constructor
        function self = IWIIRPID()
            return
        end
        
        % In this function, the user must give the simulations parameters
        function setup(self)
            % Time parameters
            self.tFinal = 10;        % Simulation time [sec]
            
            % Plant parameters
            self.plantType = PlantList.helicopter2DOF;
            self.period = 0.005;     % Plant sampling period [sec]
            self.initialStates = [-40 0 0 0];
            
            % Trajectory parameters (positions in degrees)
            self.references = struct('pitch', [0 0 10 10 10 0 0], ...
                                     'yaw', [0 0 -20 -20 0 0 20 10 10 0 0]);
            
            % Controller parameters
            self.controllerType = ControllerTypes.PID;
            self.controllerGains = struct('pitch', [10 .1 10], 'yaw', [.1 0 .1]);
            self.controllerRates = struct('pitch', [0 0 0], 'yaw', [0 0 0]);
            
            % Wavenet-IIR parameters
            self.functionType = FunctionList.wavelet;
            self.functionSelected = WaveletList.rasp2;
            self.amountFunctions = 3;
            
            self.feedbacks = 4;
            self.feedforwards = 5;
            self.persistentSignal = 1e-3;
            
            self.nnaType = NetworkList.WavenetIIR;
            self.inputs = 2;
            self.outputs = 2;
            
            self.learningRates = [1e-10, 1e-10, 1e-10, 1e-10, 1e-10];
        end
        
        % This funcion calls the class to generates the objects for the simulation.
        function builder(self)
            % Building the trajectories
            self.trajectories = ITrajectory(self.tFinal, self.period);
            self.trajectories.add(self.references.pitch)
            self.trajectories.add(self.references.yaw)
            
            % Bulding the plant
            samples = self.trajectories.getSamples();
            
            self.model = PlantFactory.create(self.plantType);
            self.model.setPeriod(self.period);
            self.model.setInitialStates(samples, deg2rad(self.initialStates))
            
            % Building the pitch controller            
            pitchController = ControllerFactory.create(self.controllerType);
            pitchController.setGains(self.controllerGains.pitch)
            pitchController.setUpdateRates(self.controllerRates.pitch);
            pitchController.initPerformance(samples);
            
            % Buildin the yaw controller
            yawController = ControllerFactory.create(self.controllerType);
            yawController.setGains(self.controllerGains.yaw)
            yawController.setUpdateRates(self.controllerRates.yaw);
            yawController.initPerformance(samples);
            
            self.controllers = [pitchController, yawController];
            
            % Building the Wavenet-IIR
            self.neuralNetwork = NetworkFactory.create(self.nnaType);
            self.neuralNetwork.buildNeuronLayer(self.functionType, ...
                self.functionSelected, self.amountFunctions, self.inputs, self.outputs);
            self.neuralNetwork.buildFilterLayer(self.inputs, self.feedbacks, ...
                self.feedforwards, self.persistentSignal);
            self.neuralNetwork.setLearningRates(self.learningRates);
            self.neuralNetwork.initInternalMemory();
            self.neuralNetwork.initPerformance(samples);
        end
        
        % Executes the algorithm.
        function execute(self)
            for iter = 1:self.trajectories.getSamples()
                kT = self.trajectories.getTime(iter);
                yRef = self.trajectories.getReferences(iter);
                
                up = self.controllers(1).getSignal();
                uy = self.controllers(2).getSignal();
                u = [up uy];
                
                self.neuralNetwork.evaluate(kT, u)
                
                yMes = self.model.measured(u, iter);
                yEst = self.neuralNetwork.getOutputs();
                Gamma = self.neuralNetwork.filterLayer.getGamma();
                
                eTracking = yRef - yMes;
                eIdentification = yMes - yEst;
                
                self.neuralNetwork.update(u, eIdentification)
                
                self.controllers(1).autotune(eTracking(1), eIdentification(1), Gamma(1))
                self.controllers(2).autotune(eTracking(2), eIdentification(2), Gamma(2))
                self.controllers(1).evaluate()
                self.controllers(2).evaluate()

                self.neuralNetwork.setPerformance(iter)
                self.controllers(1).setPerformance(iter)
                self.controllers(2).setPerformance(iter)
                
                self.log(kT, yRef, yMes, yEst, eTracking, eIdentification, u)
            end
        end
        
        function saveCSV(self)
        end
        
        function charts(self)
            self.neuralNetwork.charts()
            self.controllers(1).charts('Pitch controller')
            self.controllers(2).charts('Yaw controller')
            self.plotting(self.fNormApprox);
        end
    end
    
    methods (Access = protected)
        % Display the algorithm behavior by means of the console messages.
        %
        %   @param {float} kT Instant of the time.
        %
        function log(~, kT, reference, measured, estimated, tracking, identification, control)
            clc
            fprintf(' :: PID CONTROLLER ::\n TIME >> %6.3f seconds \n', kT);
            fprintf('PITCH >> yr = %+6.4f   ym = %+6.3f   ye = %+6.4f   et = %+6.4f   ei = %+6.4f   u = %+6.3f\n', ...
                reference(1), measured(1), estimated(1), tracking(1), identification(1), control(1))
            fprintf('  YAW >> yr = %+6.4f   ym = %+6.3f   ye = %+6.4f   et = %+6.4f   ei = %+6.4f   u = %+6.3f\n', ...
                reference(2), measured(2), estimated(2), tracking(2), identification(2), control(2))
        end
    end
end