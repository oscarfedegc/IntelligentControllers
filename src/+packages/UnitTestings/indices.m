function indices
    clc, close all
    
    PERIOD = 0.005;
    
%     classicalPoly = 'src\+repositories\results\CLASSICAL PID\POLYWOG3-J03-M04-N02-G03-T060-T03-Y\POLYWOG3-J03-M04-N02-G03-T060-T03-Y PERFMODEL.csv';
%     classicalStep = 'src\+repositories\results\CLASSICAL PID\FLATTOP2-J03-M04-N02-G03-T060-T02-Y\FLATTOP2-J03-M04-N02-G03-T060-T02-Y PERFMODEL.csv';
%     pidWnetPoly = 'src\+repositories\results\WAVENET-IIR PID\FLATTOP2-J03-M04-N02-G03-T060-T01-Y\FLATTOP2-J03-M04-N02-G03-T060-T01-Y PERFMODEL.csv';
%     pidWnetStep = 'src\+repositories\results\WAVENET-IIR PID\FLATTOP2-J03-M04-N02-G03-T060-T02-Y\FLATTOP2-J03-M04-N02-G03-T060-T02-Y PERFMODEL.csv';
%     pmrWnetPoly = 'src\+repositories\results\WAVENET-IIR PMR\FLATTOP2-J03-M04-N02-G06-T060-T03-Y\FLATTOP2-J03-M04-N02-G06-T060-T03-Y PERFMODEL.csv';
%     pmrWnetStep = 'src\+repositories\results\WAVENET-IIR PMR\FLATTOP2-J03-M04-N02-G06-T060-T02-Y\FLATTOP2-J03-M04-N02-G06-T060-T02-Y PERFMODEL.csv';
    labviewClassical = 'src\+repositories\values\Classical PID EFT2 processing.csv';
    labviewTuneEFT2 = 'src\+repositories\values\Selftune PID EFT2 processing.csv';
%     labviewTuneMorlet = 'src\+repositories\values\Selftune PID Morlet processing.csv';

    tab = readtable(labviewClassical);
    
    pitch = sum(tab.pitch_err)/length(tab.pitch_err)
    yaw = sum(tab.yaw_err)/length(tab.pitch_err)
    
    tab = readtable(labviewTuneEFT2);
    
    pitch = sum(tab.pitch_err)/length(tab.pitch_err)
    yaw = sum(tab.yaw_err)/length(tab.pitch_err)
%     
%     [classicalPitch, classicalYaw] = calculateIndixes(classicalPoly, PERIOD);
%     [classPitchStep, classYawStep] = calculateIndixes(classicalStep, PERIOD);
    
%     [pidWnetPitch, pidWnetYaw] = calculateIndixes(pidWnetPoly, PERIOD);
%     [pmrWnetPitch, pmrWnetYaw] = calculateIndixes(pmrWnetPoly, PERIOD);
    
%     [pidWnetPitchStep, pidWnetYawStep] = calculateIndixes(pidWnetStep, PERIOD);
%     [pmrWnetPitchStep, pmrWnetYawStep] = calculateIndixes(pmrWnetStep, PERIOD);
%     
%     [labClassicalPitch, labClassicalYaw] = calculateLabiew(labviewClassical, PERIOD);
%     [labviewTunePitch, labviewTunelYaw] = calculateLabiew(labviewTuneEFT2, PERIOD);
%     [labviewTunePitchMorlet, labviewTunelYawMorlet] = calculateLabiew(labviewTuneMorlet, PERIOD);
%     
%     disp('Pme WaveNet-IIR vs Classical PID :: Polynomial references :: Simulation')
%     print( 'ISE', labviewTunePitch(1), labviewTunelYaw(1), labviewTunePitchMorlet(1), labviewTunelYawMorlet(1))
%     print('ITSE', labviewTunePitch(2), labviewTunelYaw(2), labviewTunePitchMorlet(2), labviewTunelYawMorlet(2))
%     print( 'IAE', labviewTunePitch(3), labviewTunelYaw(3), labviewTunePitchMorlet(3), labviewTunelYawMorlet(3))
%     print('ITAE ', labviewTunePitch(4), labviewTunelYaw(4), labviewTunePitchMorlet(4), labviewTunelYawMorlet(4))

