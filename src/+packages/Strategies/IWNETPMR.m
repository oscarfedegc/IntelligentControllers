% This class that calls the other classes and generates the simulations
classdef IWNETPMR < Strategy
    properties (Access = public)
        PREFIX = 'WaveNet PMR';
    end
    
    methods (Access = public)
        % Class constructor
        function self = IWNETPMR()
            return
        end
        
        % In this function, the user must give the simulations parameters
        function setup(self)
            % Time parameters
            self.tFinal = 30; % Simulation time [sec]
            
            % Plant parameters
            self.plantType = PlantList.helicopter2DOF;
            self.period = 0.005; % Plant sampling period [sec]
            self.initialStates = [0 0 0 0];
            
            self.indexes = 20;
            
            % Trajectory parameters (positions in degrees)
            test = 4;
            switch test
                case 1
                    self.references = struct('pitch', [-40 10 10 10 10 10 10 10 10 10 10 0], ...
                                             'yaw', [0 30 30 30 30 30 30 30 30 0]);
                case 2
                    self.references = struct('pitch', [-40 -30 30 -30 30 -30 30 -30 -40], ...
                                             'yaw', [0 30 -30 30 -30 30 -30 0]);
                case 3
                    self.references = struct('pitch', [0 -3 3 -3 3 -3 3 -3 0], ...
                                             'yaw', [0 3 -3 3 -3 3 -3 0]);
                otherwise
                    self.references = struct('pitch', [-40 -40 -20 -20 0 0 0 0], ...
                                             'yaw', [0 30 -30 -30 0 0]);
            end
            
            % Controller parameters
            self.controllerType = ControllerTypes.WavenetPMR;
            self.controllerGains = struct('pitch', [25 1 5], ...
                                            'yaw', [22 4 5]);
            self.controllerRates = struct('pitch', [1 1 1],...
                                            'yaw', [1 1 1]);
            
            % Wavenet-IIR parameters
            self.nnaType = NetworkList.Wavenet;
            self.functionType = FunctionList.wavelet;
            self.functionSelected = WaveletList.morlet;
            
            self.inputs = 2;
            self.outputs = 2;
            self.amountFunctions = 3;
            
            self.learningRates = 1e-4 .* ones(1,3);
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
            self.neuralNetwork.setLearningRates(self.learningRates);
            self.neuralNetwork.bootPerformance(samples);
            
            % Buildind the repository
            self.repository = IRepositoryWNETPMR();
            
            self.repository.setModel(self.model)
            self.repository.setControllers(self.controllers)
            self.repository.setNeuralNetwork(self.neuralNetwork)
            self.repository.setTrajectories(self.trajectories)
            self.repository.setFolderPath()
            
            self.repository.writeConfiguration()
        end
        
        % Executes the algorithm.
        function execute(self)
            Gamma = ones(1,2);
            self.isSuccessfully = true;
            
            for iter = 1:self.trajectories.getSamples()
                kT = self.trajectories.getTime(iter);
                yRef = self.trajectories.getReferences(iter);
                
                up = self.controllers(1).getSignal();
                uy = self.controllers(2).getSignal();
                u = [up uy];
                
                self.neuralNetwork.evaluate(kT, u)
                
                yMes = self.model.measured(u, iter);
                yEst = self.neuralNetwork.getOutputs();
                
                eTracking = yRef - yMes;
                eIdentification = yMes - yEst;
                
                self.neuralNetwork.update(u, eIdentification)
                
                try
                    self.controllers(1).autotune(eTracking(1), eIdentification(1), Gamma(1))
                    self.controllers(2).autotune(eTracking(2), eIdentification(2), Gamma(2))
                    self.controllers(1).evaluate()
                    self.controllers(2).evaluate()
                catch
                    disp('AUTOTUNE FAILED!')
                    self.isSuccessfully = false;
                    break
                end
                
                self.neuralNetwork.setPerformance(iter)
                self.controllers(1).setPerformance(iter)
                self.controllers(2).setPerformance(iter)
                
                self.log(kT, yRef, yMes, yEst, eTracking, eIdentification, u, Gamma)
            end
            self.setMetrics()
        end
        
        function saveCSV(self)
            if ~self.isSuccessfully
                return
            end
            
            self.repository.write(self.indexes, self.metrics)
        end
        
        function charts(self)
            if ~self.isSuccessfully
                return
            end
            
            self.neuralNetwork.charts('compact')
            self.controllers(1).charts('Pitch controller')
            self.controllers(2).charts('Yaw controller')
            self.plottingV2();
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
            
            fprintf(' :: %s CONTROLLER ::\n TIME >> %10.3f seconds \n', self.PREFIX, kT);
            fprintf('PITCH >> yRef = %+010.4f   yMes = %+010.4f   yEst = %+010.4f   eTck = %+010.4f   eIdf = %+010.4f   signal = %+010.4f   gamma = %+010.4f\n', ...
                reference(1), measured(1), estimated(1), tracking(1), identification(1), control(1), gamma(1))
            fprintf('  YAW >> yRef = %+010.4f   yMes = %+010.4f   yEst = %+010.4f   eTck = %+010.4f   eIdf = %+010.4f   signal = %+010.4f   gamma = %+010.4f\n', ...
                reference(2), measured(2), estimated(2), tracking(2), identification(2), control(2), gamma(2))
        end
    end
end