% This class implements the PID Controller and its methods to calculate the
% control signal and autotune its gains.
classdef IClassicalControllerPID < Controller
    methods (Access = public)
        % Class constructor.
        %
        %   @returns {object} self Is the instantiated object.
        %
        function self = IClassicalControllerPID()
            self.signal = 0;
            self.gains = zeros(1,3);
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
        function autotune(~,~)
            return
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
        
        % This function is in charge of calculate the control signal by
        % applying its controller formula.
        function evaluate(self)            
            u = self.signal;
            kp = self.gains(1);
            ki = self.gains(2);
            kd = self.gains(3);
            ep = self.eTrackingMemory;
            Ts = 0.005;
            
            self.signal = u + kp*(ep(1) - ep(2)) + ki*Ts*ep(1) + kd*(ep(1) - 2*ep(2) + ep(3));
        end
        
        % Shows the behavior of the gains and the control signal by means of a graph.
        %
        %   @param {string} title Indicates the name graph to show.
        %
        function charts(self, title, offset)
            figure('Name',title,'NumberTitle','off','units','normalized',...
                'outerposition',[0 0 1 1]);
            
            tag = {'Control signal';'Proportional'; 'Integral'; 'Derivative'};
            subs = {'V';'p'; 'i'; 'd'};
            samples = length(self.performance(:,1));
            items = length(self.performance(1,:));
            
            subplot(items, 1, 1)
                plot(offset + self.performance(:,1),'r','LineWidth',1)
                ylabel(sprintf('%s [%s]', string(tag(1)), string(subs(1))))
                xlabel('Samples, k')
                xlim([1 samples])
            
            for row = 2:items
                subplot(items, 1, row)
                plot(self.performance(:,row),'r','LineWidth',1)
                ylabel(sprintf('%s, K_{%s}', string(tag(row)), string(subs(row))))
                xlim([1 samples])
            end
        end
    end
end