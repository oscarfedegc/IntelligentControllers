% This class that calls the other classes and generates the simulations
classdef IWNETPID_CRAZYFLIE_6DOF < Strategy
    properties (Access = public)
        PREFIX = 'WNet-IIR-PID-6-DOF-Crazyflie'; % It is use to create the folder and output files
    end
    
    methods (Access = public)
        % Class constructor
        function self = IWNETPID_CRAZYFLIE_6DOF()
            return
        end
        
        % In this function, the user must give the simulations parameters
        function setup(self)
            % Time parameters
            self.tFinal = 10; % Simulation time [sec]
            
            % Plant parameters
            self.plantType = PlantList.crazyflie6DOF;
            self.period = 0.1; % Plant sampling period [sec]
            self.initialStates = zeros(1,12);

            % Trajectory parameters (positions in degrees)
            self.references = struct('xpos', [0 0], ...
                                     'ypos', [0 0], ...
                                     'zpos', [1 1], ...
                                     'phi',  [0 0], ...
                                     'theta',[0 0], ...
                                     'psi',  [0 0]);
            
            % Controller parameters
            self.controllerType = ControllerTypes.WavenetPID;
            self.controllerGains = struct('rotor1', [1 0 0], ...
                                          'rotor2', [1 0 0], ...
                                          'rotor3', [1 0 0], ...
                                          'rotor4', [1 0 0]);
            self.controllerRates = struct('rotor1', 1e-2.*zeros(1,3), ...
                                          'rotor2', 1e-2.*zeros(1,3), ...
                                          'rotor3', 1e-2.*zeros(1,3), ...
                                          'rotor4', 1e-2.*zeros(1,3));
            
            % Wavenet-IIR parameters
            self.nnaType = NetworkList.WavenetIIR;
            self.functionType = FunctionList.wavelet;
            self.functionSelected = WaveletList.morlet;
            
            self.inputs = 4;
            self.outputs = 6;
            self.amountFunctions = 6;
            self.feedbacks = 4;
            self.feedforwards = 2;
            self.persistentSignal = 1;
            
            self.learningRates = 1e-5.*zeros(1,5);
            self.rangeSynapticWeights = 1e-5;
        end
        
        % This funcion calls the class to generates the objects for the simulation.
        function builder(self)
            % Building the trajectories
            self.trajectories = ITrajectory(self.tFinal, self.period, 'meters');
            self.trajectories.add(self.references.xpos)
            self.trajectories.add(self.references.ypos)
            self.trajectories.add(self.references.zpos)
            self.trajectories.add(self.references.phi)
            self.trajectories.add(self.references.theta)
            self.trajectories.add(self.references.psi)
            
            % Bulding the plant
            samples = self.trajectories.getSamples();
            
            self.fNormApprox = zeros(samples, 3);
            self.fNormErrors = zeros(samples, 3);
            
            self.model = PlantFactory.create(self.plantType);
            self.model.setPeriod(self.period);
            self.model.setInitialStates(samples + 1, self.initialStates)
            
            % Building the 1st rotor controller            
            rotor1Ctrl = ControllerFactory.create(self.controllerType);
            rotor1Ctrl.setGains(self.controllerGains.rotor1)
            rotor1Ctrl.setUpdateRates(self.controllerRates.rotor1)
            rotor1Ctrl.initPerformance(samples)
            
            % Building the 2nd rotor controller
            rotor2Ctrl = ControllerFactory.create(self.controllerType);
            rotor2Ctrl.setGains(self.controllerGains.rotor2)
            rotor2Ctrl.setUpdateRates(self.controllerRates.rotor2)
            rotor2Ctrl.initPerformance(samples)
            
            % Building the 3rd rotor controller
            rotor3Ctrl = ControllerFactory.create(self.controllerType);
            rotor3Ctrl.setGains(self.controllerGains.rotor3)
            rotor3Ctrl.setUpdateRates(self.controllerRates.rotor3)
            rotor3Ctrl.initPerformance(samples)
            
            % Building the 4th rotor controller
            rotor4Ctrl = ControllerFactory.create(self.controllerType);
            rotor4Ctrl.setGains(self.controllerGains.rotor4)
            rotor4Ctrl.setUpdateRates(self.controllerRates.rotor4)
            rotor4Ctrl.initPerformance(samples)
            
            self.controllers = [rotor1Ctrl, rotor2Ctrl, rotor3Ctrl, rotor3Ctrl];
            
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
            
            % Buildind the repository
            self.repository = IRepositoryWNETIIRPMR(self.PREFIX);
            
            self.repository.setModel(self.model)
            self.repository.setControllers(self.controllers)
            self.repository.setNeuralNetwork(self.neuralNetwork)
            self.repository.setTrajectories(self.trajectories)
            self.repository.setFolderPath()
        end
        
        % Executes the algorithm.
        function execute(self)
