% This class implements the infinite impulse response (IIR) filter and its
% methods to calculate the outputs and update its coefficients.
classdef IFilter < handle
    properties (Access = public)
        feedbacks, feedforwards, oValues, persistentSignal {mustBeNumeric}
        iMemory, oMemory, Gamma, Rho, learningRates {mustBeNumeric}
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
        function self = IFilter(inputs, amountFeedbacks, amountFeedforwards, pSignal)
            self.inputs = inputs;
            self.outputs = inputs;
            self.coeffsM = amountFeedbacks;
            self.coeffsN = amountFeedforwards;
            self.persistentSignal = pSignal;
            self.initialize();
        end
        
        % This functions initializes the values of the coefficients ans the
        % matrices memory.
        %
        %   @param {object} self Stands for instantiated object from this class.
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
            
            self.iMemory = zeros(self.inputs, self.coeffsM);
            self.oMemory = zeros(self.outputs, self.coeffsN);
        end
        
        % This function calculate the IIR filter outputs.
        %
        %   @param {object} self Stands for instantiated object from this class.
        %   @param {float} iValues Indicates the array of input values.
        %
        function evaluate(self, iValues)
            self.updateIMemory(iValues);
            
            gamma = diag(self.feedbacks * self.iMemory')' .* sum(iValues);
            rho = (diag(self.feedforwards * self.oMemory') .* self.persistentSignal)';
            
            self.Gamma = gamma;
            self.Rho = rho;
            self.oValues = gamma + rho;
            self.updateOMemory(self.oValues);
        end
        
        function updateIMemory(self, iValues)
            self.iMemory = [iValues' self.iMemory(:,1:self.coeffsM-1)];
        end
        
        function updateOMemory(self, oValues)
            self.oMemory = [oValues' self.oMemory(:,1:self.coeffsN-1)];
        end
        
        function update(self, feedbacks, feedforwards)
            self.feedbacks = self.feedbacks - self.learningRates(1).*feedbacks;
            self.feedforwards = self.feedforwards - self.learningRates(2).*feedforwards;
        end
        
        function bootPerformance(self, samples)
            self.perfFeedbacks = zeros(samples, self.inputs * self.coeffsM);
            self.perfFeedforwards = zeros(samples, self.outputs * self.coeffsN);
            self.perfOutputs = zeros(samples, self.outputs);
            self.perfGamma = zeros(samples, self.outputs);
            self.perfRho = zeros(samples, self.outputs);
        end
        
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
        
        function perfOutputs = getPerfOutputs(self)
            perfOutputs = self.perfOutputs;
        end
        
        function [perfFeedbacks, perfFeedforwards, perfGamma, perfRho, perfOutputs] = ...
                getPerformance(self)
            perfFeedbacks = self.perfFeedbacks;
            perfFeedforwards = self.perfFeedforwards;
            perfGamma = self.perfGamma;
            perfRho = self.perfRho;
            perfOutputs = self.perfOutputs;
        end
        
        function charts(self)
            self.plotCoefficientes(self.perfFeedbacks, self.inputs, self.coeffsM, ...
                'Feedbacks coefficients', 'c');
            self.plotCoefficientes(self.perfFeedforwards, self.outputs, self.coeffsN, ...
                'Feedforwards coefficients', 'd');
        end
    end
    
    methods (Access = public)
        function setLearningRates(self, rates)
            self.learningRates = rates;
        end
        
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
    end
    
    methods (Access = protected)
        function writeParameterFile(~, matrix, directory, filename, name)
            T = array2table(matrix);
            filename = lower([directory filename ' ' name '.csv']);
            
            writetable(T, filename)
        end
        
        function [feedbacks, feedforwards, pSignal] = getInitialValues(self)
            randd = @(a,b,f,c) a + (b-a)*rand(f,c);
            
            value = 0.1;
            pSignal = 0.001;
            
            feedbacks = randd(value,2*value,self.outputs,self.coeffsM);
            feedforwards= zeros(self.outputs,self.coeffsN);
        end
        
        function plotCoefficientes(~, array, cols, rows, title, tag)
            figure('Name',title,'NumberTitle','off','units','normalized','outerposition',[0 0 1 1]);
            
            for col = 1:cols
                for row = 1:rows
                    subplot(rows, cols, col + cols*(row-1))
                        plot(array(:,row + (col-1)),'r','LineWidth',1)
                        ylabel(sprintf('%s_{%i,%i}', tag, col, row))
                end
                xlabel('Muestras, k')
            end
        end
    end
end