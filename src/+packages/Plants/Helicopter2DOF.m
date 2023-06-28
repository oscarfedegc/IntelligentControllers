classdef Helicopter2DOF < Plant
    properties (Access = private)
        ORDER = 4;
    end
    
    methods (Access = public)
        function self = Helicopter2DOF()
            self.name = '2 DOF Helicopter';
            self.labels = {'pitch', 'yaw'};
            self.symbols = {'theta', 'phi'};
            self.nStates = self.ORDER;
            self.nTerms = 6;
        end
        
        function position = measured(self, inputs, iter)
            self.nonlinear(inputs, iter);
            position = [self.states(iter,1) self.states(iter,3)];
        end
        
        function addNoise(self, noise, iter)
            self.states(iter,1) = self.states(iter,1) + noise(1);
            self.states(iter,3) = self.states(iter,3) + noise(2);
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
            m   = 1.3872;
            g   = 9.8100;
            l   = 0.1860;
            Bp  = 0.8000;
            By  = 0.3180;
            Jp  = 0.0384;
            Jy  = 0.0432;
            Kpp = 0.2040;
            Kyy = 0.0720;
            Kyp = 0.0219;
            Kpy = 0.0068;

            % States
            x1 = self.states(iter,1);
            x2 = self.states(iter,2);
            x4 = self.states(iter,4);

            % Differential Equations (Nonlinear model)
            % Representation in state variables
            f1 = -(Bp*x2 + m*(x2*l)^2*sin(x1)*cos(x1) + m*g*l*cos(x1))/(Jp + m*l^2);
            f2 = -(By*x4 + 2*m*sin(x1)*cos(x1)*x2*x4*l^2)/(Jy + m*(l*cos(x1))^2);

            g11 = Kpp/(Jp + m*l^2);
            g12 = Kpy/(Jp + m*l^2);
            g21 = Kyp/(Jy + m*(l*cos(x1))^2);
            g22 = Kyy/(Jy + m*(l*cos(x1))^2);

            f = [x2; f1; x4; f2];
            g = [0,0; g11,g12; 0,0; g21,g22];
            u = [control(1); control(2)];
            
            self.perfTerms(iter,:) = [f1 f2 g11 g12 g21 g22];

            xdot = f + g*u;

            % States -- Euler aproximation of integration
            self.states(iter + 1,:) = self.states(iter,:) + self.period*xdot';
            
            % Approximation -- Gamma and Rho
            Rho = self.states(iter,:) + f'*self.period;
            Rho = Rho(1:2);
            Gamma = (g*self.period*u)';
            Gamma = Gamma(1:2);
            
            self.approximation(iter,:) = [Rho, Gamma];
        end
    end
end