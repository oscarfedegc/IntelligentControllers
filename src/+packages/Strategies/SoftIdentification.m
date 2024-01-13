% This class that calls the other classes and generates the simulations
classdef SoftIdentification < Strategy
    properties (Access = public)
        % It is use to create the folder and output files
        PREFIX = 'Soft WNetIIR Identif';
        SAMPLES = 15000;
        OFFSET = 1100;
        
        forces, generalized, samples, ctrls2file
    end
    
    methods (Access = public)
        % Class constructor
        function self = SoftIdentification()
            return
        end
        
        % In this function, the user must give the simulations parameters
        function setup(self)
            % Load MAT file - System
            addpath ('src/+repositories/values/SOFT-ROBOT')
            self.forces = load('tau_input.mat');
            self.generalized = load('q_output.mat');
            
            init = self.OFFSET;
            final = self.OFFSET + self.SAMPLES - 1;
            
            self.forces = self.forces.tau(init:final,:);
            self.generalized = self.generalized.q(init:final,:);
            
            % Time parameters
            self.period = 0.001;  % Definited arbitrarily [sec]
            self.samples = length(self.forces(:,1));
            self.tFinal = self.period * self.samples;
            
            % Wavenet-IIR parameters
            self.nnaType = NetworkList.WavenetIIR;
            self.functionType = FunctionList.wavelet;
            self.functionSelected = WaveletList.rasp1;
            
            self.inputs = 3;
            self.outputs = 3;
            self.amountFunctions = 12;
            self.feedbacks = 4;
            self.feedforwards = 2;
            self.persistentSignal = 1;
            
            % learningRate = [Synaptic weights, scales, shifts, feedbacks, forwards]
            self.learningRates = .5 * [1e-4 1e-4 5e-6 5e-1 5e-2];
            self.rangeSynapticWeights = 5;
            
            % Training status and type reference signals
            self.isTraining = false;
        end
        
        % This funcion calls the class to generates the objects for the simulation.
        function builder(self)            
            % Building the Wavenet-IIR
            self.neuralNetwork = NetworkFactory.create(self.nnaType);
            self.neuralNetwork.setSynapticRange(self.rangeSynapticWeights)
            self.neuralNetwork.buildNeuronLayer(self.functionType, ...
                self.functionSelected, self.amountFunctions, self.inputs, self.outputs)
            self.neuralNetwork.buildFilterLayer(self.inputs, self.outputs, self.feedbacks, ...
                self.feedforwards, self.persistentSignal)
            self.neuralNetwork.setLearningRates(self.learningRates)
            self.neuralNetwork.bootInternalMemory()
            self.neuralNetwork.bootPerformance(self.samples)
            self.neuralNetwork.setStatus(self.isTraining)
            
            % Buildind the repository
            self.repository = IRepositorySoft(self.PREFIX);
            self.repository.setNeuralNetwork(self.neuralNetwork)
            self.repository.setFolderPath()
        end
        
        % Executes the algorithm.
        function execute(self)

            for iter = 1:self.samples
                kT = iter * self.period;
                self.persistentSignal = 0.1*sin(kT);
                u = self.forces(iter,:);
                
                % Compute from WaveNet-IIR
                self.neuralNetwork.evaluate(kT, u)
                
                yMes = self.generalized(iter,:);
                yEst = self.neuralNetwork.getOutputs();
                
                % Calculate the identification and tracking errors
                eIdentification = yMes - yEst;
                
                if isnan(eIdentification(1)) || isnan(eIdentification(2))
                    self.isSuccessfully = false;
                    break
                end
                
                self.neuralNetwork.setPerformance(iter)
                self.neuralNetwork.updateGradientDescent(u, eIdentification)
                self.log(iter, yMes, yEst, eIdentification, u)
                self.neuralNetwork.log()
            end
        end
        
        function saveCSV(self)
            self.repository.writeResults(self.period, self.SAMPLES, ...
                self.generalized, self.forces)
        end
        
        function showCharts(self)
            self.neuralNetwork.charts('noncompact')
            self.softTauControl()
            self.softPlotting()
        end
    end
    
    methods (Access = protected)
        % Display the algorithm behavior by means of the console messages.
        %
        %   @param {float} kT Instant of the time.
        %
        function log(~, sample, measured, estimated, identification, control)
            clc
            fprintf('>> SAMPLE No. %05d \n', sample)
            fprintf(' tau1 = %+015.8f\t tau2 = %+015.8f\t tau3 = %+015.8f\n', ...
                control(1), control(2), control(3))
            fprintf('real1 = %+015.8f\treal2 = %+015.8f\treal3 = %+015.8f\n', ...
                measured(1), measured(2), measured(3))
            fprintf(' est1 = %+015.8f\t est2 = %+015.8f\t est3 = %+015.8f\n', ...
                estimated(1), estimated(2), estimated(3))
            fprintf(' err1 = %+015.8f\t err2 = %+015.8f\t err3 = %+015.8f\n', ...
                identification(1), identification(2), identification(3))
        end
        
        % This function plots the simualtions results for the tracking
        % performance and identification performance. The graphs using
        % doubles scales.
        function softPlotting(self)
            if ~self.isSuccessfully
            end
            
            figure('Name','Identification process','NumberTitle','off','units','normalized',...
                'outerposition',[0 0 1 1]);
            
            lbl = {'l'; '\phi'; '\kappa'};
            
            measurement = self.generalized;
            approximation = self.neuralNetwork.getBehaviorApproximation();
            
            min_ = min(self.generalized);
            max_ = max(self.generalized);
            
            rows = 2;
            cols = length(measurement(1,:));
            
            identifError = measurement - approximation;
            
            % Identification and identification errors
            for item = 1:cols
                subplot(rows, cols, item)
                hold on
                plot(measurement(:,item),'k-','LineWidth',1)
                plot(approximation(:,item),'r','LineWidth',1)
                ylabel(sprintf('q_{%s} vs q_{%s}^{\\Gamma}', ...
                    string(lbl(item)), string(lbl(item))))
                lgd = legend(...
                    sprintf('Real, q_{%s}', string(lbl(item))), ...
                    sprintf('Approximation, q_{%s}^{\\Gamma}', string(lbl(item))), ...
                    'Location','northoutside');
                lgd.NumColumns = 2;
                ylim([min_(item) max_(item)])
                
                subplot(rows, cols, item + cols)
                plot(identifError(:,item),'LineWidth',1)
                ylabel(sprintf('e_{%s}', string(lbl(item))))
                legend(sprintf('Identification error, e_{%s}', string(lbl(item))), ...
                    'Location','northoutside');
                xlabel('Samples, K')
            end
        end
        
        % This function plots the simualtions results for the tracking
        % performance and identification performance. The graphs using
        % doubles scales.
        function softTauControl(self)
