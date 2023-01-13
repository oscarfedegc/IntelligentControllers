classdef IAtomic < AbstractFunction
    properties (Constant)
        REPOSITORY = 'src/+repositories/WindowsCoeffs';
    end
    
    properties (Access = protected)
        domain, values, derivatives {mustBeNumeric}        
        xInit, xDiff, yDiff {mustBeNumeric}        
        items {mustBeInteger}
    end
    
    methods (Access = public)
        function self = IAtomic(neurons)
            if nargin ~= 1
                neurons = 3;
            end
            
            addpath (self.REPOSITORY)
            
            self.neurons = neurons;
            self.domain = load('x_Up.csv');
            self.values = load('Phi_Up.csv');
            self.derivatives = load('dPhi_Up.csv');
            
            self.items = length(self.domain);
            
            self.xInit = self.domain(1);
            self.xDiff = self.domain(self.items) - self.domain(1);
            self.yDiff = self.items - 1;
            
            self.generate();
        end
        
        function evaluateFunction(self)
            t = self.tau;
            idxs = self.getIndex(t);
            
            for i = 1:length(idxs)
                if idxs(i) > length(self.domain)
                    idxs(i) = length(self.domain);
                end
            end
            
            self.funcOutput  = self.values(idxs);
            self.dfuncOutput = self.derivatives(idxs);
        end
    end
    
    methods (Access = protected)
        function indexes = getIndex(self, args)
            indexes = abs(round((args - self.xInit) * self.yDiff / self.xDiff));
        end
    end
end