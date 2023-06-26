function UTStepFuncGenerate
%     randd = @(a,b) a + (b-a)*rand();
%     
%     t = 0:0.001:60;
%     T = 1e4;
%     s = length(t);
%     y = zeros(s,1);
%     a = 40;
%     
%     cnt = 0;
%     aux = 0;
%     
%     for i = 1:s
%         cnt = cnt + 1;
%         if mod(cnt,T) == 0
%             aux = randd(-1,1) * a;
%         end
%         y(i) = aux;
%     end
%     
%     plot(t,y)
    t = 0:0.005:10;
    func = FunctionFactory.create(FunctionList.wavelet, WaveletList.morlet, 1);
    shift = 0;
    scales = [0.995 1 1.110];
    
    function [funcOutput, dfuncOutput] = morlet(tau, scales)
            w0 = 0.5;
            
            funcOutput = cos(w0*tau).*exp(-0.5*tau.^2);
            dfuncOutput = (w0.*sin(w0*tau).*exp(-0.5*tau.^2) + tau.*self.funcOutput)./scales;
        end
end