classdef IWavenetIIRScheme < WavenetIIRScheme
    methods (Access = public)
        function self = IWavenetIIRScheme()
            self.optimizer = IOptimizer();
        end
        
        function setLearningRates(self, rates)
            self.allLearningRates = rates;
        end
        
        function evaluate(self, ~, inputs) % ~instant
            % Wavenet outputs
            self.setInputs(inputs);
            self.hiddenNeuronLayer.evaluate(inputs);
            outputFunction = self.hiddenNeuronLayer.getFuncOutput();
            tempWnet = self.calculateNetworkOutput(inputs, outputFunction, self.synapticWeights);
            
            % IIR Filter outputs
            self.filterLayer.evaluate(tempWnet, inputs);
            tempIIR = self.filterLayer.getOutputs();
            
            % Setting final calculate
            self.setWnetIIROutputs(tempWnet, tempIIR);
            self.updateInternalMemory();
        end
        
        function updateGradientDescent(self, inputs, identificationErrors)
            [gradientW, gradienta, gradientb, gradientC, gradientD] = ...
                self.calculateGradients(inputs, identificationErrors);
            
            scales = self.hiddenNeuronLayer.getScales();
            shifts = self.hiddenNeuronLayer.getShifts();
            weights = self.synapticWeights;
            feedbacks = self.filterLayer.getFeedbacks();
            forwards = self.filterLayer.getFeedforwards();
            learningRate = self.allLearningRates;
            
            [scales,shifts,weights,feedbacks,forwards] = IOptimizer.GradientDescent( ...
                scales,shifts,weights,feedbacks,forwards,...
                gradienta, gradientb, gradientW, gradientC, gradientD, learningRate);
            
            self.synapticWeights = weights;
            self.hiddenNeuronLayer.update(scales, shifts);
            self.filterLayer.update(feedbacks, forwards);
        end
        
        function perfOutputs = getBehaviorApproximation(self)
            perfOutputs = self.filterLayer.getPerfOutputs();
        end
        
        function charts(self, mode)
            if strcmp(mode,'compact')
                self.hiddenNeuronLayer.charts()
                self.filterLayer.charts()
                self.synapticWeightsCompactCharts()
            else
                self.hiddenNeuronLayer.charts()
                self.filterLayer.charts()
                self.synapticWeightsCharts()
            end
        end
        
        function buildFilterLayer(self, inputs, outputs, coeffsN, coeffsM, pSignal)
            self.filterLayer = IFilter(inputs, outputs, coeffsN, coeffsM, pSignal);
        end
        
        function setFilterInitialValues(self, feedbacks, feedforwards, pSignal)
            self.filterLayer.initialize(feedbacks, feedforwards, pSignal);
        end
        
        function setSynapticRange(self, range)
            self.synapticRange = range;
        end
        
        function bootInternalMemory(self)
            self.functionMemory = zeros(self.filterLayer.getCoeffsM(), self.hiddenNeuronLayer.getNeurons());
            self.derivativeMemory = self.functionMemory;
        end
        
        function updateInternalMemory(self)
            self.functionMemory = self.updateMatrix(self.functionMemory, self.hiddenNeuronLayer.getFuncOutput());
            self.derivativeMemory = self.updateMatrix(self.functionMemory, self.hiddenNeuronLayer.getDerivative());
        end
        
        function [RhoIIR, GammaIIR] = getApproximation(self)
            RhoIIR = self.filterLayer.getRho();
            GammaIIR = self.filterLayer.getGamma();
        end
    end
    
    methods (Access = public)
        function [GradientW, Gradienta, Gradientb, GradientC, GradientD] = ...
                getGradients(self, controlSignals, error)
            
            Ie = diag(error,0);
            If = error;
            tau = self.hiddenNeuronLayer.getTau();
            C = self.filterLayer.getFeedbacks();
            D = self.filterLayer.getFeedforwards();
            A = self.functionMemory + 1;
            B = self.derivativeMemory + 1;
            Z = self.filterLayer.iMemory + 1;
            Y = self.filterLayer.oMemory + 1;
            p = self.filterLayer.getPersistentSignal();
            
            GradientW = sum(controlSignals) * sum(error) * C' * A;
            Gradientb = sum(controlSignals) * If * (C' * B);
            Gradienta = Gradientb .* tau;
            GradientC = sum(controlSignals) * Ie * Z;
            GradientD = p .* Ie * Y;
        end
        
        function [tau, waveOutput, wnetOutput] = getTau(self, inputs, instant)
            % Wavenet outputs
            self.setInputs(inputs);
            self.hiddenNeuronLayer.evaluate(instant);
            
            tau = self.hiddenNeuronLayer.getTau();
            waveOutput = self.hiddenNeuronLayer.getFuncOutput();
            wnetOutput = [0 0];
        end
    end
    
    methods (Access = protected)
        function outputs = calculateNetworkOutput(~, inputs, functions, synaptics)
            outputs = sum(inputs) * functions * synaptics';
        end
        
        function rst = calculateCostFunction(~,error)
            rst = 0.5 * sum(error .^ 2);
        end
        
        function [GradientW, Gradienta, Gradientb, GradientC, GradientD] = ...
                calculateGradients(self, controlSignals, error)
            
            Ie = diag(error,0);
            If = error;
            tau = self.hiddenNeuronLayer.getTau();
            C = self.filterLayer.getFeedbacks();
            A = self.functionMemory;
            B = self.derivativeMemory;
            Z = self.filterLayer.iMemory;
            Y = self.filterLayer.oMemory;
            p = self.filterLayer.persistentSignal;
            
            GradientW = sum(controlSignals) * sum(error) * C * A;
            Gradientb = sum(controlSignals) * If *(C * B);
            Gradienta = Gradientb .* tau;
            GradientC = sum(controlSignals) * Ie * Z;
            GradientD = p .* Ie * Y;
        end
        
        function output = updateMatrix(~, matrix, newValues)
            [a,~] = size(matrix);
            output = [newValues; matrix(1:a-1,:)];
        end
        
        function synapticWeightsCharts(self)
            cols = self.outputs;
            rows = self.hiddenNeuronLayer.getNeurons();
            weigths = self.perfSynapticWeights;
            
            figure('Name','Synaptic weigths','NumberTitle','off','units','normalized','outerposition',[0 0 1 1]);
            
            for col = 1:cols
                for row = 1:rows
                    subplot(rows, cols, col + cols*(row-1))
                end
            end
            
            for col = 1:cols
                for row = 1:rows
                    subplot(rows, cols, col + cols*(row-1))
                        plot(weigths(:, row + (col-1)),'r','LineWidth',1)
                        ylabel(sprintf('w_{%i,%i}', col, row))

                    if row == rows; xlabel('Samples, k'); end
                end
            end
            xlabel('Samples, k')
        end
        
        function synapticWeightsCompactCharts(self)
            cols = self.outputs;
            rows = 1;
            neurons = self.hiddenNeuronLayer.getNeurons();
            weigths = self.perfSynapticWeights;
            
            tag = {'theta'; 'phi'};
            
            figure('Name','Synaptic weigths','NumberTitle','off','units','normalized','outerposition',[0 0 1 1]);
            
            for col = 1:cols
                subplot(rows, cols, col)
                hold on
                for neuron = 1:neurons
                    plot(weigths(:, neuron + (col-1)),'LineWidth',1,'DisplayName',...
                        sprintf('w_{\\%s_{%i}}', string(tag(col)), neuron))
                end
                legend(gca,'show')
                ylabel(sprintf('W_{\\%s} [scalar]', string(tag(col))))
                xlabel('Samples, k')
            end
        end
    end
end