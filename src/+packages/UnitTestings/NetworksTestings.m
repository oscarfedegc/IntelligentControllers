classdef NetworksTestings < handle    
    methods (Access = public)
        function self = NetworksTestings()
        end
        
        function run(self)
            tFinal = 15;
            period = 0.005;
            samples = round(tFinal/period);
            
            trajectories = ITrajectory(tFinal, period);
            trajectories.add([0 0 10 10 10 0 0])
            trajectories.add([0 0 -20 -20 0 0 20 10 10 0 0])
            
            model = PlantFactory.create();
            model.setPeriod(period);
            model.initStates(trajectories.getSamples(), deg2rad([-40 0 0 0]))
            
            pitchController = ControllerFactory.create(ControllerTypes.PID);
            yawController = ControllerFactory.create(ControllerTypes.PID);
            
            pitchController.setGains([.001 0 .001]);
            pitchController.setUpdateRates([0 0 0]);
            pitchController.initPerformance(samples);
            
            yawController.setGains([.001 0 .001]);
            yawController.setUpdateRates([0 0 0]);
            yawController.initPerformance(samples);
            
            type = FunctionList.wavelet;
            option = WaveletList.morlet;
            neurons = 3;
            
            feedbacks = 4;
            feedforwards = 5;
            pSignal = 1e-3;
            
            nnaType = NetworkList.Wavenet;
            inputs = 2;
            outputs = 2;
            
            learningRates = [1e-8, 1e-8, 1e-8, 1e-4, 1e-2];
            
            wavenetiir = NetworkFactory.create(nnaType);
            wavenetiir.buildNeuronLayer(type, option, neurons, inputs, outputs);
            wavenetiir.buildFilterLayer(inputs, feedbacks, feedforwards, pSignal);
            wavenetiir.setLearningRates(learningRates);
            wavenetiir.initInternalMemory();
            wavenetiir.initPerformance(samples);
            
            for iter = 1:samples
                kT = trajectories.getTime(iter);
                yRef = trajectories.getReferences(iter);
                
                pitchControl = pitchController.getSignal();
                yawControl = yawController.getSignal();
                
                ctrlSignals = [pitchControl, yawControl];
                
                wavenetiir.evaluate(kT, ctrlSignals)
                wavenetiir.setPerformance(iter)
                
                yMes = model.measured(ctrlSignals, iter);
                yEst = wavenetiir.getOutputs();
                gamma = wavenetiir.getGamma();
                
                eIdentification = yMes - yEst;
                eTracking = yRef - yMes;
                
                wavenetiir.update(ctrlSignals, eIdentification)
                
                pitchController.autotune(eTracking(2), eIdentification(2), gamma(2)) 
                yawController.autotune(eTracking(2), eIdentification(2), gamma(2)) 
                
                pitchController.setPerformance(iter)
                pitchController.evaluate()
                yawController.setPerformance(iter)
                yawController.evaluate()
                
                self.log(kT, yRef, yMes, yEst, eTracking, eIdentification, ctrlSignals)
            end
            
            pitchController.charts('Pitch controller')
            yawController.charts('Yaw controller')
            wavenetiir.charts()

            figure('Name','Simulation results','NumberTitle','off','units','normalized','outerposition',[0 0 1 1]);
            
            estimated = rad2deg(wavenetiir.filterLayer.perfOutputs);
            
            subplot(3, 2, 1)
                plot(rad2deg(trajectories.getTrajectory(1)),'k--','LineWidth',1)
                ylabel('y_{\theta}')
                xlabel('Samples, k')
                xlim([1 samples])
                
            subplot(3, 2, 3)
                plot(rad2deg(model.reads(1)),'r','LineWidth',1)
                ylabel('y_{\theta}')
                xlabel('Samples, k')
                xlim([1 samples])
                
            subplot(3, 2, 5)
                plot(estimated(:,1),'r','LineWidth',1)
                ylabel('y_{\theta}')
                xlabel('Samples, k')
                xlim([1 samples])
                
            subplot(3, 2, 2)
                plot(rad2deg(trajectories.getTrajectory(2)),'k--','LineWidth',1)
                ylabel('y_{\theta}')
                xlabel('Samples, k')
                xlim([1 samples])
                
            subplot(3, 2, 4)
                plot(rad2deg(model.reads(3)),'r','LineWidth',1)
                ylabel('y_{\theta}')
                xlabel('Samples, k')
                xlim([1 samples])
                
            subplot(3, 2, 6)
                plot(estimated(:,2),'r','LineWidth',1)
                ylabel('y_{\theta}')
                xlabel('Samples, k')
                xlim([1 samples])
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