classdef UTCrazyflie6DOF    
    methods (Access = public)
        function self = UTCrazyflie6DOF()
            self.start()
        end
        
        function start(~)
            close, clc;
            
            % Simulation-time parameters
            tFinal = 25;
            period = 0.1;
            initStates = zeros(1,12);
            
            % Desired positions (x, y, z, yaw)
            positions = ITrajectory(tFinal, period, 'meters');
            positions.add([0 0 -0.5 0.5 0 0]) % x
            positions.add([0 0 -1 0 0]) % y
            positions.add([0 0.5 0.5 0.5 0.5 0]) % z
            positions.add([0 -.1 -.1 -.1 -.1 -.1 0]) % yaw
            
            kT = positions.getInstants();
            samples = positions.getSamples();
            perfCtrlSignals = zeros(samples, 4);
            
            % Instance of nonlinear model
            plant = PlantFactory.create(PlantList.crazyflie6DOF);
            plant.setPeriod(period)
            plant.setInitialStates(samples, initStates)
            
            % Controller parameters
            controllerType = ControllerTypes.WavenetPID;
            controllerGains = struct('xposition',   [2 0 0], ...
                                     'yposition',   [2 0 0], ...
                                     'zposition',   [2 0.5 0], ...
                                     'roll',        [3.5 3 0], ...
                                     'pitch',       [6 3 0], ...
                                     'yaw',         [6 1 0.35], ...
                                     'rollrate',    [25 1 0], ...
                                     'pitchrate',   [25 1 0], ...
                                     'yawrate',     [25 15 0], ...
                                     'temp',        [.1 0 0]);
            controllerRates = struct('xposition',   1e-2.*zeros(1,3), ...
                                     'yposition',   1e-2.*zeros(1,3), ...
                                     'zposition',   1e-2.*zeros(1,3), ...
                                     'roll',        1e-2.*zeros(1,3), ...
                                     'pitch',       1e-2.*zeros(1,3), ...
                                     'yaw',         1e-2.*zeros(1,3), ...
                                     'rollrate',    1e-2.*zeros(1,3), ...
                                     'pitchrate',   1e-2.*zeros(1,3), ...
                                     'yawrate',     1e-2.*zeros(1,3), ...
                                     'temp',        1e-2.*zeros(1,3));
            
            % PID controller to regulate the altitude (z) 
            altCtrl = ControllerFactory.create(controllerType);
            altCtrl.setGains(controllerGains.zposition)
            altCtrl.setUpdateRates(controllerRates.zposition)
            altCtrl.initPerformance(samples)
            
            % PID controller to regulate the heading (yaw)
            yawCtrl = ControllerFactory.create(controllerType);
            yawCtrl.setGains(controllerGains.yaw)
            yawCtrl.setUpdateRates(controllerRates.yaw)
            yawCtrl.initPerformance(samples) 
            
            % PD controllers to regulate the positions (x and y)
            xpsCtrl = ControllerFactory.create(controllerType);
            xpsCtrl.setGains(controllerGains.xposition)
            xpsCtrl.setUpdateRates(controllerRates.xposition)
            xpsCtrl.initPerformance(samples)
            
            ypsCtrl = ControllerFactory.create(controllerType);
            ypsCtrl.setGains(controllerGains.yposition)
            ypsCtrl.setUpdateRates(controllerRates.yposition)
            ypsCtrl.initPerformance(samples)
            
            % PI controllers to regulate attitude (roll and pitch)
            rollCtrl = ControllerFactory.create(controllerType);
            rollCtrl.setGains(controllerGains.roll)
            rollCtrl.setUpdateRates(controllerRates.roll)
            rollCtrl.initPerformance(samples)
            
            pitchCtrl = ControllerFactory.create(controllerType);
            pitchCtrl.setGains(controllerGains.pitch)
            pitchCtrl.setUpdateRates(controllerRates.pitch)
            pitchCtrl.initPerformance(samples)
            
            % PID controllers to regulate the angular rates (roll, pitch and yaw)
            rollrateCtrl = ControllerFactory.create(controllerType);
            rollrateCtrl.setGains(controllerGains.rollrate)
            rollrateCtrl.setUpdateRates(controllerRates.rollrate)
            rollrateCtrl.initPerformance(samples)
            
            pitchrateCtrl = ControllerFactory.create(controllerType);
            pitchrateCtrl.setGains(controllerGains.pitchrate)
            pitchrateCtrl.setUpdateRates(controllerRates.pitchrate)
            pitchrateCtrl.initPerformance(samples)
            
            yawrateCtrl = ControllerFactory.create(controllerType);
            yawrateCtrl.setGains(controllerGains.yawrate)
            yawrateCtrl.setUpdateRates(controllerRates.yawrate)
            yawrateCtrl.initPerformance(samples)
            
            for iter = 1:samples
                sDesired = positions.getReferences(iter);
                
                v1 = altCtrl.getSignal();
                v2 = rollrateCtrl.getSignal();
                v3 = pitchrateCtrl.getSignal();
                v4 = yawrateCtrl.getSignal();
                
                u = [v1 v2 v3 v4];
                perfCtrlSignals(iter,:) = u;
                
                realStates = plant.measured(u, iter);
                
                xError = sDesired(1) - realStates(1);
                yError = sDesired(2) - realStates(3);
                
                xpsCtrl.autotune(xError, 0, 0)
                ypsCtrl.autotune(yError, 0, 0)
                
                xpsCtrl.evaluate()
                ypsCtrl.evaluate()
                
                rollDesired = xpsCtrl.getSignal();
                pitchDesired = ypsCtrl.getSignal();
                
                rollError = rollDesired - realStates(7);
                pitchError = pitchDesired - realStates(9);
                yawError = sDesired(4) - realStates(11);
                
                rollCtrl.autotune(rollError, 0, 0)
                pitchCtrl.autotune(pitchError, 0, 0)
                yawCtrl.autotune(yawError, 0, 0)
                
                rollCtrl.evaluate()
                pitchCtrl.evaluate()
                yawCtrl.evaluate()
                
                rollrateDesired = rollCtrl.getSignal();
                pitchrateDesired = pitchCtrl.getSignal();
                yawrateDesired = yawCtrl.getSignal();
                
                rollrateError = rollrateDesired - realStates(8);
                pitchrateError = pitchrateDesired - realStates(10);
                yawrateError = yawrateDesired - realStates(12);
                zError = sDesired(3) - realStates(5);
                
                rollrateCtrl.autotune(rollrateError, 0, 0)
                pitchrateCtrl.autotune(pitchrateError, 0, 0)
                yawrateCtrl.autotune(yawrateError, 0, 0)
                altCtrl.autotune(zError, 0, 0)
                
                rollrateCtrl.evaluate()
                pitchrateCtrl.evaluate()
                yawrateCtrl.evaluate()
                altCtrl.evaluate()
            end
            
            desired = positions.getAllReferences();
            measurement = plant.getPerformance([1 3 5 11]);
            
            figure(1)
                subplot(2, 3, 1)
                hold on
                plot(kT, desired(:,1))
                plot(kT, measurement(:,1))
                xlabel('Time [sec]')
                ylabel('x [m]')
                
                subplot(2, 3, 2)
                plot(kT, desired(:,2))
                hold on
                plot(kT, measurement(:,2))
                xlabel('Time [sec]')
                ylabel('y [m]')
                
                subplot(2, 3, 4)
                plot(kT, desired(:,3))
                hold on
                plot(kT, measurement(:,3))
                xlabel('Time [sec]')
                ylabel('z [m]')
                
                subplot(2, 3, 5)
                plot(kT, desired(:,4))
                hold on
                plot(kT, measurement(:,4))
                xlabel('Time [sec]')
                ylabel('yaw [rad]')
                
                subplot(2, 3, 3)
                plot3(desired(:,1), desired(:,2), desired(:,3))
                xlabel('x [m]')
                ylabel('y [m]')
                ylabel('z [m]')
                
                subplot(2, 3, 6)
                plot3(measurement(:,1), measurement(:,2), measurement(:,3),'r')
                xlabel('x [m]')
                ylabel('y [m]')
                ylabel('z [m]')
        
            figure(2)
                subplot(2, 2, 1)
                plot(kT, perfCtrlSignals(:,1))
                xlabel('Time [sec]')
                ylabel('V1')
                
                subplot(2, 2, 2)
                plot(kT, perfCtrlSignals(:,2))
                xlabel('Time [sec]')
                ylabel('V2')
                
                subplot(2, 2, 3)
                plot(kT, perfCtrlSignals(:,3))
                xlabel('Time [sec]')
                ylabel('V3')
                
                subplot(2, 2, 4)
                plot(kT, perfCtrlSignals(:,4))
                xlabel('Time [sec]')
                ylabel('V4')
        end
    end
end