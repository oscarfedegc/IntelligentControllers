% This class that calls the other classes and generates the simulations
classdef IWIIRIDF < Strategy
    properties (Access = public)
        PREFIX = 'WaveNet-IIR Identification'; % It is use to create the folder and output files
        REPOSITORY 
    end
    
    methods (Access = public)
        % Class constructor
        function self = IWIIRIDF()
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
            self.controllerType = ControllerTypes.WavenetPMR;
            self.controllerGains = struct('pitch', [100 100 75 .1 .1 .1], ...
                                            'yaw', [300 100 75 .5 .5 .5]);
            self.controllerRates = struct('pitch', 100.*ones(1,6),...
                                            'yaw', 100.*ones(1,6));
            
            self.offsets = [12.5 -4.0];
            
            % Wavenet-IIR parameters
            self.nnaType = NetworkList.WavenetIIR;
            self.functionType = FunctionList.wavelet;
            self.functionSelected = WaveletList.polywog4;
            
            self.inputs = 2;
            self.outputs = 2;
            self.amountFunctions = 3;
            self.feedbacks = 4;
            self.feedforwards = 2;
            self.persistentSignal = 50;
            
            self.learningRates = [10e-5 10e-5 5e-6 5e-1 5e-2];
            self.rangeSynapticWeights = 0.001;
            
            self.idxStates = [1 3];
            
            % Training status
            self.isTraining = true;
            
            % Trajectory parameters (positions in degrees)
            if self.isTraining
                trajectorySelected = 1;
                self.REPOSITORY = 'src/+repositories/values/CTRL SIGNALS 60S V01.csv';
            else
                trajectorySelected = 2;
                self.REPOSITORY = 'src/+repositories/values/CTRL SIGNALS 60S V02.csv';
            end
            
            switch trajectorySelected
                case 1
                    self.references = struct('pitch',  0, ...
                                             'yaw',    0);
                case 2
                    self.references = struct('pitch',  [5 0 0 -5 -5 0 5 10 0 5 5 0], ...
                                             'yaw',    [0 0 5 5 5 0 -5 -10 0 0 5 0],...
                                             'tpitch', 5:5:self.tFinal,...
                                             'tyaw',   5:5:self.tFinal);
            end
        end
        
        % This funcion calls the class to generates the objects for the simulation.
        function builder(self)
            % Building the trajectories
            self.trajectories = ITrajectory(self.tFinal, self.period, 'rads');
            
            if self.isTraining
                self.trajectories.add(self.references.pitch)
                self.trajectories.add(self.references.yaw)
            else
                self.trajectories.addPositions(self.references.pitch, self.references.tpitch)
                self.trajectories.addPositions(self.references.yaw, self.references.tyaw)
            end
            
            self.dampingSignal()
            
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
                u = self.trajectories.getReferences(iter);
                
                self.neuralNetwork.evaluate(kT, u)
                
                yMes = self.model.measured(u, iter);
                yEst = self.neuralNetwork.getOutputs();
                Gamma = self.neuralNetwork.filterLayer.getGamma();
                
                mu = [0, 0];
                sigma = [0.025, 0.020];
                noise = [sigma(1)*randn(1,1) + mu(1), sigma(2)*randn(1,1) + mu(2)];
                
                self.model.addNoise(noise, iter);
                
                yMes = yMes + noise;

                eIdentification = yMes - yEst;
                
                if isnan(eIdentification(1)) || isnan(eIdentification(2))
                    self.isSuccessfully = false;
                    break
                end
                
                self.neuralNetwork.setPerformance(iter)
                self.neuralNetwork.updateGradientDescent(u, eIdentification)                
                self.log(kT, yMes, yEst, eIdentification, u, Gamma, self.isTraining)
            end
            self.setMetrics(self.idxStates)
        end
        
        function saveCSV(self)
            self.repository.writeFinalParameters()
            self.repository.setCutOffResults(false)
            self.repository.write(self.metrics, self.idxStates, self.offsets)
        end
        
        function showCharts(self)
            self.neuralNetwork.charts('noncompact')
            self.plotting()
        end
    end
    
    methods (Access = protected)
        % Display the algorithm behavior by means of the console messages.
        %
        %   @param {float} kT Instant of the time.
        %
        function log(self, kT, measured, estimated, identification, control, gamma, training)
            clc
            measured = rad2deg(measured);
            estimated = rad2deg(estimated);
            identification = rad2deg(identification);
            
            fprintf(' :: %s ::\n TIME >> %10.3f seconds \n', self.PREFIX, kT);
            fprintf('PITCH >> yMes = %+010.4f   yEst = %+010.4f   eIdf = %+010.4f   signal = %+010.4f   gamma = %+010.4f   %d\n', ...
                measured(1), estimated(1), identification(1), control(1), gamma(1), training)
            fprintf('  YAW >> yMes = %+010.4f   yEst = %+010.4f   eIdf = %+010.4f   signal = %+010.4f   gamma = %+010.4f   %d\n', ...
                measured(2), estimated(2), identification(2), control(2), gamma(2), training)
        end
        
        function dampingSignal(self)            
            data = readtable(self.REPOSITORY);
            data = table2array(data);            
            self.trajectories.setReferences([data(:,2) data(:,3)])
        end
    end
end