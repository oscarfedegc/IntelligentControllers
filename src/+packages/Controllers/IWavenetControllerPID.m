% This class implements the PID Controller and its methods to calculate the
% control signal and autotune its gains using a WaveNet-IIR parameter.
classdef IWavenetControllerPID < Controller
    methods (Access = public)
        % Class constructor.
        %
        %   @returns {object} self Is the instantiated object.
        %
        function self = IWavenetControllerPID()
            self.signal = 0;
            self.gains = zeros(1,3);
            self.updateRates = zeros(1,3);
            self.eTrackingMemory = zeros(1,3);
        end
        
        % Defines the gains autotune algorithm.
        %
        %   @param {float} trackingErr Difference between the desired position
        %                              and the real position.
        %   @param {float} identificationErr Difference between the real position and 
        %                                    the wavenet output.
        %   @param {float} gamma Represents a wavenet parameter.
        %
        function autotune(self, trackingErr, identificationErr, gamma)
            self.updateMemory(trackingErr)
            
            kp = self.gains(1);
            ki = self.gains(2);
            kd = self.gains(3);
            mp = self.updateRates(1);
            mi = self.updateRates(2);
            md = self.updateRates(3);
            ep = self.eTrackingMemory;
            
            kp = kp + mp*identificationErr*gamma*(ep(1) - ep(2));
            ki = ki + mi*identificationErr*gamma*ep(1);
            kd = kd + md*identificationErr*gamma*(ep(1) - 2*ep(2) + ep(3));
            
            self.gains = [kp ki kd];
            % self.normalized(1,2);
        end
        
        % This function is responsable for store the tracking error into an
        % array memory.
        %
        %   @param {float} trackingError Difference between the desired
        %                                position and the real position.
        %
        function updateMemory(self, trackingError)
            self.eTrackingMemory = [trackingError, self.eTrackingMemory(1:2)];
        end
        
        % This function is in charge of calculate the control signal.
        %
        %   @param {object} self Stands for instantiated object from this class.
        %
        function evaluate(self)            
            u = self.signal;
            kp = self.gains(1);
            ki = self.gains(2);
            kd = self.gains(3);
            ep = self.eTrackingMemory;
            Ts = 0.005;
            
            self.signal = u + kp*(ep(1) + ep(2)) + ki*ep(1)* Ts + ...
                kd*(ep(1) - 2*ep(2) + ep(3)) / Ts;
        end
        
        % Shows the behavior of the gains and the control signal by means of a graph.
        %
        %   @param {string} title Indicates the name graph to show.
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
        % Normalizes the gain values.
        %
        %   @param {float} inf Lower limit
        %   @param {float} sup Superior limit
        %
        function normalized(self, inf, sup)
            data = self.gains;
            self.gains = inf + (data - min(data)).*(sup - inf)./(max(data) - min(data));
        end
    end
end