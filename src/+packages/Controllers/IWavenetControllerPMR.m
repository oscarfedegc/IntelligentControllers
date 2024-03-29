% This class implements the PMR Controller and its methods to calculate the
% control signal and autotune its gains using a Wavenet-IIR parameter.
classdef IWavenetControllerPMR < Controller
    properties (Access = private)
        level, errorSignals, errorSamples {mustBeNumeric}
    end
    
    methods (Access = public)
        % Class constructor.
        %
        %   @returns {object} self Is the instantiated object.
        %
        function self = IWavenetControllerPMR()
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
        %   @param {float} gains Indicate the initial values array.
        %
        function setLevelDescomposition(self)
            self.level = length(self.gains) - 1;
            self.eTrackingMemory = zeros(2, self.level + 1);
        end
        
        % Defines the gains autotune algorithm.
        %
        %   @param {float} trackingError Difference between the desired position
        %                              and the real position.
        %   @param {float} gamma Represents a wavenet parameter.
        %   @param {float} period Sampling period of the plant.
        %
        function autotune(self, trackingError, ~, Gamma)
            self.updateMemory(trackingError);
            
            deltaGains = zeros(1, self.level + 1);
            epsilon = self.eTrackingMemory;
            mu = self.updateRates;
            
            for i = 1:self.level + 1
                deltaGains(i) = mu(i) * Gamma * (epsilon(1,i) - epsilon(2,i));
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
            self.descomposition(self.errorSignals);
        end
        
        % This function is in charge of calculate the control signal by
        % applying the controller formula.
        function evaluate(self)
            epsilon = self.eTrackingMemory(1,:) - self.eTrackingMemory(2,:);
            self.signal = self.signal + sum(self.gains.*epsilon);
        end
        
        % Shows the behavior of the gains and the control signal by means of a graph.
        %
        %   @param {string} title Indicates the name graph to show.
        %   @param {float} offset Represents the phase shitf applied to the
        %                                                         contol signal.
        %
        function charts(self, title, offset)
            figure('Name',title,'NumberTitle','off','units','normalized',...
                'outerposition',[0 0 1 1]);
            
            items = length(self.performance(1,:));
            
            subplot(items, 1, 1)
                plot(self.performance(:,1) + offset,'r','LineWidth',1)
                ylabel('Control signal, u [V]')
                
            for row = 2:items
                subplot(items, 1, row)
                plot(self.performance(:,row),'r','LineWidth',1)
                ylabel(sprintf('K_{P_%i}', row))
            end
            xlabel('Samples, k')
        end
    end
    
    methods (Access = protected)
        % Implements the descomposition methods for the tracking error signal.
        %
        %   @param {float} errorSignal The tracking error from the current
        %                                                 until (k-N) periods.
        %
        function descomposition(self, errorSignal)
            output = zeros(self.errorSamples, self.level + 1);
            rows = self.errorSamples - 1 : 1 : self.errorSamples;
            
            try
                [C,L] = wavedec(errorSignal, self.level, 'db2');

                output(:,1) = wrcoef('a', C, L, 'db2', self.level);

                for i = 2:self.level + 1
                    output(:,i) = wrcoef('d', C, L, 'db2', i-1);
                end
            catch
                return
            end
            
            self.eTrackingMemory = output(rows,:);
        end
    end
end