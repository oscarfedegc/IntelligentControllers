% This class that calls the other classes and generates the simulations
classdef IWIIRPMR < Strategy
    properties (Access = public)
        PREFIX = 'WaveNet-IIR PMR'; % It is use to create the folder and output files
    end
    
    methods (Access = public)
        % Class constructor
        function self = IWIIRPMR()
            return
        end
        
        % In this function, the user must give the simulations parameters
        function setup(self)
            % Time parameters
            self.tFinal = 15; % Simulation time [sec]
            
            % Plant parameters
            self.plantType = PlantList.helicopter2DOF;
            self.period = 0.005; % Plant sampling period [sec]
            self.initialStates = [0 0 0 0];

            % Trajectory parameters (positions in degrees)
            test = 1;
            switch test
                case 1
                    self.references = struct('pitch', [-40 20 20 20 20 0], ...
                                             'yaw', [0 30 30 0 -30 -30 0]);
                case 2
                    self.references = struct('pitch', [-30 -20 20 -20 20 -20 20 -20 -30], ...
                                             'yaw', [0 30 -30 30 -30 30 -30 0]);
                case 3
                    self.references = struct('pitch', [-30 30], ...
                                             'yaw', [0 30]);
                otherwise
                    self.references = struct('pitch', [-40 -40 -20 -20 0 0 0 0], ...
                                             'yaw', [0 30 -30 -30 0 0]);
            end
            
            % Controller parameters
            self.controllerType = ControllerTypes.WavenetPMR;
            self.controllerGains = struct('pitch', [100 100 75 0 0 0], ...
                                            'yaw', [300 100 75 0 0 0]);
            self.controllerRates = struct('pitch', 1e-5.*ones(1,6),...
                                            'yaw', 1e-5.*ones(1,6));
            self.pitchCtrlOffset = 12.5;
            self.yawCtrlOffset = -4.0;
            
            % Wavenet-IIR parameters
            self.nnaType = NetworkList.WavenetIIR;
            self.functionType = FunctionList.wavelet;
            self.functionSelected = WaveletList.morlet;
            
            self.inputs = 2;
            self.outputs = 2;
            self.amountFunctions = 4;
            self.feedbacks = 4;
            self.feedforwards = 4;
            self.persistentSignal = 1;
            
            self.learningRates = [1e-4 1e-4 1e-6 1e-4 1e-4];
            self.rangeSynapticWeights = 0.005;
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
            pitchController.setLevelDescomposition()
            pitchController.setUpdateRates(self.controllerRates.pitch)
            pitchController.initPerformance(samples)
            
            % Buildin the yaw controller
            yawController = ControllerFactory.create(self.controllerType);
            yawController.setGains(self.controllerGains.yaw)
            yawController.setLevelDescomposition()
            yawController.setUpdateRates(self.controllerRates.yaw);
            yawController.initPerformance(samples);
            
            self.controllers = [pitchController, yawController];
            
            % Building the Wavenet-IIR
            self.neuralNetwork = NetworkFactory.create(self.nnaType);
            self.neuralNetwork.setSynapticRange(self.rangeSynapticWeights)
            self.neuralNetwork.buildNeuronLayer(self.functionType, ...
                self.functionSelected, self.amountFunctions, self.inputs, self.outputs)
            self.neuralNetwork.buildFilterLayer(self.inputs, self.feedbacks, ...
                self.feedforwards, self.persistentSignal)
            self.neuralNetwork.setLearningRates(self.learningRates)
            self.neuralNetwork.bootInternalMemory()
            self.neuralNetwork.bootPerformance(samples)
            
            % Buildind the repository
            self.repository = IRepositoryWNETIIRPMR(self.PREFIX);
            
            self.repository.setModel(self.model)
            self.repository.setControllers(self.controllers)
            self.repository.setNeuralNetwork(self.neuralNetwork)
            self.repository.setTrajectories(self.trajectories)
            self.repository.setFolderPath()

            % Sampling amount for output files
            self.indexes = ISamplePopulation.getIndexes(samples);
        end
        
        % Executes the algorithm.
        function execute(self)
            self.repository.writeConfiguration()

            for iter = 1:self.trajectories.getSamples()
                kT = self.trajectories.getTime(iter);
                yRef = self.trajectories.getReferences(iter);
                
                up = self.controllers(1).getSignal() + self.pitchCtrlOffset;
                uy = self.controllers(2).getSignal() + self.yawCtrlOffset;
                u = [up uy];
                
                self.neuralNetwork.evaluate(kT, u)
                
                yMes = self.model.measured(u, iter);
                yEst = self.neuralNetwork.getOutputs();
                Gamma = self.neuralNetwork.filterLayer.getGamma();

                eTracking = yRef - yMes;
                eIdentification = yMes - yEst;
                
                if isnan(eTracking(1)) || isnan(eTracking(2)) || ...
                        isnan(eIdentification(1)) || isnan(eIdentification(2))
                    self.isSuccessfully = false;
                    break
                end
                
                self.neuralNetwork.update(u, eIdentification)
                
                self.controllers(1).autotune(eTracking(1), eIdentification(1), Gamma(1))
                self.controllers(2).autotune(eTracking(2), eIdentification(2), Gamma(2))
                self.controllers(1).evaluate()
                self.controllers(2).evaluate()
                
                self.neuralNetwork.setPerformance(iter)
                self.controllers(1).setPerformance(iter)
                self.controllers(2).setPerformance(iter)
                
                self.log(kT, yRef, yMes, yEst, eTracking, eIdentification, u, Gamma)
            end
            self.setMetrics()
        end
        
        function saveCSV(self)
            self.repository.write(self.indexes, self.metrics)
        end
        
        function showCharts(self)
            self.neuralNetwork.charts('noncompact')
            self.controllers(1).charts('Pitch controller', self.pitchCtrlOffset)
            self.controllers(2).charts('Yaw controller', self.yawCtrlOffset)
            self.plotting()
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