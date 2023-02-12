classdef NetworksTestings < handle
    methods (Access = public)
        function self = NetworksTestings()
        end
        
        function run(self)
            tFinal = 60;
            period = 0.005;
            samples = round(tFinal/period);
            
            x = 0 : period : tFinal-period;
            trainingInputs = exp(-x./50) .* 5 .* sin(0.2.*x);
            trainingInputs2 = -sin(0.005.*x.^2) - 1.2*cos(0.1.*x) - sin(0.05.*x.^2);
            
            targetOutputs = trainingInputs;
            targetOutputs2 = trainingInputs2;
            
            targets = [targetOutputs', targetOutputs2'];
            
            nnaType = NetworkList.Wavenet;
            type = FunctionList.wavelet;
            option = WaveletList.morlet;
            inputs = 2;
            outputs = 2;
            neurons = 10;
            
            learningRates = [0.005 0.01 0.0005];
            
            WNET = NetworkFactory.create(nnaType);
            WNET.buildNeuronLayer(type, option, neurons, inputs, outputs);
            WNET.setLearningRates(learningRates);
            WNET.bootPerformance(samples);
            
            wIdent = zeros(samples,3);
            isOK = true;
            
            for iter = 1:samples
                kT = iter * period;
                
                WNET.evaluate(kT, [trainingInputs(iter), trainingInputs2(iter)])
                WNET.setPerformance(iter)
                
                estimated = WNET.getOutputs();
                
                if isnan(estimated(1)) || isnan(estimated(2))
                    disp('Failed!')
                    isOK = ~isOK;
                    break
                end
                
                eIdent_ = estimated - targets(iter,:);
                
                wIdent(iter,:) = [eIdent_, WNET.getCostFunction(eIdent_)];
                
                WNET.update([trainingInputs(iter), trainingInputs2(iter)], eIdent_)
                
                clc
                fprintf(' TIME == %10.3f seconds ==\n', kT);
                fprintf(' %+010.3f\t%+010.3f\t%+010.3f\t%+010.3f\t%+010.3f\t%+010.3f\n', ...
                    targets(iter,1), estimated(1), targets(iter,2), estimated(2),...
                    eIdent_(1), eIdent_(2));
            end
            
            if isOK
                disp('Single wavenet')
                self.setMetrics(wIdent(:,1), period)
                self.setMetrics(wIdent(:,2), period)

                WNET.charts('compact');
                figure('Name','Simulation results single wavenet','NumberTitle','off','units','normalized','outerposition',[0 0 1 1]);

                estimated = WNET.getBehavior();

                subplot(3, 2, 1)
                    plot(trainingInputs,'k--','LineWidth',1)
                    ylabel('u_{\theta}')
                    xlabel('Samples, k')
                    xlim([1 samples])

                subplot(3, 2, 3)
                    hold on
                    plot(targetOutputs,'LineWidth',1)
                    plot(estimated(:,1),'LineWidth',1)
                    legend('Target output','NNA Output');
                    xlabel('Samples, k')
                    xlim([1 samples])

                subplot(3, 2, 5)
                    hold on
                    plot(wIdent(:,1),'r','LineWidth',1)
                    plot(wIdent(:,2),'b:','LineWidth',1)
                    legend('e_1','e_2');
                    ylabel('Identification error')
                    xlabel('Samples, k')
                    xlim([1 samples])

                subplot(3, 2, 2)
                    plot(trainingInputs2,'k--','LineWidth',1)
                    ylabel('u_{\phi}')
                    xlabel('Samples, k')
                    xlim([1 samples])

                subplot(3, 2, 4)
                    hold on
                    plot(targetOutputs2,'LineWidth',1)
                    plot(estimated(:,2),'LineWidth',1)
                    legend('Target output','NNA Output');
                    xlabel('Samples, k')
                    xlim([1 samples])

                subplot(3, 2, 6)
                    plot(wIdent(:,3),'r','LineWidth',1)
                    ylabel('Cost function')
                    xlabel('Samples, k')
                    xlim([1 samples])
            end
        end
        
        function runModel(self)
            tFinal = 30;
            period = 0.005;
            samples = round(tFinal/period);
            
            x = 0:period:tFinal;
            
            trainingInputs = 5 .* cos(0 .* x);
            trainingInputs2 = -4 .* cos(0 .* x);
            
            plantType = PlantList.helicopter2DOF;
            initialStates = [-40 0 0 0];
            model = PlantFactory.create(plantType);
            model.setPeriod(period);
            model.setInitialStates(samples, deg2rad(initialStates))
            
            for iter = 1:samples
                u = [trainingInputs(iter), trainingInputs2(iter)];
                model.measured(u, iter);
            end
            
            targets = rad2deg(model.getPerformance());
            
            targetOutputs = targets(:,1);
            targetOutputs2 = targets(:,2);
            
            type = FunctionList.wavelet;
            option = WaveletList.morlet;
            neurons = 3;
            
            feedbacks = 3;
            feedforwards = 2;
            pSignal = 0.05;
            
            nnaType = NetworkList.Wavenet;
            inputs = 1;
            outputs = 1;
            
            learningRates = [1e-15 1e-15 1e-15 1e-15 1e-15];
            
            wavenetiir = NetworkFactory.create(nnaType);
            wavenetiir.buildNeuronLayer(type, option, neurons, inputs, outputs);
            wavenetiir.buildFilterLayer(inputs, feedbacks, feedforwards, pSignal);
            wavenetiir.setLearningRates(learningRates);
            wavenetiir.initInternalMemory();
            wavenetiir.initPerformance(samples);
            
            wavenetiir2 = NetworkFactory.create(nnaType);
            wavenetiir2.buildNeuronLayer(type, option, neurons, inputs, outputs);
            wavenetiir2.buildFilterLayer(inputs, feedbacks, feedforwards, pSignal);
            wavenetiir2.setLearningRates(learningRates);
            wavenetiir2.initInternalMemory();
            wavenetiir2.initPerformance(samples);
            
            WNET = NetworkFactory.create(nnaType);
            WNET.buildNeuronLayer(type, option, 2*neurons, 2, 2);
            WNET.buildFilterLayer(2, 2*feedbacks, 2*feedforwards, pSignal);
            WNET.setLearningRates(learningRates);
            WNET.initInternalMemory();
            WNET.initPerformance(samples);
            
            eIdent = zeros(samples,2);            
            wIdent = zeros(samples,2);
            
            for iter = 1:samples
                kT = iter * period;
                
                wavenetiir.evaluate(kT, trainingInputs(iter))
                wavenetiir.setPerformance(iter)
                
                wavenetiir2.evaluate(kT, trainingInputs2(iter))
                wavenetiir2.setPerformance(iter)
                
                WNET.evaluate(kT, [trainingInputs(iter), trainingInputs2(iter)])
                WNET.setPerformance(iter)
                
                eIdentification = wavenetiir.getOutputs() - targetOutputs(iter);
                eIdentification2 = wavenetiir2.getOutputs() - targetOutputs2(iter);
                
                eIdent_ = WNET.getOutputs()*100 - [targetOutputs(iter) targetOutputs2(iter)];
                
                eIdent(iter,:) = [eIdentification eIdentification2];
                
                wIdent(iter,:) = eIdent_;
                
                wavenetiir.update(trainingInputs(iter), eIdentification)
                wavenetiir2.update(trainingInputs2(iter), eIdentification2)
                
                WNET.update([trainingInputs(iter), trainingInputs2(iter)], eIdent_)
                
                temp = wavenetiir.getOutputs();
                
                if isnan(temp(1)) || isnan(temp(2))
                    break
                end
                
                clc
                fprintf(' TIME == %10.3f seconds ==\n', kT);
            end
            
            disp('Double wavenet')
            self.setMetrics(eIdent(:,1), period)
            self.setMetrics(eIdent(:,2), period)
            disp('Single wavenet')
            self.setMetrics(wIdent(:,1), period)
            self.setMetrics(wIdent(:,2), period)

            figure('Name','Simulation results double wavenet','NumberTitle','off','units','normalized','outerposition',[0 0 1 1]);
            
            estimated = rad2deg(wavenetiir.filterLayer.perfOutputs);
            estimated2 = rad2deg(wavenetiir2.filterLayer.perfOutputs);
            
            subplot(3, 2, 1)
                plot(trainingInputs,'k--','LineWidth',1)
                ylabel('u_{\theta}')
                xlabel('Samples, k')
                xlim([1 samples])
                
            subplot(3, 2, 3)
                plot(targetOutputs,'r','LineWidth',1)
                ylabel('y_{\theta}')
                xlabel('Samples, k')
                xlim([1 samples])
                
            subplot(3, 2, 5)
                plot(estimated,'r','LineWidth',1)
                ylabel('y_{\theta_{estimated}}')
                xlabel('Samples, k')
                xlim([1 samples])
                
            subplot(3, 2, 2)
                plot(trainingInputs2,'k--','LineWidth',1)
                ylabel('u_{\phi}')
                xlabel('Samples, k')
                xlim([1 samples])
                
            subplot(3, 2, 4)
                plot(targetOutputs2,'r','LineWidth',1)
                ylabel('y_{\phi}')
                xlabel('Samples, k')
                xlim([1 samples])
                
            subplot(3, 2, 6)
                plot(estimated2,'r','LineWidth',1)
                ylabel('y_{\phi_{estimated}}')
                xlabel('Samples, k')
                xlim([1 samples])
                
            figure('Name','Simulation results single wavenet','NumberTitle','off','units','normalized','outerposition',[0 0 1 1]);
            
            estimated = rad2deg(WNET.filterLayer.perfOutputs);
            
            subplot(3, 2, 1)
                plot(trainingInputs,'k--','LineWidth',1)
                ylabel('u_{\theta}')
                xlabel('Samples, k')
                xlim([1 samples])
                
            subplot(3, 2, 3)
                plot(targetOutputs,'r','LineWidth',1)
                ylabel('y_{\theta}')
                xlabel('Samples, k')
                xlim([1 samples])
                
            subplot(3, 2, 5)
                plot(estimated(:,1),'r','LineWidth',1)
                ylabel('y_{\theta_{estimated}}')
                xlabel('Samples, k')
                xlim([1 samples])
                
            subplot(3, 2, 2)
                plot(trainingInputs2,'k--','LineWidth',1)
                ylabel('u_{\phi}')
                xlabel('Samples, k')
                xlim([1 samples])
                
            subplot(3, 2, 4)
                plot(targetOutputs2,'r','LineWidth',1)
                ylabel('y_{\phi}')
                xlabel('Samples, k')
                xlim([1 samples])
                
            subplot(3, 2, 6)
                plot(estimated(:,2),'r','LineWidth',1)
                ylabel('y_{\phi_{estimated}}')
                xlabel('Samples, k')
                xlim([1 samples])
        end
    end
    
    methods (Access = protected)
        function setMetrics(~, identifError, T)
            metrics = [IMetrics.ISE(identifError,T), IMetrics.IAE(identifError,T), IMetrics.IATE(identifError,T)];
            fprintf('ISE = %015.5f\tIAE = %015.5f\tIATE = %015.5f\n', metrics(1), metrics(2), metrics(3))
        end
        
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