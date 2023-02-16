classdef IWavenetIIRScheme < WavenetScheme
    properties (Access = public)
        functionMemory, derivativeMemory {mustBeNumeric}
        filterLayer % {must be ImplementFilters}
    end
    
    methods (Access = public)
        function self = IWavenetIIRScheme()
            return
        end
        
        function setLearningRates(self, rates)
            self.sWeightLearningRate = rates(3);
            self.hiddenNeuronLayer.setLearningRates(rates(1:2))
            self.filterLayer.setLearningRates(rates(4:5))
        end
        
        function evaluate(self, instant, inputs)
            % Wavenet outputs
            self.setInputs(inputs);
            self.hiddenNeuronLayer.evaluate(instant);
            outputFunction = self.hiddenNeuronLayer.getFuncOutput();
            temp = self.calculateNetworkOutput(inputs, outputFunction, self.synapticWeights);
            
            % IIR Filter outputs
            self.filterLayer.evaluate(temp);
            temp = self.filterLayer.getOutputs();
            
            % Setting final calculate
            self.setNetworkOutputs(temp);
            self.updateInternalMemory();
        end
        
        function update(self, inputs, identificationErrors)
            [DeltaW, Deltaa, Deltab, DeltaC, DeltaD] = self.calculateGradients(inputs, identificationErrors);
            
            self.synapticWeights = self.synapticWeights - self.sWeightLearningRate .* DeltaW;
            self.hiddenNeuronLayer.update(Deltaa, Deltab);
            self.filterLayer.update(DeltaC, DeltaD);
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
        
        function buildFilterLayer(self, inputs, coeffsN, coeffsM, pSignal)
            self.filterLayer = IFilter(inputs, coeffsN, coeffsM, pSignal);
        end
        
        function setFilterInitialValues(self, feedbacks, feedforwards, pSignal)
            self.filterLayer.initialize(feedbacks, feedforwards, pSignal);
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
    
    methods (Access = protected)
        function outputs = calculateNetworkOutput(~, inputs, functions, synaptics)
            outputs = sum(inputs) * functions * synaptics';
        end
        
        function rst = calculateCostFunction(~,error)
            rst = 0.5 * sum(error .^ 2);
        end
        
        function [DeltaW, Deltaa, Deltab, DeltaC, DeltaD] = calculateGradients(self, controlSignals, error)
            U = sum(controlSignals);
            Ie = diag(error,0);
            If = error;
            tau = self.hiddenNeuronLayer.getTau();
            C = self.filterLayer.getFeedbacks();
            A = self.functionMemory;
            B = self.derivativeMemory;
            Z = self.filterLayer.iMemory;
            Y = self.filterLayer.oMemory;
            p = self.filterLayer.persistentSignal;
            
            DeltaW = U .* Ie * C * A;
            Deltab = U * If *(C * B);
            Deltaa = Deltab .* tau;
            DeltaC = U * Ie * Z;
            DeltaD = p .* Ie * Y;
        end
        
        function output = updateMatrix(~, matrix, newValues)
            [a,~] = size(matrix);
            output = [newValues; matrix(1:a-1,:)];
        end
        
        function bootBehavior(self, samples)
            self.filterLayer.bootPerformance(samples)
        end
        
        function setBehavior(self, iteration)
            self.filterLayer.setPerformance(iteration)
        end
        
        function synapticWeightsCharts(self)
            cols = self.outputs;
            rows = self.hiddenNeuronLayer.getNeurons();
            weigths = self.perfSynapticWeights;
            
            tag = {'theta'; 'phi'};
            
            figure('Name','Synaptic weigths','NumberTitle','off','units','normalized','outerposition',[0 0 1 1]);
            
            for col = 1:cols
                for row = 1:rows
                    subplot(rows, cols, 1 + cols*(row-1))
                end
            end
            
            for row = 1:rows
                subplot(rows, cols, 1 + cols*(row-1))
                    plot(weigths(:, row + (col-1)),'r','LineWidth',1)
                    ylabel(sprintf('w_{\\%s_%i}', string(tag(col)), row))
                    
                if row == rows; xlabel('Samples, k'); end
                
                subplot(rows, cols, 2 + cols*(row-1))
                    plot(weigths(:,row),'r','LineWidth',1)
                    ylabel(sprintf('w_{\\%s_%i}', string(tag(2)), row))
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