%     disp('Pme WaveNet-IIR vs Classical PID :: Polynomial references :: Simulation')
%     print('ISE', pmrWnetPitch(1), pmrWnetYaw(1), classicalPitch(1), classicalYaw(1))
%     print('ITSE', pmrWnetPitch(2), pmrWnetYaw(2), classicalPitch(2), classicalYaw(2))
%     print('IAE', pmrWnetPitch(3), pmrWnetYaw(3), classicalPitch(3), classicalYaw(3))
%     print('ITAE ', pmrWnetPitch(4), pmrWnetYaw(4), classicalPitch(4), classicalYaw(4))
    
%     disp('PID WaveNet-IIR vs Classical PID :: Polynomial references :: Simulation')
%     print('ISE', pidWnetPitch(1), pidWnetYaw(1), classicalPitch(1), classicalYaw(1))
%     print('ITSE', pidWnetPitch(2), pidWnetYaw(2), classicalPitch(2), classicalYaw(2))
%     print('IAE', pidWnetPitch(3), pidWnetYaw(3), classicalPitch(3), classicalYaw(3))
%     print('ITAE ', pidWnetPitch(4), pidWnetYaw(4), classicalPitch(4), classicalYaw(4))
%     
%     disp(' ')
%     disp('PID WaveNet-IIR vs Classical PID :: Polynomial references :: LabVIEW')
%     print('ISE', labviewTunePitch(1), labviewTunelYaw(1), labClassicalPitch(1), labClassicalYaw(1))
%     print('ITSE', labviewTunePitch(2), labviewTunelYaw(2), labClassicalPitch(2), labClassicalYaw(2))
%     print('IAE', labviewTunePitch(3), labviewTunelYaw(3), labClassicalPitch(3), labClassicalYaw(3))
%     print('ITAE', labviewTunePitch(4), labviewTunelYaw(4), labClassicalPitch(4), labClassicalYaw(4))
%     
%     disp(' ')
%     disp('PMR WaveNet-IIR vs PID WaveNet-IIR :: Polynomial references :: Simulation')
%     print('ISE', pmrWnetPitch(1), pmrWnetYaw(1), pidWnetPitch(1), pidWnetYaw(1))
%     print('ITSE', pmrWnetPitch(2), pmrWnetYaw(2), pidWnetPitch(2), pidWnetYaw(2))
%     print('IAE', pmrWnetPitch(3), pmrWnetYaw(3), pidWnetPitch(3), pidWnetYaw(3))
%     print('ITAE', pmrWnetPitch(4), pmrWnetYaw(4), pidWnetPitch(4), pidWnetYaw(4))
%     
%     disp(' ')
%     disp('PMR WaveNet-IIR vs PID WaveNet-IIR vs Classical PID :: Step references :: Simulation')
%     fprintf('ISE  & \\num{%.2f} & \\num{%.2f} & \\num{%.2f} & \\num{%.2f} & \\num{%.2f} & \\num{%.2f} \\\\\n', ...
%         pmrWnetPitchStep(1), pmrWnetYawStep(1), pidWnetPitchStep(1), pidWnetYawStep(1), classPitchStep(1), classYawStep(1))
%     fprintf('ITSE & \\num{%.2f} & \\num{%.2f} & \\num{%.2f} & \\num{%.2f} & \\num{%.2f} & \\num{%.2f} \\\\\n', ...
%         pmrWnetPitchStep(2), pmrWnetYawStep(2), pidWnetPitchStep(2), pidWnetYawStep(2), classPitchStep(2), classYawStep(2))
%     fprintf('IAE  & \\num{%.2f} & \\num{%.2f} & \\num{%.2f} & \\num{%.2f} & \\num{%.2f} & \\num{%.2f} \\\\\n', ...
%         pmrWnetPitchStep(3), pmrWnetYawStep(3), pidWnetPitchStep(3), pidWnetYawStep(3), classPitchStep(3), classYawStep(3))
%     fprintf('ITAE & \\num{%.2f} & \\num{%.2f} & \\num{%.2f} & \\num{%.2f} & \\num{%.2f} & \\num{%.2f} \\\\\n\n', ...
%         pmrWnetPitchStep(4), pmrWnetYawStep(4), pidWnetPitchStep(4), pidWnetYawStep(4), classPitchStep(4), classYawStep(4))
% %
%     reduce('ISE',  pmrWnetPitchStep(1), pmrWnetYawStep(1), pidWnetPitchStep(1), pidWnetYawStep(1), classPitchStep(1), classYawStep(1))
%     reduce('ITSE', pmrWnetPitchStep(2), pmrWnetYawStep(2), pidWnetPitchStep(2), pidWnetYawStep(2), classPitchStep(2), classYawStep(2))
%     reduce('IAE',  pmrWnetPitchStep(3), pmrWnetYawStep(3), pidWnetPitchStep(3), pidWnetYawStep(3), classPitchStep(3), classYawStep(3))
%     reduce('ITAE', pmrWnetPitchStep(4), pmrWnetYawStep(4), pidWnetPitchStep(4), pidWnetYawStep(4), classPitchStep(4), classYawStep(4))
    %%
    
