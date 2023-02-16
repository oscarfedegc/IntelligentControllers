classdef IWavenetScheme < WavenetScheme
    methods (Access = public)
        function self = IWavenetScheme()
            return
        end
        
        function setLearningRates(self, rates)
            self.sWeightLearningRate = rates(3);
            self.hiddenNeuronLayer.setLearningRates(rates(1:2))
        end
        
        function evaluate(self, instant, inputs)
            % Evaluation of activation functions
            self.setInputs(inputs);
            self.hiddenNeuronLayer.evaluate(instant);
            outputFunction = self.hiddenNeuronLayer.getFuncOutput();
            
            % Calculating the wavenet output
            temp = self.calculateNetworkOutput(inputs, outputFunction, self.synapticWeights);
            self.setNetworkOutputs(temp);
        end
        
        function update(self, inputs, identificationErrors)
            [DeltaW, Deltaa, Deltab] = self.calculateGradients(inputs, identificationErrors);
            
            self.synapticWeights = self.synapticWeights - self.sWeightLearningRate .* DeltaW;
            self.hiddenNeuronLayer.update(Deltaa, Deltab);
        end
        
        function perfOutputs = getBehaviorApproximation(self)
            perfOutputs = self.getBehaviorWavenet();
        end
        
        function charts(self, mode)
            if strcmp(mode,'compact')
                self.hiddenNeuronLayer.charts();
                self.synapticWeightsCompactCharts();
            else
                self.hiddenNeuronLayer.charts();
                self.synapticWeightsCharts();
            end
        end
    end
    
    methods (Access = protected)
        function outputs = calculateNetworkOutput(~, inputs, functions, synaptics)
            outputs = sum(inputs) * functions * synaptics';
        end
        
        function rst = calculateCostFunction(~,error)
            rst = 0.5 * sum(error .^ 2);
        end
        
        function [DeltaW, Deltaa, Deltab] = calculateGradients(self, controlSignals, error)
            U = sum(controlSignals);
            phi = self.hiddenNeuronLayer.getFuncOutput();
            dfunc = self.hiddenNeuronLayer.getDerivative();
            weights = self.synapticWeights;
            tau = self.hiddenNeuronLayer.getTau();
            
            DeltaW = U .* error' * phi;
            Deltab = (U * error * weights) .* dfunc;
            Deltaa = Deltab .* tau;
        end
        
        function bootBehavior(~,~)
        end
        
        function setBehavior(~,~)
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