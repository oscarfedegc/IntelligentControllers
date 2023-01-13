classdef IWIIRPID < Strategy
    properties (Access = public)
        model % {must be Plant}
        controllers % {must be Controller}
        network % {must be NetworkScheme}
        trajectories % {must be ITrajectories}
        isRandom {mustBeInteger}
    end
    
    methods (Access = public)
        function self = IWIIRPID()
            return
        end
        
        function trajectoryBuilder(self, tFinal, period, pitchReference, yawReference)
            self.trajectories = ITrajectory(tFinal, period);
            self.trajectories.add(pitchReference);
            self.trajectories.add(yawReference);
        end
        
        function modelBuilder(self, period, initPositions)
            self.model = PlantFactory.create();
            self.model.setPeriod(period);
            self.model.initStates(self.trajectories.getSamples(), deg2rad(initPositions));
        end
        
        function controllerBuilder(self)
            pitchControl = ControllerFactory.create(ControllerTypes.PID);
            yawControl = ControllerFactory.create(ControllerTypes.PID);
            
            pitchControl.setGains([100 2.5 50]);
            pitchControl.setUpdateRates([0.75 7.5e-5 1.25]);
            
            yawControl.setGains([150 0.5 15]);
            yawControl.setUpdateRates([0.75 5e-5 1.25]);
            
            self.controllers = [pitchControl, yawControl];
        end
        
        function networkBuilder(self, functionType, selection, neurons, inputs, outputs, coeffsM, coeffsN)
            self.network = NetworkFactory.create(NetworkList.Wavenet);
            self.network.buildNeuronLayer(functionType, selection, neurons, inputs, outputs);
            self.network.buildFilterLayer(inputs, coeffsM, coeffsN, 0.1);
            self.network.setLearningRates(rand(1,5));
            self.network.initInternalMemory();
        end
        
        function execute(self)
            for iter = 1:self.trajectories.getSamples()
                kT = self.trajectories.getInstant(iter);               
                yRef = self.trajectories.getPosition(iter,[1 2]);
                
                up = self.controllers(1).getSignal();
                uy = self.controllers(2).getSignal();
                u = [up uy];
                
                self.network.evaluate(kT, u)
                
                yMes = self.model.measured(u, iter);
                yEst = self.network.getOutputs();
                Gamma = self.network.filterLayer.getGamma();
                
                eTracking = yRef - yMes;
                eIdentification = yMes - yEst;
                
                self.network.update(u, eIdentification)
                
                self.controllers(1).updateMemory(eTracking(1))
                self.controllers(2).updateMemory(eTracking(2))
                self.controllers(1).autotune(eIdentification(1), Gamma(1))
                self.controllers(2).autotune(eIdentification(2), Gamma(2))
                self.controllers(1).evaluate()
                self.controllers(2).evaluate()
                
                self.log(kT, yRef, yMes, yEst, eTracking, eIdentification, u)
            end
        end
        
        function saveResults(self)
        end
    end
    
    methods (Access = protected)
        function log(~, kT, reference, measured, estimated, tracking, identification, control)
            clc
            fprintf(' TIME == %6.3f seconds ==\n', kT);
            fprintf('PITCH >> yr = %+6.4f   ym = %+6.3f   ye = %+6.4f   et = %+6.4f   ei = %+6.4f   u = %+6.3f\n', ...
                reference(1), measured(1), estimated(1), tracking(1), identification(1), control(1))
            fprintf('  YAW >> yr = %+6.4f   ym = %+6.3f   ye = %+6.4f   et = %+6.4f   ei = %+6.4f   u = %+6.3f\n', ...
                reference(2), measured(2), estimated(2), tracking(2), identification(2), control(2))
        end
    end
end