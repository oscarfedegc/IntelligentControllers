classdef IFilter < handle
    properties (Access = public)
        feedbacks, feedforwards, oValues, persistentSignal {mustBeNumeric}
        iMemory, oMemory, Gamma, Phi, learningRates {mustBeNumeric}
        coeffsM, coeffsN, inputs, outputs {mustBeInteger}
%         perfFeedbacks, perfFeedforwards, perfGamma, perfPhi, perfOutputs {mustBeNumeric}
    end
    
    methods (Access = public)
        function self = IFilter(inputs, amountFeedbacks, amountFeedforwards, pSignal)
            self.inputs = inputs;
            self.outputs = inputs;
            self.coeffsM = amountFeedbacks;
            self.coeffsN = amountFeedforwards;
            self.persistentSignal = pSignal;
            self.generate();
        end
        
        function initialize(self, feedbacks, feedforwards, pSignal)
            self.feedbacks = feedbacks;
            self.feedforwards = feedforwards;
            self.persistentSignal = pSignal;
        end
        
        function evaluate(self, iValues)
            self.updateIMemory(iValues);
            
            gamma = diag(self.feedbacks * self.iMemory')';
            rho = (diag(self.feedforwards * self.oMemory') .* self.persistentSignal)';
            
            self.Gamma = gamma;
            self.Phi = rho;
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
        
%         function initPerformanceArrays(self, samples)
%             self.perfFeedbacks = zeros(samples, self.inputs * self.coeffsM);
%             self.perfFeedforwards = zeros(samples, self.outputs * self.coeffsN);
%             self.perfOutputs = zeros(samples, self.outputs);
%             self.perfGamma = zeros(samples, self.outputs);
%             self.perfPhi = zeros(samples, self.outputs);
%         end
%         
%         function savePerformance(self, index)
%             cols = 0:self.coeffsM:self.coeffsM*self.inputs;
%             for item = 1:length(cols)-1
%                 self.perfFeedbacks(index, cols(item)+1:cols(item+1)) = self.feedbacks(item,:);
%             end
%             
%             cols = 0:self.coeffsN:self.coeffsN*self.outputs;
%             for item = 1:length(cols)-1
%                 self.perfFeedforwards(index, cols(item)+1:cols(item+1)) = self.feedforwards(item,:);
%             end
%         end
        
%         function charts(self)
%             self.plotCoefficientes(self.perfFeedbacks, self.inputs, self.coeffsM, ...
%                 'Coeficientes de retardo', 'c');
%             self.plotCoefficientes(self.perfFeedforwards, self.outputs, self.coeffsN, ...
%                 'Coeficientes de adelanto', 'd');
%         end

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
        
        function outputs = getOutputs(self)
            outputs = self.oValues;
        end
        
        function gamma = getGamma(self)
            gamma = self.Gamma;
        end
        
        function phi = getPhi(self)
            phi = self.Phi;
        end
    end
    
    methods (Access = protected)
        function generate(self)
            self.feedbacks = rand(self.inputs, self.coeffsM);
            self.feedforwards = rand(self.outputs, self.coeffsN);
            self.iMemory = zeros(self.inputs, self.coeffsM);
            self.oMemory = zeros(self.outputs, self.coeffsN);
        end
        
%         function plotCoefficientes(~,array,cols,rows,title,tag)
%             figure('Name',title,'NumberTitle','off','units','normalized','outerposition',[0 0 1 1]);
%             
%             for col = 1:cols
%                 for row = 1:rows
%                     subplot(rows, cols, col + cols*(row-1))
%                         plot(array(:,row + (col-1)),'r','LineWidth',1)
%                         ylabel(sprintf('%s_{%i,%i}', tag, col, row))
%                 end
%                 xlabel('Muestras, k')
%             end
%         end
    end
end