%     pidWnet01Morlet = 'src\+repositories\results\WAVENET-IIR PID\POLYWOG4-J03-M04-N02-G03-T060-T01-Y\POLYWOG4-J03-M04-N02-G03-T060-T01-Y PERFMODEL.csv';
%     pidWnet01EFT2 = 'src\+repositories\results\WAVENET-IIR PID\FLATTOP2-J03-M04-N02-G03-T060-T01-Y\FLATTOP2-J03-M04-N02-G03-T060-T01-Y PERFMODEL.csv';
    
%     pidWnet01Morlet = 'src\+repositories\results\WAVENET-IIR PMR\POLYWOG4-J03-M04-N02-G06-T060-T01-Y\POLYWOG4-J03-M04-N02-G06-T060-T01-Y PERFMODEL.csv';
%     pidWnet01EFT2 = 'src\+repositories\results\WAVENET-IIR PMR\FLATTOP2-J03-M04-N02-G06-T060-T01-Y\FLATTOP2-J03-M04-N02-G06-T060-T01-Y PERFMODEL.csv';
    
%     pidWnet01Morlet = 'src\+repositories\results\WAVENET-IIR PMR\POLYWOG4-J03-M04-N02-G06-T060-T02-Y\POLYWOG4-J03-M04-N02-G06-T060-T02-Y PERFMODEL.csv';
%     pidWnet01EFT2 = 'src\+repositories\results\WAVENET-IIR PMR\FLATTOP2-J03-M04-N02-G06-T060-T02-Y\FLATTOP2-J03-M04-N02-G06-T060-T02-Y PERFMODEL.csv';
    
