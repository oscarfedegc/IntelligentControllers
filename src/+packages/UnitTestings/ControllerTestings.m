classdef ControllerTestings < handle    
    methods (Access = public)
        function self = ControllerTestings()
            clc, close all
            self.run()            
        end
        
        function run(self)
            tFinal = 60;
            period = 0.005;
            samples = round(tFinal/period);
            
            model = PlantFactory.create(PlantList.helicopter2DOF);
            model.setPeriod(period);
            model.setInitialStates(samples + 1, deg2rad([0 0 0 0]))
            
            references = struct('pitch',  [0 10 10 0 0 -10 -10 0]', ...
                                'yaw',    [0 -10 -10 0 0 10 10 0]', ...
                                'tpitch', [0 5 15 20 35 40 55 60]',...
                                'tyaw',   [0 10 15 25 35 45 55 60]');
                            
            trajectories = ITrajectory(tFinal, period, 'rads');
            trajectories.setTypeRef('T01')
            trajectories.addPositionsWithTime(references)
            
            pitchController = ControllerFactory.create(ControllerTypes.ClassicalPID);
            pitchController.setGains([15 5*period 5/period]);
            pitchController.initPerformance(samples);
            pitchOffset = 12.5;
            
            yawController = ControllerFactory.create(ControllerTypes.ClassicalPID);
            yawController.setGains([10 5*period 7/period]);
            yawController.initPerformance(samples);
            yawOffset = -4.5;
            
            for iter = 1:samples
                kT = trajectories.getTime(iter);
                yRef = trajectories.getReferences(iter);
                
                if iter > 100
                    up = pitchController.getSignal() + pitchOffset;
                    uy = yawController.getSignal() + yawOffset;
                else
                    up = pitchController.getSignal();
                    uy = yawController.getSignal();
                end
                
                u = [up uy];
                yMes = model.measured(u, iter);
                eTracking = yRef - yMes;
                
                if isnan(eTracking(1)) || isnan(eTracking(2))
                    break
                end
                
                pitchController.evaluate();
                pitchController.setPerformance(iter);
                pitchController.updateMemory(eTracking(1))
                
                yawController.evaluate();
                yawController.setPerformance(iter);
                yawController.updateMemory(eTracking(2))
                
                self.log(kT, yRef, yMes, eTracking, u)
            end
            
            pitchController.charts('Controller', pitchOffset)
            yawController.charts('Controller', yawOffset)
        end
        
        function log(~, kT, reference, measured, tracking, control)
            clc
            reference = rad2deg(reference);
            measured = rad2deg(measured);
            tracking = rad2deg(tracking);
            
            fprintf(' :: %s CONTROLLER ::\n TIME >> %10.3f seconds \n', 'CLASSICAL', kT);
            fprintf('PITCH >> yRef = %+010.4f   yMes = %+010.4f   eTck = %+010.4f   signal = %+010.4f\n', ...
                reference(1), measured(1), tracking(1), control(1))
            fprintf('  YAW >> yRef = %+010.4f   yMes = %+010.4f   eTck = %+010.4f   signal = %+010.4f\n', ...
                reference(2), measured(2), tracking(2), control(2))
        end
    end
end