%             if ~self.isSuccessfully
%                 return
%             end
            
            figure('Name','Generalized forces','NumberTitle','off','units','normalized',...
                'outerposition',[0 0 1 1]);
            
            tau = self.forces;
            rows = 1;
            cols = 3;
            lbl = {'l'; '\phi'; '\kappa'};
            
            % Identification and identification errors
            for item = 1:length(tau(1,:))
                subplot(rows, cols, item)
                plot(tau(:,item),'LineWidth',1)
                xlabel('Samples, K')
                ylabel(sprintf('\\tau_{%s}', string(lbl(item))))
            end
        end
        
         %{
            Normalized the vector pressures
        
            @args
                inf {float} inferior limit of the normalized vector
                sup {float} superior limit of the normalized vector
        %}
        function normalizedPressures(self, inf, sup)
            data = self.forces;
            [min_, max_] = self.getArrayLimits();
            
            for input = 1:length(data(1,:))
                self.forces(:,input) = self.normalizedVector(data(:,input), ...
                    inf, sup, min_, max_);
            end
        end
        
        function output = normalizedVector(~, data, inf, sup, min, max)
            output = inf + (data - min).*(sup - inf)./(max - min);
        end
        
        function [min_, max_] = getArrayLimits(self)
            min_ = min(self.forces);
            max_ = max(self.forces);
        end
    end
end