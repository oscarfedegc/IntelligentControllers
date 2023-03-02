function samples
    close, clc
    
    folder = 'src\+repositories\results\WAVENET-IIR PMR\';
    
    aFunction = 'POLYWOG3-J06-M04-N02-L05-T0060-Y';
    T = readtable([folder aFunction '\' aFunction ' PERFMODEL.csv']);
    ref1 = getRef(T);
    
    filename = [folder 'ref steps.csv'];
    writematrix(ref1, filename)
    
    aFunction = 'POLYWOG3-J06-M04-N02-L05-T0060-X';
    T = readtable([folder aFunction '\' aFunction ' PERFMODEL.csv']);
    ref2 = getRef(T);
    
    filename = [folder 'ref polynomial.csv'];
    writematrix(ref2, filename)

    
%     MAEPOLYWOG3 = getMAE(T);
%     
%     aFunction = 'FLATTOP4-J06-M04-N02-L05-T0100-X';
%     T = readtable([folder aFunction '\' aFunction ' PERFMODEL.csv']);
%     MAEFLATTOP4 = getMAE(T);
%     
%     aFunction = 'FLATTOP5-J06-M04-N02-L05-T0100-X';
%     T = readtable([folder aFunction '\' aFunction ' PERFMODEL.csv']);
%     MAEFLATTOP5 = getMAE(T);
    
    
    plot(ref1(:,1),ref1(:,2),ref1(:,1),ref1(:,3))
    figure
    plot(ref2(:,1),ref2(:,2),ref2(:,1),ref2(:,3))
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
        ref = A(:,1:3);
    end
end