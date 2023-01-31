classdef AbstractFunction < handle
    properties (Access = protected)
        neurons {mustBeInteger}
        scales, shifts, tau, funcOutput, dfuncOutput, learningRates {mustBeNumeric}
        perfScales, perfShifts, perfTau, perfFuncOutput, perfdfunOutput {mustBeNumeric}
    end
    
    methods (Abstract)
        evaluateFunction();
    end
    
    methods (Access = public)
        function evaluate(self, instant)
            self.calculateTau(instant);
            self.normalizedTau(-1,1);
            self.evaluateFunction();
        end
        
        function generate(self)
            randd = @(a,b,f,c) a + (b-a)*rand(f,c);
            
            self.setScales(randd(1,1,1,self.neurons))
            self.setShifts(randd(-1,1,1,self.neurons))
        end
        
        function initialize(self, scales, shifts)
            self.setScales(scales);
            self.setShifts(shifts);
        end
        
        function update(self, scales, shifts)
            self.scales = self.scales - self.learningRates(1).*scales;
            self.shifts = self.shifts - self.learningRates(2).*shifts;
        end
        
        function charts(self)
            self.plotParameters();
            self.plotFunctionVals();
        end
    end
    
    methods (Access = public)
        function initPerformance(self, samples)
            self.perfScales = zeros(samples, self.neurons);
            self.perfShifts = self.perfScales;
            self.perfTau = self.perfScales;
            self.perfFuncOutput = self.perfScales;
            self.perfdfunOutput = self.perfScales;
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
        
        function rates = getLearningRates(self)
            rates = self.learningRates;
        end
        
        function setLearningRates(self, rates)
            self.learningRates = rates;
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
        
        function calculateTau(self, instant)
            self.tau = (instant - self.shifts) ./ self.scales;
        end
        
        function normalizedTau(self, inf, sup)
            data = self.tau;
            self.tau = inf + (data - min(data)).*(sup - inf)./(max(data) - min(data));
        end
    end
end