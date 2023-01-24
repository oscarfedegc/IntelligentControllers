% This class that calls the other classes and generates the simulations
classdef OpenLoop < Strategy
    properties (Access = protected)
        PREFIX = 'OpenLoop';
    end
    
    properties (Access = private)
        tFinal, period {mustBeNumeric}
        plantType % {must be PlantList}
        controllerType % {must be ControllerTypes}
        references, controllerGains, controllerRates % {must be Structure}
        
        learningRates, persistentSignal, initialStates {mustBeNumeric}
        
        controlSignals {mustBeNumeric}
        fNormErrors {mustBeNumeric}
    end
    
    methods (Access = public)
        % Class constructor
        function self = OpenLoop()
            return
        end
        
        % In this function, the user must give the simulations parameters
        function setup(self)
            % Time parameters
            self.tFinal = 30;        % Simulation time [sec]
            
            % Plant parameters
            self.plantType = PlantList.helicopter2DOF;
            self.period = 0.005;     % Plant sampling period [sec]
            self.initialStates = [-40 0 0 0];
            
            % Trajectory parameters (positions in degrees)
            self.references = struct('pitch', [0 0 10 10 10 0 0], ...
                                     'yaw', [0 0 -20 -20 0 0]);
                                 
            % Controller parameters
            self.controllerType = ControllerTypes.ClassicalPID;
            self.controllerGains = struct('pitch', [1 1 1 10 100 100], ...
                                            'yaw', [1 1 1 10 100 100]);
            self.controllerRates = struct('pitch', [1e-5 1e-5 1e-5 1e-5 1e-5 1e-5],...
                                            'yaw', [1e-5 1e-5 1e-5 1e-5 1e-5 1e-5]);
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
            
            % Initialize the normalized error arrays
            self.fNormErrors = zeros(samples,2);
        end
        
        % Executes the algorithm.
        function execute(self)            
            for iter = 1:self.trajectories.getSamples()
                kT = self.trajectories.getTime(iter);
                yRef = self.trajectories.getReferences(iter);
                
                up = self.controllers(1).getSignal();
                uy = self.controllers(2).getSignal();
                u = [up uy];
                
                yMes = self.model.measured(u, iter);
                yEst = [0 0];
                
                eTracking = yRef - yMes;
                eIdentification = ones(1,2);
                
                self.controllers(1).autotune(eTracking(1))
                self.controllers(2).autotune(eTracking(2))
                
                self.controllers(1).evaluate()
                self.controllers(2).evaluate()
                
                self.controllers(1).setPerformance(iter)
                self.controllers(2).setPerformance(iter)
                
                self.log(kT, yRef, yMes, yEst, eTracking, eIdentification, u)
            end
        end
        
        function saveCSV(~)
        end
        
        function charts(self)
            self.identification();
            self.controllers(1).charts('Pitch controller')
            self.controllers(2).charts('Yaw controller')
        end
    end
    
    methods (Access = protected)        
        % Display the algorithm behavior by means of the console messages.
        %
        %   @param {float} kT Instant of the time.
        %
        function log(self, kT, reference, measured, estimated, tracking, identification, control)
            clc
            reference = rad2deg(reference);
            measured = rad2deg(measured);
            estimated = rad2deg(estimated);
            tracking = rad2deg(tracking);
            identification = rad2deg(identification);
            
            fprintf(' :: %s CONTROLLER ::\n TIME >> %6.3f seconds \n', self.PREFIX, kT);
            fprintf('PITCH >> yRef = %+6.4f   yMes = %+6.3f   yEst = %+6.4f   eTrackig = %+6.4f   eIdentification = %+6.4f   ctrlSignal = %+6.3f\n', ...
                reference(1), measured(1), estimated(1), tracking(1), identification(1), control(1))
            fprintf('  YAW >> yRef = %+6.4f   yMes = %+6.3f   yEst = %+6.4f   eTrackig = %+6.4f   eIdentification = %+6.4f   ctrlSignal = %+6.3f\n', ...
                reference(2), measured(2), estimated(2), tracking(2), identification(2), control(2))
        end
        
        function identification(self)
            figure('Name','Identification process','NumberTitle','off','units','normalized',...
                'outerposition',[0 0 1 1]);
            
            tag = {'Pitch'; 'Yaw'};
            samples = self.trajectories.getSamples();
            rows = 1;
            cols = 2;
            
            for item = 1:cols
                subplot(rows, cols, item)
                hold on
                plot(rad2deg(self.trajectories.getTrajectory(item)),'k--','LineWidth',1)
                plot(rad2deg(self.model.reads(item)),'r','LineWidth',1)
                legend('Reference','Measured')
                ylabel(sprintf('%s', string(tag(item))))
                xlim([1 samples])
            end
        end
    end
end