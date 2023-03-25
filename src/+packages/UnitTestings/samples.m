function samples
    close, clc

    folder = 'src\+repositories\results\WAVENET-IIR PMR\';

    aFunction = 'POLYWOG3-J06-M04-N02-L05-T0060-X';
    T = readtable([folder aFunction '\' aFunction ' PERFCONTROLLER PITCH.csv']);
    ref1 = getRef(T);
    ref1(:,2) = ref1(:,2) + 12.5;

    aFunction = 'POLYWOG3-J06-M04-N02-L05-T0060-X';
    T = readtable([folder aFunction '\' aFunction ' PERFCONTROLLER YAW.csv']);
    ref2 = getRef(T);
    ref2(:,2) = ref2(:,2) - 4;
    
    P = array2table(ref1);
    Y = array2table(ref2);
    
    writetable(P, [folder aFunction '\' aFunction ' PERFCONTROLLER PITCH.csv']);
    writetable(Y, [folder aFunction '\' aFunction ' PERFCONTROLLER YAW.csv']);
    

%     MAEPOLYWOG3 = getMAE(T);
%
%     aFunction = 'FLATTOP4-J06-M04-N02-L05-T0100-X';
%     T = readtable([folder aFunction '\' aFunction ' PERFMODEL.csv']);
%     MAEFLATTOP4 = getMAE(T);
%
%     aFunction = 'FLATTOP5-J06-M04-N02-L05-T0100-X';
%     T = readtable([folder aFunction '\' aFunction ' PERFMODEL.csv']);
%     MAEFLATTOP5 = getMAE(T);

% figure
% plot(ref1(:,1),ref1(:,2))
% figure
% plot(ref2(:,1),ref2(:,2))
%     plot(MAEFLATTOP4)
%     plot(MAEFLATTOP5)
%     legend('P3', 'FT4', 'FT5')
%
%     sum(MAEPOLYWOG3)
%     sum(MAEFLATTOP4)
%     sum(MAEFLATTOP5)

    function MAE = getMAE(T)
        A = table2array(T);
        [n,~] = size(A);
        MAE = zeros(n,1);
        
        data = A(:,10:11);
        items = 2;
        
        for iter = 1:n
            for item = 1:items
                MAE(iter) = MAE(iter) + abs(data(iter,item));
            end
        end
    end

    function ref = getRef(T)
        A = table2array(T);
        ref = A;
    end
end