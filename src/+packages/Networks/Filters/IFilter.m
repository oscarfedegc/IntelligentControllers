% This class implements the infinite impulse response (IIR) filter and its
% methods to calculate the outputs and update its coefficients.
classdef IFilter < handle
    properties (Access = public)
        feedbacks, feedforwards, oValues, persistentSignal {mustBeNumeric}
        iMemory, oMemory, Gamma, Rho {mustBeNumeric}
        coeffsM, coeffsN, inputs, outputs {mustBeInteger}
        perfFeedbacks, perfFeedforwards, perfGamma, perfRho, perfOutputs {mustBeNumeric}
    end
    
    methods (Access = public)
        % Class constructor.
        %
        %   @param {integer} inputs Number of entries.
        %   @param {integer} amountFeedbacks Number of feedbacks coefficients.
        %   @param {integer} amountFeedforwards Number of feedforwards coefficients.
        %   @param {float} pSignal Persistent signal for the filter.
        %
        %   @returns {object} self Is the instantiated object.
        %
        function self = IFilter(inputs, outputs, amountFeedbacks, amountFeedforwards, pSignal)
            self.inputs = inputs;
            self.outputs = outputs;
            self.coeffsM = amountFeedbacks;
            self.coeffsN = amountFeedforwards;
            self.persistentSignal = pSignal;
            self.initialize();
        end
        
        % This functions initializes the values of the coefficients ans the
        % matrices memory.
        %
        %   @param {float} feedbacks Indicates the array of coefficient values.
        %   @param {float} feedforwards Indicates the array of coefficient values.
        %   @param {float} pSignal Denotes the persistent signal value.
        %
        function initialize(self, feedbacks, feedforwards, pSignal)
            if nargin < 3
                [feedbacks, feedforwards, pSignal] = self.getInitialValues();
            end
            
            self.feedbacks = feedbacks;
            self.feedforwards = feedforwards;
            self.persistentSignal = pSignal;
            
            self.iMemory = zeros(self.outputs, self.coeffsM);
            self.oMemory = zeros(self.outputs, self.coeffsN);
        end
        
        % This function calculate the IIR filter outputs.
        %
        %   @param {float} iValues Indicates the array of input values.
        %
        function evaluate(self, iWavenet, iCtrlSignals)
            self.updateIMemory(iWavenet);
            
            gamma = diag(self.feedbacks * self.iMemory')' .* sum(iCtrlSignals);
            rho = (diag(self.feedforwards * self.oMemory') .* self.persistentSignal)';
            
            self.Gamma = gamma;
            self.Rho = rho;
            self.oValues = gamma + rho;
            self.updateOMemory(self.oValues);
        end
        
        % This function update the internal memory data.
        %
        %   @param {float} iValues Indicate the input values array.
        %
        function updateIMemory(self, iValues)
            self.iMemory = [iValues' self.iMemory(:,1:self.coeffsM-1)];
        end
        
        % This function update the internal memory data.
        %
        %   @param {float} oValues Indicate the output values array.
        %
        function updateOMemory(self, oValues)
            self.oMemory = [oValues' self.oMemory(:,1:self.coeffsN-1)];
        end
        
        % This function update the value of filter coefficients.
        %
        %   @param {float} feedbacks Indicates the feedbacks gradient.
        %   @param {float} feedforwards Indicates the feedforwards gradient.
        %
        function update(self, feedbacks, feedforwards)
            self.feedbacks = feedbacks;
            self.feedforwards = feedforwards;
        end
        
        % Initializes the matrices to store the behavior of the filter parameters.
        %
        %   @param {integer} samples Denotes of the samples amount for the simulation.
        %
        function bootPerformance(self, samples)
            self.perfFeedbacks = zeros(samples, self.inputs * self.coeffsM);
            self.perfFeedforwards = zeros(samples, self.outputs * self.coeffsN);
            self.perfOutputs = zeros(samples, self.outputs);
            self.perfGamma = zeros(samples, self.outputs);
            self.perfRho = zeros(samples, self.outputs);
        end
        
        % Stores the current value parameters.
        %
        %   @param {integer} iteration Represents the current sample.
        %
        function setPerformance(self, iteration)
            cols = 0:self.coeffsM:self.coeffsM*self.inputs;
            for item = 1:length(cols)-1
                self.perfFeedbacks(iteration, cols(item)+1:cols(item+1)) = self.feedbacks(item,:);
            end
            
            cols = 0:self.coeffsN:self.coeffsN*self.outputs;
            for item = 1:length(cols)-1
                self.perfFeedforwards(iteration, cols(item)+1:cols(item+1)) = self.feedforwards(item,:);
            end
            
            self.perfOutputs(iteration,:) = self.oValues;
            self.perfGamma(iteration,:) = self.Gamma;
            self.perfRho(iteration,:) = self.Rho;
        end
        
        % Provides the output values from the filter.
        %
        %   @returns {float} perfOutputs Output values array.
        %
        function perfOutputs = getPerfOutputs(self)
            perfOutputs = self.perfOutputs;
        end
        
        % Provides the filter behavior during simulation.
        %
        %   @returns {float} perfFeedbacks Coefficient performance matrix.
        %   @returns {float} perfFeedforwards Coefficient performance matrix.
        %   @returns {float} perfGamma Identification parameter performance matrix.
        %   @returns {float} perfRho Identification parameter performance matrix.
        %   @returns {float} perfOutputs Output performance matrix.
        %
        function [perfFeedbacks, perfFeedforwards, perfGamma, perfRho, perfOutputs] = ...
                getPerformance(self)
            perfFeedbacks = self.perfFeedbacks;
            perfFeedforwards = self.perfFeedforwards;
            perfGamma = self.perfGamma;
            perfRho = self.perfRho;
            perfOutputs = self.perfOutputs;
        end
        
        % Calls the functions to show the filter behavior.
        function charts(self)
            self.plotCoefficientes(self.perfFeedbacks, self.inputs, self.coeffsM, ...
                'Feedbacks coefficients', 'c');
            self.plotCoefficientes(self.perfFeedforwards, self.outputs, self.coeffsN, ...
                'Feedforwards coefficients', 'd');
        end
    end
    
    % These funcions are the getters and setters for each parameter class.
    methods (Access = public)        
        function setFeedbacks(self, feedbacks)
            self.feedbacks = feedbacks;
        end
        
        function setFeedforwards(self, feedforwards)
            self.feedforwards = feedforwards;
        end
        
        function feedbacks = getFeedbacks(self)
            feedbacks = self.feedbacks;
        end
        
        function feedforwards = getFeedforwards(self)
            feedforwards = self.feedforwards;
        end
        
        function coeffsM = getCoeffsM(self)
            coeffsM = self.coeffsM;
        end
        
        function N = getCoeffsN(self)
            N = self.coeffsN;
        end
        
        function outputs = getOutputs(self)
            outputs = self.oValues;
        end
        
        function gamma = getGamma(self)
            gamma = self.Gamma;
        end
        
        function Rho = getRho(self)
            Rho = self.Rho;
        end

        function persistentSignal = getPersistentSignal(self)
            persistentSignal = self.persistentSignal;
        end
    end
    
    methods (Access = protected)
        % Writes the filter parameters into a csv file.
        %
        %   @param {float} matrix The filter data.
        %   @param {string} directory Folderpath to save the file.
        %   @param {string} filename
        %   @param {string} name Filename suffix.
        %
        function writeParameterFile(~, matrix, directory, filename, name)
            T = array2table(matrix);
            filename = [directory filename ' ' name '.csv'];
            
            writetable(T, filename)
        end
        
        % Provedires the initial values of the filter
        %
        %   @returns {float} feedbacks Coefficient values.
        %   @returns {float} feedforwards Coefficient values.
        %   @returns {float} pSignal The persistent signal value.
        %
        function [feedbacks, feedforwards, pSignal] = getInitialValues(self)
            randd = @(a,b,f,c) a + (b-a)*rand(f,c);
            
            value = 1;
            pSignal = 0.001;
            
            feedbacks = randd(-value,value,self.outputs,self.coeffsM);
            feedforwards= randd(-value,value,self.outputs,self.coeffsN);
        end
        
        % Shows the behavior of the filter coefficients by means of a graph.
        %
        %   @param {float} array Filter coefficients performance matrix.
        %   @param {integer} cols Indicates the inputs amount.
        %   @param {integer} rows Represents the coefficients amount.
        %   @param {string} title The chart title.
        %   @param {string} tag Indicates the axis movement.
        %
        function plotCoefficientes(~, array, cols, rows, title, tag)
            figure('Name',title,'NumberTitle','off','units','normalized','outerposition',[0 0 1 1]);
            
            for col = 1:cols
                for row = 1:rows
                    subplot(rows, cols, col + cols*(row-1))
                        plot(array(:,row + (col-1)),'r','LineWidth',1)
                        ylabel(sprintf('%s_{%i,%i}', tag, col, row))
                end
                xlabel('Samples, k')
            end
        end
    end
end