function plot_up
    close, clc
    
    x = linspace(-2,2,200);
    y = x;
    
    % EFT1  
    funcOutput = evaluateWindow(1, x);
    plot(x,funcOutput)
    hold on
    
    % Hanning  
    funcOutput = evaluateWindow(7, x);
    plot(x,funcOutput)
    
    % Hamming  
    funcOutput = evaluateWindow(8, x);
    plot(x,funcOutput)
    
    % Blackman  
    funcOutput = evaluateWindow(9, x);
    plot(x,funcOutput)
    
    % Blackman-Harris  
    funcOutput = evaluateWindow(10, x);
    plot(x,funcOutput)
    
    return
    
    for i = 1:length(x)
        y(i) = sumatory(1, 1, x(i));
    end
    
    plot(x,y)
    
    function rst = sumatory(samples, products, point)
        rst = 0;
        for k = 1:samples
            rst = rst + hatup(products, point);%*cos(k*pi*point);
        end
    end
    
    function rst = hatup(samples, point)
        rst = 1;
        
        for k = 1:samples
            rst = rst * sinc(point/2^k);
        end
    end

    function funcOutput = evaluateWindow(idx, x)
        K = 3/16;
        
        x
        
        % Window coefficients
        A = [ 0.139969361944199, 0.279646558214300, 0.267153027459332, 0.202120943545989, 0.092889443059007, 0.018244323707956, 0; ...
              0.188101508860125, 0.369231207086926, 0.287018792909551, 0.130768792913074, 0.024879698230324, 0,                 0; ...
              0.201424880000000, 0.39291808, 0.28504554, 0.10708192, 0.01352957, 0, 0; ...
              0.209785458600496, 0.407530071019158, 0.2811792263005, 0.092475737791143, 0.009041123909306, 0, 0; ...
              0.21375736, 0.41424355, 0.27860627, 0.08592806, 0.00746476, 0, 0; ...
              0.2710514, 0.43329794, 0.218123, 0.06592546, 0.0108117, 0.0007766, 0.0000139;...
              0.5, 0.5, 0, 0, 0, 0, 0;
              0.54, 0.46, 0, 0, 0, 0, 0;
              0.42, 0.5, 0.08, 0, 0, 0, 0;
              0.35875, 0.48829, 0.14128, 0.01168, 0, 0, 0];
      
        [~,b] = size(A);
        funcOutput = 0;
        for l = 1:b
           funcOutput = A(idx,l)*cos((K*(l-1)).*x) + funcOutput;
        end
    end
end