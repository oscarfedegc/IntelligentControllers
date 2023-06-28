classdef ActivationFunction < handle
    properties (Access = protected)
        neurons {mustBeInteger}
        scales, shifts, tau, funcOutput, dfuncOutput {mustBeNumeric}
        perfScales, perfShifts, perfTau, perfFuncOutput, perfdfunOutput {mustBeNumeric}
    end
    
    methods (Abstract)
        evaluateFunction();
    end
    
    methods (Access = public)
        function evaluate(self, instant)
            self.calculateTau(instant)
            self.normalizedTau(-1,1)
            self.evaluateFunction()
        end
        
        function initialize(self, scales, shifts)
            if nargin <= 2
                [scales, shifts] = self.getInitialValues();
            end
            
            self.setScales(scales);
            self.setShifts(shifts);
        end
        
        function update(self, scales, shifts)
            self.scales = scales;
            self.shifts = shifts;
        end
        
        function charts(self)
            self.compactParameterCharts();
            self.plotFunctionVals();
        end
    end
    
    methods (Access = public)
        function bootPerformance(self, samples)
            aux = zeros(samples, self.neurons);
            
            self.perfScales = aux;
            self.perfShifts = aux;
            self.perfTau = aux;
            self.perfFuncOutput = aux;
            self.perfdfunOutput = aux;
        end
        
        function setPerformance(self, iteration)
            self.perfScales(iteration,:) = self.scales;
            self.perfShifts(iteration,:) = self.shifts;
            self.perfTau(iteration,:) = self.tau;
            self.perfFuncOutput(iteration,:) = self.funcOutput;
            self.perfdfunOutput(iteration,:) = self.dfuncOutput;
        end
        
        function [scales, shifts, tau, funcOutput, dfuncOutput] = getPerformance(self)
            scales = self.perfScales;
            shifts = self.perfShifts;
            tau = self.perfTau;
            funcOutput = self.perfFuncOutput;
            dfuncOutput = self.perfdfunOutput;
        end
    end
    
    methods (Access = public)
        function setScales(self, scales)
            self.scales = scales;
        end
        
        function setShifts(self, shifts)
            self.shifts = shifts;
        end
        
        function tau = getTau(self)
            tau = self.tau;
        end
        
        function func = getFuncOutput(self)
            func = self.funcOutput;
        end
        
        function dfunc = getDerivative(self)
            dfunc = self.dfuncOutput;
        end
        
        function scales = getScales(self)
            scales = self.scales;
        end
        
        function shifts = getShifts(self)
            shifts = self.shifts;
        end
        
        function neurons = getNeurons(self)
            neurons = self.neurons;
        end
    end
    
    methods (Access = protected)
        function compactParameterCharts(self)
            cols = 3;
            rows = 1;
            tag = {'a', 'b', '\tau'};
            lbl = {'Scales', 'Shifts', 'Wavelet'};
            
            figure('Name','Scaling and shifting parameters','NumberTitle','off','units','normalized','outerposition',[0 0 1 1]);
            
            for col = 1:cols
                subplot(rows, cols, col)
                hold on
                
                switch col
                    case 1
                        data = self.perfScales;
                    case 2
                        data = self.perfShifts;
                    case 3
                        data = self.perfTau;
                end
                
                for neuron = 1:self.neurons
                    plot(data(:, neuron),'LineWidth',1,'DisplayName',...
                            sprintf('%s_{%i}', string(tag(col)), neuron))
                end
                ylabel(sprintf('%s [scalar]', string(lbl(col))))
                xlabel('Samples, k')
                legend(gca,'show')
            end
        end
        
        function plotParameters(self)
            cols = 3;
            rows = self.neurons;
            
            figure('Name','Scaling and shifting parameters','NumberTitle','off','units','normalized','outerposition',[0 0 1 1]);
            for row = 1:rows
                subplot(rows, cols, 1 + cols*(row-1))
                    plot(self.perfScales(:,row),'r','LineWidth',1)
                    ylabel(sprintf('a_{%i}', row))
                    
                if row == rows; xlabel('Samples, k'); end
                
                subplot(rows, cols, 2 + cols*(row-1))
                    plot(self.perfShifts(:,row),'r','LineWidth',1)
                    ylabel(sprintf('b_{%i}', row))
                    
                if row == rows; xlabel('Samples, k'); end
               
                subplot(rows, cols, 3 + cols*(row-1))
                    plot(self.perfTau(:,row),'r','LineWidth',1)
                    ylabel(sprintf('\\tau_{%i}', row))
            end
            xlabel('Samples, k')
        end
        
        function plotFunctionVals(self)
            cols = 2;
            rows = self.neurons;
            
            figure('Name','Neuron outputs and its derivatives','NumberTitle','off','units','normalized','outerposition',[0 0 1 1]);
            for row = 1:rows
                subplot(rows, cols, 1 + cols*(row-1))
                    plot(self.perfFuncOutput(:,row),'r','LineWidth',1)
                    ylabel(sprintf('\\psi(\\tau_{%i})', row))
                    
                if row == rows; xlabel('Samples, k'); end
                
                subplot(rows, cols, 2 + cols*(row-1))
                    plot(self.perfdfunOutput(:,row),'r','LineWidth',1)
                    ylabel(sprintf('\\partial\\psi(\\tau_{%i})', row))
            end
            xlabel('Samples, k');
        end
        
        function [scales, shifts] = getInitialValues(self)
            data = 1;
            scales = data .* ones(1,self.neurons);
            shifts = data:data:data*self.neurons;
        end
        
        function calculateTau(self, instant)
            self.tau = (instant - self.shifts) ./ self.scales;
        end
        
        function normalizedTau(self, inf, sup)
            data = self.tau;
            self.tau = inf + (data - min(data)).*(sup - inf)./(max(data) - min(data));
        end
    end
end