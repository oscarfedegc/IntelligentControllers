% This class that calls the other classes and generates the simulations
classdef IWIIRPID < Strategy
    properties (Access = public)
        PREFIX = 'WaveNet-IIR PID'; % It is use to create the folder and output files
    end
    
    methods (Access = public)
        % Class constructor
        function self = IWIIRPID()
            return
        end
        
        % In this function, the user must give the simulations parameters
        function setup(self)
            % Time parameters
            self.tFinal = 60; % Simulation time [sec]
            
            % Plant parameters
            self.plantType = PlantList.helicopter2DOF;
            self.period = 0.005; % Plant sampling period [sec]
            self.initialStates = [-40 0 0 0];

            % Controller parameters
            self.controllerType = ControllerTypes.WavenetPID;
            self.controllerGains = struct('pitch', [0.1 0 0], ...
                                            'yaw', [0.1 0 0]);
            self.controllerRates = struct('pitch', 1e-2.*zeros(1,3),...
                                            'yaw', 1e-2.*zeros(1,3));
            self.offsets = [12.5 -4.0];
            
            % Wavenet-IIR parameters
            self.nnaType = NetworkList.WavenetIIR;
            self.functionType = FunctionList.window;
            self.functionSelected = WindowList.flattop2;
            
            self.inputs = 2;
            self.outputs = 2;
            self.amountFunctions = 3;
            self.feedbacks = 5;
            self.feedforwards = 4;
            self.persistentSignal = 3.35e-10;
            
            self.learningRates = 0*[10e-5 10e-10 10e-7 10e-5 10e-5];
            self.rangeSynapticWeights = 0.001;
            
            self.idxStates = [1 3];
            
            self.idxStates = [1 3];
            
            % Training status and type reference signals
            self.isTraining = true;
            self.typeReference = 'S01';
            
            % Trajectory parameters (positions in degrees)
            switch self.typeReference
                case 'P01'
                    self.references = struct('pitch',  [-40 40 40 10 10 -20 -20 -40], ...
                                             'yaw',    [0 -40 -40 0 0 40 40 0]);
                                         
                case 'P02'                                         
                    self.references = struct('pitch',  [-20 -20 0 0 20 20], ...
                                             'yaw',    [0 -10 -10 0 0 10 10]);
                case 'S01'
                    self.references = struct('pitch',  [5 0 0 -5 -10 -10 -10 -10 -5 0 -5 0], ...
                                             'yaw',    [0 0 5 5 5 0 -5 -10 -5 0 5 0], ...
                                             'tpitch', 5:5:self.tFinal,...
                                             'tyaw',   5:5:self.tFinal);
            end
        end
        
        % This funcion calls the class to generates the objects for the simulation.
        function builder(self)
            % Building the trajectories
            self.trajectories = ITrajectory(self.tFinal, self.period, 'rads');
            
            if ~strcmp(self.isTraining,'S01')
                self.trajectories.add(self.references.pitch)
                self.trajectories.add(self.references.yaw)
            else
                self.trajectories.addPositions(self.references.pitch, self.references.tpitch)
                self.trajectories.addPositions(self.references.yaw, self.references.tyaw)
            end
            
            % Bulding the plant
            samples = self.trajectories.getSamples();
            
            self.fNormApprox = zeros(samples, 2);
            self.fNormErrors = zeros(samples, 2);
            
            self.model = PlantFactory.create(self.plantType);
            self.model.setPeriod(self.period);
            self.model.setInitialStates(samples + 1, deg2rad(self.initialStates))
            
            % Building the pitch controller            
            pitchController = ControllerFactory.create(self.controllerType);
            pitchController.setGains(self.controllerGains.pitch)
            pitchController.setUpdateRates(self.controllerRates.pitch)
            pitchController.initPerformance(samples)
            
            % Buildin the yaw controller
            yawController = ControllerFactory.create(self.controllerType);
            yawController.setGains(self.controllerGains.yaw)
            yawController.setUpdateRates(self.controllerRates.yaw);
            yawController.initPerformance(samples);
            
            self.controllers = [pitchController, yawController];
            
            % Building the Wavenet-IIR
            self.neuralNetwork = NetworkFactory.create(self.nnaType);
            self.neuralNetwork.setSynapticRange(self.rangeSynapticWeights)
            self.neuralNetwork.buildNeuronLayer(self.functionType, ...
                self.functionSelected, self.amountFunctions, self.inputs, self.outputs)
            self.neuralNetwork.buildFilterLayer(self.inputs, self.outputs, self.feedbacks, ...
                self.feedforwards, self.persistentSignal)
            self.neuralNetwork.setLearningRates(self.learningRates)
            self.neuralNetwork.bootInternalMemory()
            self.neuralNetwork.bootPerformance(samples)
            self.neuralNetwork.setStatus(self.isTraining)
            
            % Buildind the repository
            self.repository = IRepositoryWNETIIRPMR(self.PREFIX);
            
            self.repository.setModel(self.model)
            self.repository.setControllers(self.controllers)
            self.repository.setNeuralNetwork(self.neuralNetwork)
            self.repository.setTrajectories(self.trajectories)
            self.repository.setFolderPath()
            
            % Execute this part with ANN was trained
            if ~self.isTraining
                [scales, shifts, weights, feedbacks, feedforwards] = self.repository.readParameters();
                self.neuralNetwork.setInitialValues(scales, shifts, weights, feedbacks, feedforwards)
            end
        end
        
        % Executes the algorithm.
        function execute(self)
            self.repository.writeConfiguration()

            for iter = 1:self.trajectories.getSamples()
                kT = self.trajectories.getTime(iter);
                yRef = self.trajectories.getReferences(iter);
                
                up = self.controllers(1).getSignal() + self.offsets(1);
                uy = self.controllers(2).getSignal() + self.offsets(2);
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
                
                self.neuralNetwork.setPerformance(iter)
                self.controllers(1).setPerformance(iter)
                self.controllers(2).setPerformance(iter)
                
                self.neuralNetwork.updateGradientDescent(u, eIdentification)
                
                self.controllers(1).autotune(eTracking(1), eIdentification(1), Gamma(1))
                self.controllers(2).autotune(eTracking(2), eIdentification(2), Gamma(2))
                self.controllers(1).evaluate()
                self.controllers(2).evaluate()
                
                self.log(kT, yRef, yMes, yEst, eTracking, eIdentification, u, Gamma, self.isTraining)
            end
            self.setMetrics()
        end
        
        function saveCSV(self)
            self.repository.writeFinalParameters()
            self.repository.setCutOffResults(false)
            self.repository.write(self.metrics)
            self.repository.setCutOffResults(true)
            self.repository.write(self.metrics)
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
        function log(self, kT, reference, measured, estimated, tracking, identification, control, gamma, training)
            clc
            reference = rad2deg(reference);
            measured = rad2deg(measured);
            estimated = rad2deg(estimated);
            tracking = rad2deg(tracking);
            identification = rad2deg(identification);
            
            fprintf(' :: %s CONTROLLER ::\n TIME >> %10.3f seconds \n', self.PREFIX, kT);
            fprintf('PITCH >> yRef = %+010.4f   yMes = %+010.4f   yEst = %+010.4f   eTck = %+010.4f   eIdf = %+010.4f   signal = %+010.4f   gamma = %+010.4f   %d\n', ...
                reference(1), measured(1), estimated(1), tracking(1), identification(1), control(1), gamma(1), training)
            fprintf('  YAW >> yRef = %+010.4f   yMes = %+010.4f   yEst = %+010.4f   eTck = %+010.4f   eIdf = %+010.4f   signal = %+010.4f   gamma = %+010.4f   %d\n', ...
                reference(2), measured(2), estimated(2), tracking(2), identification(2), control(2), gamma(2), training)
        end
    end
end