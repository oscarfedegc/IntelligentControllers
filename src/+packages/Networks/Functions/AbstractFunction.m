classdef AbstractFunction < handle
    properties (Access = public)
        neurons {mustBeInteger}
        scales, shifts, tau, funcOutput, dfuncOutput, learningRates {mustBeNumeric}
    end
    
    methods (Abstract = true)
        evaluateFunction();
    end
    
    methods (Access = public)
        function evaluate(self, instant)
            self.calculateTau(instant);
            self.normalizedTau(-1,1);
            self.evaluateFunction();
        end
        
        function generate(self)
            self.scales = rand(1, self.neurons);
            self.shifts = rand(1, self.neurons);
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
            self.plotScalesShiftsTau();
            self.plotFunctionVals();
        end
    end
    
    methods (Access = public)
        function setScales(self, scales)
            self.scales = scales;
        end
        
        function setShifts(self, shifts)
            self.shifts = shifts;
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
    end
    
    methods (Access = protected)
        function plotScalesShiftsTau(self)
            cols = 3;
            rows = self.neurons;
            
            figure('Name','Parámetros de escalamiento y traslación','NumberTitle','off','units','normalized','outerposition',[0 0 1 1]);
            for row = 1:rows
                subplot(rows, cols, 1 + cols*(row-1))
                    plot(self.perfScales(:,row),'r','LineWidth',1)
                    ylabel(sprintf('a_{%i}', row))
                    
                if row == rows; xlabel('Muestras, k'); end
                
                subplot(rows, cols, 2 + cols*(row-1))
                    plot(self.perfShifts(:,row),'r','LineWidth',1)
                    ylabel(sprintf('b_{%i}', row))
                    
                if row == rows; xlabel('Muestras, k'); end
               
                subplot(rows, cols, 3 + cols*(row-1))
                    plot(self.perfTau(:,row),'r','LineWidth',1)
                    ylabel(sprintf('\\tau_{%i}', row))
            end
            xlabel('Muestras, k')
        end
        
        function plotFunctionVals(self)
            cols = 2;
            rows = self.neurons;
            
            figure('Name','Salidas de las neuronas y sus derivadas','NumberTitle','off','units','normalized','outerposition',[0 0 1 1]);
            for row = 1:rows
                subplot(rows, cols, 1 + cols*(row-1))
                    plot(self.perfFunc(:,row),'r','LineWidth',1)
                    ylabel(sprintf('\\psi(\\tau_{%i})', row))
                    
                if row == rows; xlabel('Muestras, k'); end
                
                subplot(rows, cols, 2 + cols*(row-1))
                    plot(self.perfdFunc(:,row),'r','LineWidth',1)
                    ylabel(sprintf('\\partial\\psi(\\tau_{%i})', row))
            end
            xlabel('Muestras, k');
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