%     [pidWnetPitchP4, pidWnetYawP4] = calculateIndixes(pidWnet01Morlet, PERIOD);
%     [pidWnetPitchE2, pidWnetYawE2] = calculateIndixes(pidWnet01EFT2, PERIOD);
%     
%     disp(' ')
%     disp('PMR WaveNet-IIR :: POLYWOG4 vs EFT2 :: Polynomial references :: Simulation')
%     printv2( 'ISE', pidWnetPitchP4(1), pidWnetYawP4(1), pidWnetPitchE2(1), pidWnetYawE2(1))
%     printv2('ITSE', pidWnetPitchP4(2), pidWnetYawP4(2), pidWnetPitchE2(2), pidWnetYawE2(2))
%     printv2( 'IAE', pidWnetPitchP4(3), pidWnetYawP4(3), pidWnetPitchE2(3), pidWnetYawE2(3))
%     printv2('ITAE', pidWnetPitchP4(4), pidWnetYawP4(4), pidWnetPitchE2(4), pidWnetYawE2(4))
    
    %%
    function rst = percentage(a,b)
        rst = 100 * (b-a)/b;
    end

    function print(idx, a, b, c, d)
        fprintf('%s & \\num{%.2f} & \\num{%.2f} & \\num{%.2f} & \\num{%.2f} & \\qty{%.2f}{\\percent} & \\qty{%.2f}{\\percent} \\\\\n', ...
            idx, a, b, c, d, percentage(a,c), percentage(b,d))
    end

    function printv2(idx, a, b, c, d)
        fprintf('%s & \\num{%.2f} & \\num{%.2f} & \\num{%.2f} & \\num{%.2f} & \\qty{%.2f}{\\percent} & \\qty{%.2f}{\\percent} \\\\\n', ...
            idx, a, b, c, d, percentage(c,a), percentage(d,b))
    end

    function reduce(idx, a, b, c, d, e, f)
        fprintf('%4s & \\qty{%.2f}{\\percent} & \\qty{%.2f}{\\percent} & \\qty{%.2f}{\\percent} & \\qty{%.2f}{\\percent} \\\\\n', idx, percentage(a,c), percentage(b,d), percentage(a,e), percentage(b,f))
    end

    function [pitch, yaw] = calculateIndixes(filename, period)
        file = readtable(filename);
    
        pitch = [ISETrapezoidal(file.epsilonpitch, period), ...
                 ITSETrapezoidal(file.epsilonpitch, period), ...
                 IAETrapezoidal(file.epsilonpitch, period), ...
                 ITAETrapezoidal(file.epsilonpitch, period)];
                  
        yaw = [ISETrapezoidal(file.epsilonyaw, period), ...
               ITSETrapezoidal(file.epsilonyaw, period), ...
               IAETrapezoidal(file.epsilonyaw, period), ...
               ITAETrapezoidal(file.epsilonyaw, period)];
           
%         pitchAvg = sum(file.epsilonpitch)/length(file.epsilonpitch)
%         yawAvg = sum(file.epsilonyaw)/length(file.epsilonyaw)
%         
%         plot(file.time,file.refyaw)
%         hold on
%         plot(file.time,file.mesyaw)
    end

    function [pitch, yaw] = calculateLabiew(filename, period)
        file = readtable(filename);
    
        pitch = [ISETrapezoidal(file.pitch_err, period), ...
                 ITSETrapezoidal(file.pitch_err, period), ...
                 IAETrapezoidal(file.pitch_err, period), ...
                 ITAETrapezoidal(file.pitch_err, period)];
                  
        yaw = [ISETrapezoidal(file.yaw_err, period), ...
               ITSETrapezoidal(file.yaw_err, period), ...
               IAETrapezoidal(file.yaw_err, period), ...
               ITAETrapezoidal(file.yaw_err, period)];
           
%         pitchAvg = sum(file.pitch_err)/length(file.pitch_err)
%         yawAvg = sum(file.yaw_err)/length(file.yaw_err)
    end

    function rst = ISETrapezoidal(error, period)
        samples = length(error);
        error = error.^2;
        rst = 0;
        
        for k = 2:samples
            rst = rst + (error(k) + error(k-1))*period/2;
        end
    end

    function rst = ITSETrapezoidal(error, period)
        samples = length(error);
        error = error.^2;
        rst = 0;
        
        for k = 2:samples
            rst = rst + (error(k) + error(k-1))*k*period/2;
        end
    end

    function rst = IAETrapezoidal(error, period)
        samples = length(error);
        error = abs(error);
        rst = 0;
        
        for k = 2:samples
            rst = rst + (error(k) + error(k-1))*period/2;
        end
    end

    function rst = ITAETrapezoidal(error, period)
        samples = length(error);
        error = abs(error);
        rst = 0;
        
        for k = 2:samples
            rst = rst + (error(k) + error(k-1))*k*period/2;
        end
    end
end