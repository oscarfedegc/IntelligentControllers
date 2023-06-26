classdef IWavelet < ActivationFunction
    properties (Access = public)
        wavelet
    end
    
    methods (Access = public)
        function self = IWavelet(wavelet, neurons)
            if nargin ~= 2 || isempty(wavelet)
                wavelet = WaveletList.morlet;
                neurons = 3;
            end
            
            self.wavelet = wavelet;
            self.neurons = neurons;
            self.initialize();
        end
        
        function evaluateFunction(self)
            switch self.wavelet
                case WaveletList.morlet
                    self.morlet()
                case WaveletList.shannon
                    self.shannon()
                case WaveletList.mexicanHat
                    self.mexicanHat()
                case WaveletList.gaussian
                    self.gaussian()
                otherwise
                    if self.wavelet >= WaveletList.rasp1 && ...
                            self.wavelet <= WaveletList.rasp3
                        self.rasp()
                    elseif self.wavelet >= WaveletList.polywog1 && ...
                            self.wavelet <= WaveletList.polywog5
                        self.polywog()
                    end
            end
        end
    end
    
    methods (Access = protected)
        function morlet(self)
            w0 = 0.5;
            t = self.tau;
            a = self.scales;
            
            self.funcOutput = cos(w0*t).*exp(-0.5*t.^2);
            self.dfuncOutput = (w0.*sin(w0*t).*exp(-0.5*t.^2) + t.*self.funcOutput)./a;
        end
        
        function mexicanHat(self)
            self.funcOutput = zeros(1,self.neurons);
            self.dfuncOutput = ones(1,self.neurons);
        end
        
        function rasp(self)
            t = self.tau;
            a = self.scales;
            
            switch self.wavelet
                case WaveletList.rasp1
                    f = t./(t.^2 + 1).^2;
                    d = (3.*t - 1)./(a.*(t.^2 + 1).^3);
                case WaveletList.rasp2
                    f = t.*cos(t)./(t.^2 + 1);
                    d = ((t.^3 + t).*sin(t) + (t.^2 - 1).*cos(t))./(a.*(t.^2 + 1).^2);
                case WaveletList.rasp3
                    f = sin(pi.*t)./(t.^2 - 1);
                    d = (2.*t.*sin(pi.*t) + pi.*(t.^2 - 1).*cos(pi.*t))./(a.*(t.^2 - 1).^2);
            end
            
            self.funcOutput = f;
            self.dfuncOutput = d;
        end
        
        function polywog(self)
            t = self.tau;
            a = self.scales;
            e = exp(-0.5*t.^2);
            
            switch self.wavelet
                case WaveletList.polywog1
                    f = t.*e;
                    d = (t.^2 - 1).*e ./ a;
                case WaveletList.polywog2
                    f = (t.^3 - 3.*t).*e;
                    d = (t.^4 - 6.*t.^2 + 3).*e./a;
                case WaveletList.polywog3
                    f = (t.^4 - 6.*t.^2 + 3).*e;
                    d = (t.^5 - 10.*t.^3 + 15.*t).*e./a;
                case WaveletList.polywog4
                    f = (1 - t.^2).*e;
                    d = (3.*t - t.^3).*e./a;
                case WaveletList.polywog5
                    f = (3.*t.^2 - t.^4).*e;
                    d = (-t.^5 + 7.*t.^3 - 6.*t).*e./a;
            end
            
            self.funcOutput = f;
            self.dfuncOutput = d;
        end
        
        function shannon(self)
            t = self.tau;
            a = self.scales;
            
            self.funcOutput = (sin(2*pi.*t) - sin(pi.*t))./(pi.*t);
            self.dfuncOutput = (-2*pi.*t.*cos(2*pi.*t) + pi.*t.*cos(pi.*t) + sin(2*pi.*t) - sin(pi.*t)) .* pi ./ (pi.*a).^2;
        end
        
        function gaussian(self)
            t = self.tau;
            a = self.scales;
            b = self.scales;
            
            self.funcOutput = exp((t-a)./(2*b.^2));
            self.dfuncOutput = (-2*pi.*t.*cos(2*pi.*t) + pi.*t.*cos(pi.*t) + sin(2*pi.*t) - sin(pi.*t)) .* pi ./ (pi.*a).^2;
        end
    end
end