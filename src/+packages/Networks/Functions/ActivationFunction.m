% This abstract class represents the activation function and its operations: 
%   calculate the function output, update parameters, boot initial values
%   for the parameters, and plotting its behavior.
classdef ActivationFunction < handle
    properties (Access = protected)
        neurons {mustBeInteger}
        scales, shifts, tau, funcOutput, dfuncOutput {mustBeNumeric}
        perfScales, perfShifts, perfTau, perfFuncOutput, perfdfunOutput {mustBeNumeric}
    end
    
    % Theses functions must be implemented in all inherited classes.
    methods (Abstract)
        evaluateFunction();
    end
    
    methods (Access = public)
        % Calculates the output of activation function.
        %
        %   @param {float} instant Indicates the time of operation.
        %
        function evaluate(self, instant)
            self.calculateTau(instant)
            self.normalizedTau(-1,1)
            self.evaluateFunction()
        end
        
        % Initializes the scales and shifts values. 
        % If there are not input arguments, the value are generate.
        %
        %   @param {float} scales Initial values of the scales.
        %   @param {float} shifts Initial values of the shifts.
        %
        function initialize(self, scales, shifts)
            if nargin <= 2
                [scales, shifts] = self.getInitialValues();
            end
            
            self.setScales(scales);
            self.setShifts(shifts);
        end
        
        % Updates the scales and shifts values.
        %
        %   @param {float} scales New values of the scales.
        %   @param {float} shifts New values of the shifts.
        %
        function update(self, scales, shifts)
            self.scales = scales;
            self.shifts = shifts;
        end
        
        % Calls the method to generate the chart from behavior parameters.
        %
        function charts(self)
            self.compactParameterCharts();
            self.plotFunctionVals();
        end
    end
    
    methods (Access = public)
        % Initializes the performances matrices to save the parameter behavior.
        %
        %   @param {integer} samples Indicates the amounf of operations.
        %
        function bootPerformance(self, samples)
            aux = zeros(samples, self.neurons);
            
            self.perfScales = aux;
            self.perfShifts = aux;
            self.perfTau = aux;
            self.perfFuncOutput = aux;
            self.perfdfunOutput = aux;
        end
        
        % Stores the current parameter values of the activation functions.
        %
        %   @param {integer} iteration Indicates the current operation.
        %
        function setPerformance(self, iteration)
            self.perfScales(iteration,:) = self.scales;
            self.perfShifts(iteration,:) = self.shifts;
            self.perfTau(iteration,:) = self.tau;
            self.perfFuncOutput(iteration,:) = self.funcOutput;
            self.perfdfunOutput(iteration,:) = self.dfuncOutput;
        end
        
        % Returns the performance of all parameters from the activation functions
        % during the whole time simulation.
        %
        %   @returns {float} scales Matrix of scaling values.
        %   @returns {float} shifts Matrix of shifting values.
        %   @returns {float} scales Matrix of tau values.
        %   @returns {float} scales Matrix of output function values.
        %   @returns {float} scales Matrix of derivative function values.
        %
        function [scales, shifts, tau, funcOutput, dfuncOutput] = getPerformance(self)
            scales = self.perfScales;
            shifts = self.perfShifts;
            tau = self.perfTau;
            funcOutput = self.perfFuncOutput;
            dfuncOutput = self.perfdfunOutput;
        end
    end
    
    % These funcions are the getters and setters for each parameter class.
    methods (Access = public)
        % Assigns the values of scale parameters.
        %
        %   @param {float} scales Indicates the scaling values.
        %
        function setScales(self, scales)
            self.scales = scales;
        end
        
        % Assigns the values of shift parameters.
        %
        %   @param {float} shifts Indicates the shifting values.
        %
        function setShifts(self, shifts)
            self.shifts = shifts;
        end
        
        % Gets the values of tau parameters.
        %
        %   @returns {float} tau Vector of the tau parameter values.
        %
        function tau = getTau(self)
            tau = self.tau;
        end
        
        % Gets the values of output of activation functions.
        %
        %   @returns {float} func Vector of the activation function values.
        %
        function func = getFuncOutput(self)
            func = self.funcOutput;
        end
        
        % Gets the value of the derivatives of activation functions.
        %
        %   @returns {float} dfunc Vector of the derivative function values.
        %
        function dfunc = getDerivative(self)
            dfunc = self.dfuncOutput;
        end
        
        % Gets the values of scale parameters.
        %
        %   @returns {float} scales Vector of the scale parameter values.
        %
        function scales = getScales(self)
            scales = self.scales;
        end
        
        % Gets the values of shifts parameters.
        %
        %   @returns {float} shifts Vector of the shifts parameter values.
        %        
        function shifts = getShifts(self)
            shifts = self.shifts;
        end
        
        % Gets the amount of the neuron into the hidden layer from the neural network.
        %
        %   @returns {integer} neurons Amount of neurons.
        %  
        function neurons = getNeurons(self)
            neurons = self.neurons;
        end
    end
    
    methods (Access = protected)
        % Plots the function parameters in one figure
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
        
        %{
            Gets the scales and shift values
        
            @returns
                scales {float} vector of values
                shifts {float} vector of values
        %}
        function [scales, shifts] = getInitialValues(self)
            data = 1;
            scales = data .* ones(1,self.neurons);
            shifts = data:data:data*self.neurons;
        end
        
        %{
            Calculates the tau vector for the activation function
        
            @args
                instant {float} instant of the operation in seconds
        %}
        function calculateTau(self, instant)
            instant = sum(instant.^2);
            self.tau = (instant - self.shifts) ./ self.scales;
        end
        
        %{
            Normalized the vector tau
        
            @args
                inf {float} inferior limit of the normalized vector
                sup {float} superior limit of the normalized vector
        %}
        function normalizedTau(self, inf, sup)
            data = self.tau;
            self.tau = inf + (data - min(data)).*(sup - inf)./(max(data) - min(data));
        end
    end
end