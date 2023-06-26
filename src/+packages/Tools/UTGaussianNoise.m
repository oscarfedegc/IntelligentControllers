function UTGaussianNoise
    clc, close all
    
    t = 0:0.005:10;
    y = 4*cos(2*pi.*t) + 2*sin(3*pi.*t) + 5*sin(pi.*t);
    
    L = length(t); %Sample length for the random signal
    mu = 1;
    sigma = 0.1;
    X = sigma*randn(1,L) + mu;
    
    Z = y + X;
    
    figure()
        subplot(4,1,1)
        plot(t,y)
        title('Signal')
        xlabel('Time')
        ylabel('Values')
        
        subplot(3,1,2)
        plot(t,X);
        title(['White noise : \mu_x=',num2str(mu),' \sigma^2=',num2str(sigma^2)])
        xlabel('Time')
        ylabel('Sample Values')
        
        subplot(3,1,3)
        plot(t,Z);
        title(['Signal + White noise : \mu_x=',num2str(mu),' \sigma^2=',num2str(sigma^2)])
        xlabel('Time')
        ylabel('Values')
end