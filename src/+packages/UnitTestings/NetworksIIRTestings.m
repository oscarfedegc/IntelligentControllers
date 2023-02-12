classdef NetworksIIRTestings < handle
    methods (Access = public)
        function self = NetworksIIRTestings()
            return
        end
        
        function run(self)
            tFinal = 120;
            period = 0.005;
            samples = round(tFinal/period);
            
            x = 0 : period : tFinal-period;
            trainingInputs = exp(-x./50) .* sin(0.02.*x);
            trainingInputs2 = -sin(0.005.*x.^2) - 1.2*cos(0.1.*x);
            
            targetOutputs = trainingInputs;
            targetOutputs2 = -10.*trainingInputs2;
            
            targets = [targetOutputs', targetOutputs2'];
            
            nnaType = NetworkList.WavenetIIR;
            type = FunctionList.wavelet;
            option = WaveletList.morlet;
            inputs = 2;
            outputs = 2;
            neurons = 6;
            
            coeffsN = 4;
            coeffsM = 2;
            persistentSignal = 1e-5;
            
            learningRates = [0.0005 0.001 0.0005 0.00001 0.00001];
            
            WNET = NetworkFactory.create(nnaType);
            WNET.buildNeuronLayer(type, option, neurons, inputs, outputs)
            WNET.buildFilterLayer(inputs, coeffsN, coeffsM, persistentSignal)
            WNET.initInternalMemory()
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
                
                eIdent_ = estimated - [targetOutputs(iter) targetOutputs2(iter)];
                
                wIdent(iter,:) = [eIdent_, WNET.getCostFunction(eIdent_)];
                
                WNET.update([trainingInputs(iter), trainingInputs2(iter)], eIdent_)
                
                clc
                fprintf(' TIME == %10.3f seconds ==\n', kT);
                fprintf(' %+10.3f\t%+10.3f\t%+10.3f\t%+10.3f\t%+10.3f\t%+10.3f\n', ...
                    targetOutputs(iter), estimated(1), targetOutputs2(iter), estimated(2),...
                    eIdent_(1), eIdent_(2));
            end
            
            if isOK
                close all
                disp('Single wavenet')
                self.setMetrics(wIdent(:,1), period)
                self.setMetrics(wIdent(:,2), period)

                WNET.charts('compact');
                figure('Name','Simulation results single wavenet','NumberTitle','off','units','normalized','outerposition',[0 0 1 1]);

                estimated = WNET.getBehavior();
                error = targets - estimated;

                subplot(3, 2, 1)
                    plot(x,trainingInputs,'k--','LineWidth',1)
                    ylabel('u_{\theta}')
                    xlabel('Samples, k')
                    xlim([1 max(x)])

                subplot(3, 2, 3)
                    hold on
                    plot(x,targetOutputs,'LineWidth',1)
                    plot(x,estimated(:,1),'LineWidth',1)
                    legend('Target output','NNA Output');
                    xlabel('Samples, k')
                    xlim([1 max(x)])

                subplot(3, 2, 5)
                    hold on
                    plot(x,error(:,1),'r','LineWidth',1)
                    plot(x,error(:,2),'b:','LineWidth',1)
                    legend('e_1','e_2');
                    ylabel('Identification error')
                    xlabel('Samples, k')
                    xlim([1 max(x)])

                subplot(3, 2, 2)
                    plot(x,trainingInputs2,'k--','LineWidth',1)
                    ylabel('u_{\phi}')
                    xlabel('Samples, k')
                    xlim([1 max(x)])

                subplot(3, 2, 4)
                    hold on
                    plot(x,targetOutputs2,'LineWidth',1)
                    plot(x,estimated(:,2),'LineWidth',1)
                    legend('Target output','NNA Output');
                    xlabel('Samples, k')
                    xlim([1 max(x)])

                subplot(3, 2, 6)
                    plot(x,wIdent(:,3),'r','LineWidth',1)
                    ylabel('Cost function')
                    xlabel('Samples, k')
                    xlim([1 max(x)])
            end
        end
        
        function runModel(self)
            tFinal = 120;
            period = 0.005;
            samples = round(tFinal/period);
            
            x = 0 : period : tFinal-period;
            trainingInputs = sin(0.005.*x.^2) + 1.2*sin(0.01.*x);
            trainingInputs2 = -sin(0.005.*x.^2) - 1.2*cos(0.1.*x);
            
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
            
            targets = [targetOutputs targetOutputs2];
            
            nnaType = NetworkList.WavenetIIR;
            type = FunctionList.wavelet;
            option = WaveletList.morlet;
            inputs = 2;
            outputs = 2;
            neurons = 20;
            
            coeffsN = 4;
            coeffsM = 2;
            persistentSignal = 1e-5;
            
            learningRates = [0.000001 0.000001 0.0001 0.00000001 0.000000001];
            
            WNET = NetworkFactory.create(nnaType);
            WNET.buildNeuronLayer(type, option, neurons, inputs, outputs)
            WNET.buildFilterLayer(inputs, coeffsN, coeffsM, persistentSignal)
            WNET.initInternalMemory()
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
                
                eIdent_ = estimated - [targetOutputs(iter) targetOutputs2(iter)];
                
                wIdent(iter,:) = [eIdent_, WNET.getCostFunction(eIdent_)];
                
                WNET.update([trainingInputs(iter), trainingInputs2(iter)], eIdent_)
                
                clc
                fprintf(' TIME == %10.3f seconds ==\n', kT);
                fprintf(' %+10.3f\t%+10.3f\t%+10.3f\t%+10.3f\t%+10.3f\t%+10.3f\n', ...
                    targetOutputs(iter), estimated(1), targetOutputs2(iter), estimated(2),...
                    eIdent_(1), eIdent_(2));
            end
            
            if isOK
                close all
                disp('Single wavenet')
                self.setMetrics(wIdent(:,1), period)
                self.setMetrics(wIdent(:,2), period)

                WNET.charts('compact');
                figure('Name','Simulation results single wavenet','NumberTitle','off','units','normalized','outerposition',[0 0 1 1]);

                estimated = WNET.getBehavior();
                error = targets - estimated;

                subplot(3, 2, 1)
                    plot(trainingInputs,'k--','LineWidth',1)
                    ylabel('u_{\theta}')
                    xlabel('Samples, k')
                    xlim([1 samples])

                subplot(3, 2, 3)
                    hold on
                    yyaxis left
                    plot(targetOutputs,'LineWidth',1)
                    yyaxis right
                    plot(estimated(:,1),'LineWidth',1)
                    legend('Target output','NNA Output');
                    xlabel('Samples, k')
                    xlim([1 samples])

                subplot(3, 2, 5)
                    hold on
                    plot(error(:,1),'r','LineWidth',1)
                    plot(error(:,2),'b:','LineWidth',1)
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
                    yyaxis left
                    plot(targetOutputs2,'LineWidth',1)
                    yyaxis right
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