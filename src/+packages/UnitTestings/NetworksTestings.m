classdef NetworksTestings < handle
    methods (Access = public)
        function self = NetworksTestings()
        end
        
        function run(self)
            tFinal = 90;
            period = 0.005;
            samples = round(tFinal/period);
            
            x = 0 : period : tFinal-period;
            trainingInputs = exp(-x./50) .* 5 .* sin(0.2.*x);
            trainingInputs2 = -sin(0.005.*x.^2) - 1.2*cos(0.01.*x) - sin(0.005.*x.^2);
            
            targetOutputs = 10 .* trainingInputs;
            targetOutputs2 = 10 .* trainingInputs2;
            
            targets = [targetOutputs', targetOutputs2'];
            
            nnaType = NetworkList.Wavenet;
            type = FunctionList.wavelet;
            option = WaveletList.morlet;
            inputs = 2;
            outputs = 2;
            neurons = 5;
            
            learningRates = [0.005 0.01 0.01];
            
            WNET = NetworkFactory.create(nnaType);
            WNET.setSynapticRange(1)
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

                estimated = WNET.getBehaviorApproximation();

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
            
            x = 0 : period : tFinal-period;
            trainingInputs = exp(-x./50) .* 5 .* sin(0.2.*x);
            trainingInputs2 = -sin(0.005.*x.^2) - 1.2*cos(0.1.*x) - sin(0.05.*x.^2);
            
            plantType = PlantList.helicopter2DOF;
            initialStates = [0 0 0 0];
            model = PlantFactory.create(plantType);
            model.setPeriod(period);
            model.setInitialStates(samples, deg2rad(initialStates))
            
            for iter = 1:samples
                u = [trainingInputs(iter), trainingInputs2(iter)];
                model.measured(u, iter);
            end
            
            targets = rad2deg(model.getPerformance());
            
            nnaType = NetworkList.Wavenet;
            type = FunctionList.wavelet;
            option = WaveletList.morlet;
            inputs = 2;
            outputs = 2;
            neurons = 6;
            
            learningRates = [1e-8 1e-8 1e-5];
            
            WNET = NetworkFactory.create(nnaType);
            WNET.setSynapticRange(1)
            WNET.buildNeuronLayer(type, option, neurons, inputs, outputs)
            WNET.setLearningRates(learningRates)
            WNET.bootPerformance(samples)
            
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

                estimated = WNET.getBehaviorApproximation();

                subplot(3, 2, 1)
                    plot(trainingInputs,'k--','LineWidth',1)
                    ylabel('u_{\theta}')
                    xlabel('Samples, k')
                    xlim([1 samples])

                subplot(3, 2, 3)
                    hold on
                    plot(targets(:,1),'LineWidth',1)
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
                    plot(targets(:,2),'LineWidth',1)
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