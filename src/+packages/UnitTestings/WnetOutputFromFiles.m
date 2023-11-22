% function WnetOutputFromFiles
    clc, close all
    
    folder = 'src\+repositories\results\Backup\WAVENET-IIR IDENTIFICATION\FLATTOP2-J03-M04-N02-L05-T0060-X';
    
    af_filename = 'FLATTOP2-J03-M04-N02-L05-T0060-X PERFPSI.csv';
    w_pitch = 'FLATTOP2-J03-M04-N02-L05-T0060-X PERFWEIGHTS PITCH.csv';
    w_yaw = 'FLATTOP2-J03-M04-N02-L05-T0060-X PERFWEIGHTS YAW.csv';
    model = 'FLATTOP2-J03-M04-N02-L05-T0060-X PERFMODEL.csv';
    
    psi = readtable(sprintf("%s\\%s", folder, af_filename));
    wp = readtable(sprintf("%s\\%s", folder, w_pitch));
    wy = readtable(sprintf("%s\\%s", folder, w_yaw));
    mod = readtable(sprintf("%s\\%s", folder, model));
    
    psi = table2array(psi);
    wp = table2array(wp);
    wy = table2array(wy);
    mod = table2array(mod);
    
    samples = length(psi(:,1));
    z = zeros(samples, 2);
    
    for i = 1:samples
        fn_ = psi(i,2:4);
        wp_ = wp(i,2:4);
        wy_ = wy(i,2:4);
        
        z(i,:) = [fn_ * wp_', fn_ * wy_'];
    end
    
    zpitch = z(:,1);
    zyaw = z(:,2);
    ypitch = mod(:,6);
    yyaw = mod(:,7);
    
    fs = 1/0.005;           % Hz
    t = psi(:,1);           % seconds
    n = length(z(:,1));     % number of samples
    f = (0:n-1)*(fs/n);     % frequency range
    y = fft(z(:,1));
    power = abs(y).^2/n;    % power of the DFT
    
    pspectrum(z(:,1),t)
    
%     figure(2)
%     subplot(2,2,1)
%         hold on
%         plot(psi(:,1), z(:,1))
%         plot(psi(:,1), z(:,2))
%         legend('$z_1$','$z_2$','interpreter','latex')
%         xlabel('Tiempo')
%         ylabel('Posición')
%         
%     subplot(2,2,2)
%         hold on
%         plot(psi(:,1), mod(:,6))
%         plot(psi(:,1), mod(:,7))
%         legend('$\hat y_1$','$\hat y_2$','interpreter','latex')
%         xlabel('Tiempo')
%         ylabel('Posición')
%         
%     subplot(2,2,3)
%         hold on
%         plot(f,power)
% %         plot(psi(:,1), mod(:,7))
% %         legend('$\hat y_1$','$\hat y_2$','interpreter','latex')
%         xlabel('Frecuencia')
%         ylabel('Power')
% end