%             self.repository.writeConfiguration()

            for iter = 1:self.trajectories.getSamples()
                kT = self.trajectories.getTime(iter);
                yRef = self.trajectories.getReferences(iter);
                
                v1 = sin(iter*self.period);
                v2 = cos(iter*self.period);
                v3 = sin(iter*self.period);
                v4 = cos(iter*self.period);
                
                u = [v1 v2 v3 v4];
                wr = -v1 + v2 - v3 + v4;
                
                self.neuralNetwork.evaluate(kT, u)
                
                yMes = self.model.measured(u, wr, iter);
                yEst = self.neuralNetwork.getOutputs();
                Gamma = self.neuralNetwork.filterLayer.getGamma();

                realStates = [yMes(1), yMes(3), yMes(5), yMes(7), yMes(9), yMes(10)];
                
                eTracking = yRef - realStates;
                eIdentification = realStates - yEst;
                
                if isnan(eTracking(1)) || isnan(eTracking(2)) || ...
                        isnan(eIdentification(1)) || isnan(eIdentification(2))
                    self.isSuccessfully = false;
                    break
                end
                
                self.neuralNetwork.setPerformance(iter)
                self.controllers(1).setPerformance(iter)
                self.controllers(2).setPerformance(iter)
                self.controllers(3).setPerformance(iter)
                self.controllers(4).setPerformance(iter)
                
                self.neuralNetwork.updateGradientDescent(u, eIdentification)
                
                self.controllers(1).autotune(eTracking(1), eIdentification(1), Gamma(1))
                self.controllers(2).autotune(eTracking(4), eIdentification(2), Gamma(2))
                self.controllers(3).autotune(eTracking(5), eIdentification(3), Gamma(3))
                self.controllers(4).autotune(eTracking(6), eIdentification(4), Gamma(4))
                
                self.controllers(1).evaluate()
                self.controllers(2).evaluate()
                self.controllers(3).evaluate()
                self.controllers(4).evaluate()
                
                self.log(kT, yRef, realStates, yEst, eTracking, eIdentification, u, Gamma)
                pause(0.01)
            end
            self.setMetrics()
        end
        
        function saveCSV(self)
            self.repository.setCutOffResults(false)
            self.repository.write(self.metrics)
            self.repository.setCutOffResults(true)
            self.repository.write(self.metrics)
        end
        
        function showCharts(self)
            self.neuralNetwork.charts('noncompact')
            self.controllers(1).charts('1st controller', 0)
            self.controllers(2).charts('2nd controller', 0)
            self.controllers(3).charts('3rd controller', 0)
            self.controllers(4).charts('4th controller', 0)
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
            fprintf('XPOS >> ref = %+010.4f   mes = %+010.4f   est = %+010.4f   tck = %+010.4f   idf = %+010.4f   v1 = %+010.4f   gamma = %+010.4f\n', ...
                reference(1), measured(1), estimated(1), tracking(1), identification(1), control(1), gamma(1))
            fprintf('YPOS >> ref = %+010.4f   mes = %+010.4f   est = %+010.4f   tck = %+010.4f   idf = %+010.4f   v1 = %+010.4f   gamma = %+010.4f\n', ...
                reference(2), measured(2), estimated(2), tracking(2), identification(2), control(1), gamma(2))
            fprintf('ZPOS >> ref = %+010.4f   mes = %+010.4f   est = %+010.4f   tck = %+010.4f   idf = %+010.4f   v1 = %+010.4f   gamma = %+010.4f\n', ...
                reference(3), measured(3), estimated(3), tracking(3), identification(3), control(1), gamma(3))
            fprintf('PHI  >> ref = %+010.4f   mes = %+010.4f   est = %+010.4f   tck = %+010.4f   idf = %+010.4f   v1 = %+010.4f   gamma = %+010.4f\n', ...
                reference(4), measured(4), estimated(4), tracking(4), identification(4), control(2), gamma(4))
            fprintf('PHI  >> ref = %+010.4f   mes = %+010.4f   est = %+010.4f   tck = %+010.4f   idf = %+010.4f   v1 = %+010.4f   gamma = %+010.4f\n', ...
                reference(4), measured(4), estimated(4), tracking(4), identification(5), control(2), gamma(4))
            fprintf('PHI  >> ref = %+010.4f   mes = %+010.4f   est = %+010.4f   tck = %+010.4f   idf = %+010.4f   v1 = %+010.4f   gamma = %+010.4f\n', ...
                reference(4), measured(4), estimated(4), tracking(4), identification(6), control(2), gamma(4))
        end
    end
end