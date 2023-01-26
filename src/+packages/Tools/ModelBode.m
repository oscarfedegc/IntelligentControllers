function ModelBode
    clc, close all
    
    H11 = tf([0 0 2.3610],[1 9.26 0]);
    H12 = tf([0 0 0.2402],[1 3.487 0]);
    H21 = tf([0 0 0.07871],[1 9.26 0]);
    H22 = tf([0 0 0.7895],[1 3.487 0]);
    
    bode(H11, H12, H21, H22, {0,10000})
    
    close all
    
    J = 0.01;
    b = 0.1;
    K = 0.01;
    R = 1;
    L = 0.5;
    s = tf('s');
    P_motor = K/((J*s+b)*(L*s+R)+K^2)
    
    bode(P_motor, {0,10000})
end