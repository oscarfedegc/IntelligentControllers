function Descomposition
    clc, close all
    
    fs = 100;
    t = 0:1/fs:5;
    x = sin(2*pi*t*3);
    
    samples = 20;
    level = 3;
    
    x = x(1:samples);
    t = t(1:samples);
    
    [C,L] = wavedec(x,level,'db4')
    
    ex5H = wrcoef('a', C, L, 'db4', level)
    ex1L = wrcoef('d', C, L, 'db4', 1)
    ex2L = wrcoef('d', C, L, 'db4', 2)
    ex3L = wrcoef('d', C, L, 'db4', 3)
    
    plot(t,x)
    legend('Original')
    legend('boxoff')
end