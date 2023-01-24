% This class implements the PMR Controller and its methods to calculate the
% control signal and autotune its gains.
classdef IPMRController < Controller
    properties (Access = private)
        level, errorSignals, errorSamples {mustBeNumeric}
    end
    
    methods (Access = public)
        % Class constructor.
        %
        %   @returns {object} self Is the instantiated object.
        %
        function self = IPMRController()
            self.signal = 0;
            self.level = 2;
            self.gains = rand(1,3);
            self.updateRates = zeros(1,3);
            self.eTrackingMemory = zeros(2,3);
            self.setErrorSamples(5);
        end
        
        % This function changes the size of memory for the tracking error.
        %
        %   @param {int} samples Amount of tracking error samples.
        %
        function setErrorSamples(self, samples)
            self.errorSamples = samples;
            self.errorSignals = zeros(1,samples);
        end
        
        % Assigns the initial value of gains, defines the descomposition
        % level and initializes the arrays memory for descomposition.
        %
        %   @param {object} self Stands for instantiated object from this class.
        %   @param {float[]} gains Indicate the initial values.
        %
        function setGains(self, gains)
            self.gains = gains;
            self.level = length(gains) - 1;
            self.eTrackingMemory = zeros(2, self.level + 1);
        end
        
        % Defines the gains autotune algorithm.
        %
        %   @param {object} self Stands for instantiated object from this class.
        %   @param {float} trackingError Difference between the desired position
        %                              and the real position.
        %   @param {float} gamma Represents a wavenet parameter.
        %   @param {float} period Sampling period of the plant.
        %
        function autotune(self, trackingError, gamma)
            self.updateMemory(trackingError);
            
            deltaGains = zeros(1, self.level + 1);
            epsilon = self.eTrackingMemory;
            mu = self.updateRates;
            
            for i = 1:self.level
                deltaGains(i) = gamma * mu(i) * (epsilon(1,i) - epsilon(2,i));
            end
            
            self.gains = self.gains + deltaGains;
        end
        
        % This function is responsable for store the tracking error into an
        % array memory after the descomposition.
        %
        %   @param {float} trackingError Difference between the desired
        %                                position and the real position.
        %
        function updateMemory(self, trackingError)
            self.errorSignals = [trackingError, self.errorSignals(1:self.errorSamples-1)];
            descomposition = self.descomposition(self.errorSignals);
            self.eTrackingMemory = [descomposition; self.eTrackingMemory(1,:)];
        end
        
        % This function is in charge of calculate the control signal.
        %
        %   @param {object} self Stands for instantiated object from this class.
        %
        function evaluate(self)
            self.signal = self.signal + sum(self.gains.*self.eTrackingMemory(1,:));
        end
        
        % Shows the behavior of the gains and the control signal by means of a graph.
        %
        %   @param {object} self Stands for instantiated object from this class.
        %   @param {string} title Indicates the name graph to show.
        %
        function charts(self, title)
            figure('Name',title,'NumberTitle','off','units','normalized',...
                'outerposition',[0 0 1 1]);
            
            items = length(self.performance(1,:));
            for row = 1:items - 1
                subplot(items, 1, row)
                plot(self.performance(:,row),'r','LineWidth',1)
                ylabel(sprintf('K_{P_%i}', row))
            end
            
            subplot(items, 1, items)
                plot(self.performance(:,items),'r','LineWidth',1)
                ylabel('Control signal, u [V]')
                xlabel('Samples, k')
        end
    end
    
    methods (Access = protected)
        % Implements the descomposition methods for the tracking error signal.
        %
        %   @param {object} self
        %   @param {float[]} errorSignal The tracking error from the
        %                                current until (k-N) periods.
        %   @return {float[]} output Is the descomposed signal.
        %
        function output = descomposition(self, errorSignal)
            output = zeros(self.level + 1, self.errorSamples);
            
            [C,L] = wavedec(errorSignal, self.level, 'db2');
            
            output(1,:) = wrcoef('a', C, L, 'db2', self.level);
            
            for i = 2:self.level + 1
                output(i,:) = wrcoef('d', C, L, 'db2', i-1);
            end
            
            output = output(:,1)';
        end
    end
end