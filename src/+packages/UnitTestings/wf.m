tf = 100;
T = 0.005;
t = 0:T:tf;

a = 1;
b = 0;

tau = (t - 0) ./ 1;

a0 = 25/46;
a1 = 1 - a0;
Csc = 0.125*pi;

N = 30;
n = 0:1:N;

wf_hann = a0 - a1.*cos(2*pi.*(n-10)./(2*N));

wf_hann1 = a0 - a1.*cos(Csc.*tau);

tau = (t - 0) ./ 10;
wf_hann2 = a0 - a1.*cos(Csc.*tau);

% wn_bm = 0.42 - 0.5.*cos(2*pi.*t) + 0.08.*cos(4*pi.*t);
% wn_bm_tau = 0.42 - 0.5.*cos(2*pi.*tau) + 0.08.*cos(4*pi.*tau);
% 
% c = [0.21557895 0.41663158 0.277263158 0.083578947 0.0069473];
% ft_t = c(1) - c(2).*cos(2*pi.*tau) + c(3).*cos(4*pi.*tau) - c(3).*cos(6*pi.*tau) + c(4).*cos(8*pi.*tau);
% 
% a = 10;
% b = 10;
% tau = (t - b) ./ a;
% ft_2 = c(1) - c(2).*cos(2*pi.*tau) + c(3).*cos(4*pi.*tau) - c(3).*cos(6*pi.*tau) + c(4).*cos(8*pi.*tau);
% 
% a = 1;
% b = 0;
% tau = (t - b) ./ a;
% ft_3 = c(1) - c(2).*cos(2*pi.*tau) + c(3).*cos(4*pi.*tau) - c(3).*cos(6*pi.*tau) + c(4).*cos(8*pi.*tau);
% 
% a = 1;
% b = 40;
% tau = (t - b) ./ a;
% ft_4 = c(1) - c(2).*cos(2*pi.*tau) + c(3).*cos(4*pi.*tau) - c(3).*cos(6*pi.*tau) + c(4).*cos(8*pi.*tau);
% 
% a = 10;
% b = 10;
% tau = (t - b) ./ a;
% wn_bm2 = 0.42 - 0.5.*cos(2*pi.*tau) + 0.08.*cos(4*pi.*tau);

close all
figure(1)
subplot(2,2,1)
hold on
plot(n,wf_hann)
% plot(t,wf_hann1)
% plot(t,wf_hann2)
% plot(t,ft_2)
% plot(t,ft_3)
% plot(t,ft_4)
% subplot(1,2,2)
% hold on
% plot(t,wn_bm_tau)
% plot(t,wn_bm2)
return