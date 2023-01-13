classdef IPIDController < Controller
    methods (Access = public)
        function self = IPIDController()
            self.currentSignal = 0;
            self.currentGains = rand(1,3);
            self.updateRates = zeros(1,3);
            self.eTrackingMemory = zeros(1,3);
        end
        
        function autotune(self, error, gamma)
            kp = self.currentGains(1);
            ki = self.currentGains(2);
            kd = self.currentGains(3);
            mp = self.updateRates(1);
            mi = self.updateRates(2);
            md = self.updateRates(3);
            ep = self.eTrackingMemory;
            
            kp = kp + mp*error*gamma*(ep(1) - ep(2));
            ki = ki + mi*error*gamma*ep(1);
            kd = kd + md*error*gamma*(ep(1) - 2*ep(2) + ep(3));
            
            self.currentGains = [kp ki kd];
        end
        
        function updateMemory(self, trackingError)
            self.eTrackingMemory = [trackingError, self.eTrackingMemory(1:2)];
        end
        
        function evaluate(self)            
            u = self.currentSignal;
            kp = self.currentGains(1);
            ki = self.currentGains(2);
            kd = self.currentGains(3);
            ep = self.eTrackingMemory;
            
            new = u + kp*(ep(1) + ep(2)) + ki*ep(1) + kd*(ep(1) - 2*ep(2) + ep(3));
            
            self.currentSignal = new;
        end
        
%         function charts(self,title)
%             figure('Name',title,'NumberTitle','off','units','normalized','outerposition',[0 0 1 1]);
%             
%             tag = {'Proporcional'; 'Integral'; 'Derivativa'};
%             subs = {'p'; 'i'; 'd'};
%             
%             rows = 1 + length(self.perfGains(1,:));
%             for row = 1:rows - 1
%                 subplot(rows, 1, row)                
%                 plot(self.perfGains(:,row),'r','LineWidth',1)
%                 ylabel(sprintf('%s, K_{%s}', string(tag(row)), string(subs(row))))
%             end
%             
%             subplot(rows, 1, rows)
%                 plot(self.perfSignal,'r','LineWidth',1)
%                 ylabel('Señal de control, u [V]')
%                 xlabel('Muestras, k')
%         end
    end
end