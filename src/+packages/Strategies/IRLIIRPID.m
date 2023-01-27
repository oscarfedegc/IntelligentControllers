% This class that calls the other classes and generates the simulations
classdef IRLIIRPID < Strategy
    properties (Access = protected)
        PREFIX = 'RL-IIR PID';
    end
    
    properties (Access = private)
        tFinal, period {mustBeNumeric}
        plantType % {must be PlantList}
        controllerType % {must be ControllerTypes}
        references, controllerGains, controllerRates % {must be Structure}
        
        nnaType % {must be NetworkList}
        functionType % {must be FuntionList}
        functionSelected % {must be WaveletList, WindowList or []}
        amountFunctions, feedbacks, feedforwards, inputs, outputs {mustBeInteger}
        learningRates, persistentSignal, initialStates {mustBeNumeric}
        
        fNormApprox, fNormErrors {mustBeNumeric}
    end
    
    methods (Access = public)
        % Class constructor
        function self = IRLIIRPID()
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
            self.references = struct('pitch', [-40 -40 -20 -20 0 0 0 0], ...
                                     'yaw', [0 30 -30 -30 0 0]);
            
            % Controller parameters
            self.controllerType = ControllerTypes.WavenetPMR;
            self.controllerGains = struct('pitch', [1 1 1], ...
                                            'yaw', [1 1 1]);
            self.controllerRates = struct('pitch', [1e-1 1e-1 1e-1],...
                                            'yaw', [1e-1 1e-1 1e-1]);
            
            % Wavenet-IIR parameters
            self.functionType = FunctionList.wavelet;
            self.functionSelected = WaveletList.rasp1;
            self.amountFunctions = 3;
            
            self.feedbacks = 5;
            self.feedforwards = 4;
            self.persistentSignal = 3.36e-2;
            
            self.nnaType = NetworkList.ActorCritic;
            self.inputs = 3;
            self.outputs = 3;
            
            self.learningRates = [3e-8 3e-8 3e-8 5e-8 5e-5];
        end
        
        % This funcion calls the class to generates the objects for the simulation.
        function builder(self)
            % Building the trajectories
            self.trajectories = ITrajectory(self.tFinal, self.period);
            self.trajectories.add(self.references.pitch)
            self.trajectories.add(self.references.yaw)
            
            % Bulding the plant
            samples = self.trajectories.getSamples();
            
            self.fNormApprox = zeros(samples, 2);
            self.fNormErrors = zeros(samples, 2);
            
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
                
%                 yMes = self.model.measured(u, iter);
%                 
%                 netOutputs = self.neuralNetwork.getOutputs();
%                 yEst = netOutputs(1:self.outputs-1);
%                 criticOutput = netOutputs(self.outputs-1);
%                 Gamma = self.neuralNetwork.filterLayer.getGamma();
%                 Gamma = Gamma(1:self.outputs-1);
%                 
%                 eTracking = yRef - yMes;
%                 eIdentification = yMes - yEst;
%                 
%                 self.fNormApprox = self.setNormError(self.fNormApprox, iter);
%                 
% %                 self.neuralNetwork.update(u, eIdentification)
%                 
%                 self.controllers(1).autotune(eTracking(1), eIdentification(1), Gamma(1))
%                 self.controllers(2).autotune(eTracking(2), eIdentification(2), Gamma(2))
%                 self.controllers(1).evaluate()
%                 self.controllers(2).evaluate()
%                 
%                 self.neuralNetwork.setPerformance(iter)
%                 self.controllers(1).setPerformance(iter)
%                 self.controllers(2).setPerformance(iter)
%                 
%                 self.log(kT, yRef, yMes, yEst, eTracking, eIdentification, u, Gamma)
            end
        end
        
        function saveCSV(~)
        end
        
        function charts(self)
%             self.neuralNetwork.charts()
%             self.controllers(1).charts('Pitch controller')
%             self.controllers(2).charts('Yaw controller')
            self.plotting(self.fNormApprox);
        end
    end
    
    methods (Access = protected)
        % Display the algorithm behavior by means of the console messages.
        %
        %   @param {float} kT Instant of the time.
        %
        function log(self, kT, reference, measured, estimated, tracking, identification, control, gamma)
            clc            
            reference = rad2deg(reference);
            measured = rad2deg(measured);
            estimated = rad2deg(estimated);
            tracking = rad2deg(tracking);
            identification = rad2deg(identification);
            
            fprintf(' :: %s CONTROLLER ::\n TIME >> %6.3f seconds \n', self.PREFIX, kT);
            fprintf('PITCH >> yRef = %+6.3f   yMes = %+6.3f   yEst = %+6.3f   eTck = %+6.3f   eIdf = %+6.3f   signal = %+6.3f   gamma = %+6.3f\n', ...
                reference(1), measured(1), estimated(1), tracking(1), identification(1), control(1), gamma(1))
            fprintf('  YAW >> yRef = %+6.3f   yMes = %+6.3f   yEst = %+6.3f   eTck = %+6.3f   eIdf = %+6.3f   signal = %+6.3f   gamma = %+6.3f\n', ...
                reference(2), measured(2), estimated(2), tracking(2), identification(2), control(2), gamma(2))
        end
    end
end