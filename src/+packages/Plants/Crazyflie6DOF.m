classdef Crazyflie6DOF < Plant
    properties (Access = private)
        ORDER = 12;
    end
    
    methods (Access = public)
        function self = Crazyflie6DOF()
            self.name = '6-DOF Crazyflie';
            self.labels = {'x pos', 'y pos', 'altitude'};
            self.symbols = {'x', 'y', 'z', 'phi', 'theta', 'psi'};
            self.nStates = self.ORDER;
        end
        
        function position = measured(self, inputs, iter)
            self.nonlinear(inputs, iter);
            position = self.states(iter,:);
        end
        
        function order = getOrder(self)
            order = self.ORDER;
        end
        
        function labels = getLabels(self)
            labels = self.labels;
        end
    end
    
    methods (Access = protected)
        function nonlinear(self, control, iter)
            % Set constants
            m   = 0.0320;
            g   = 9.8100;
            l   = 0.0460;
            Jxx = 111.3e-7;
            Jyy = 111.3e-7;
            Jzz = 216.2e-7;
            Fr  = 1.68e-7;
            
            % Motor parameters
            A = [ 1 -1 -1  1; 1  1 -1 -1; 1  1  1  1; 1 -1  1 -1];
            P = A * control';
            RPM = 0.2685 * P + 4070.3;
            w = RPM * pi / 30;
            wr = -w(1) + w(2) - w(3) + w(4);

            % States
            x = self.states(iter,:);

            % Differential Equations (Nonlinear model)
            % Representation in state variables
            f = [   x(2);
                    0;
                    x(4);
                    0;
                    x(6);
                    g;
                    x(8);
                    -Fr*x(10)*wr/Jxx + (Jyy - Jzz)*x(10)*x(12)/Jxx;
                    x(10);
                    -Fr*x(8)*wr/Jyy + (Jzz - Jxx)*x(8)*x(12)/Jyy;
                    x(12);
                    (Jxx - Jyy)*x(8)*x(10)/Jzz
               ];
            
            g = [   0 0 0 0;
                    -(sin(x(7))*sin(x(11)) + cos(x(7))*sin(x(9))*cos(x(11)))/m 0 0 0;
                    0 0 0 0;
                    -(cos(x(7))*sin(x(9))*sin(x(11)) - sin(x(7))*cos(x(11)))/m 0 0 0;
                    0 0 0 0;
                    -cos(x(7))*cos(x(9))/m 0 0 0;
                    0 0 0 0;
                    0 l/Jxx 0 0;
                    0 0 0 0;
                    0 0 l/Jyy 0;
                    0 0 0 0;
                    0 0 0 1/Jzz
               ];

           u = control';
           
            xdot = f + g*u;

            % States -- Euler aproximation of integration
            self.states(iter + 1,:) = self.states(iter,:) + self.period*xdot';
        end
    end
end