classdef UTHelicopter2DOF    
    methods (Access = public)
        function self = UTHelicopter2DOF()
            self.start()
        end
        
        function start(self)
            close, clc;
            
            % Simulation-time parameters
            tFinal = 5;
            period = 0.01;
            initStates = zeros(1,4);
            initStates(1) = -0.7;
            
            % Desired positions to get samples
            positions = ITrajectory(tFinal, period, 'meters');
            kT = positions.getInstants();
            samples = positions.getSamples();
            perfCtrlSignals = zeros(samples, 2);
            
            % Instance of nonlinear model
            plant = PlantFactory.create(PlantList.helicopter2DOF);
            plant.setPeriod(period)
            plant.setInitialStates(samples, initStates)
            
            for iter = 1:samples
                pitchCtrl = 10*sin(2*iter*period);
                yawCtrl = 50*cos(4*iter*period);
                
                u = [pitchCtrl yawCtrl];
                
                perfCtrlSignals(iter,:) = u;
                plant.measured(u, iter);
            end
            
            measurement = plant.getPerformance(1:4);
            terms = plant.getTerms();
            
            figure('Name',string(class(self)),'NumberTitle','off','units','normalized','outerposition',[0 0 1 1]);
                subplot(2, 2, 1)
                hold on
                plot(kT, perfCtrlSignals(:,1))
                plot(kT, perfCtrlSignals(:,2))
                xlabel('Time [sec]')
                ylabel('Control signal [V]')
                legend('u_\theta','u_\phi')
                
                subplot(2, 2, 2)
                hold on
                plot(kT, measurement(:,1))
                plot(kT, measurement(:,3))
                xlabel('Time [sec]')
                ylabel('Position [rad]')
                legend('y_\theta','y_\phi')
                
                subplot(2, 2, 3)
                hold on
                plot(kT, terms(:,1))
                plot(kT, terms(:,2))
                xlabel('Time [sec]')
                legend('f_1','f_2')
                
                subplot(2, 2, 4)
                hold on
                plot(kT, terms(:,3))
                plot(kT, terms(:,4))
                plot(kT, terms(:,5))
                plot(kT, terms(:,6))
                xlabel('Time [sec]')
                legend('g_{1,1}','g_{1,2}','g_{2.1}','g_{2,2}')
        end
    end
end