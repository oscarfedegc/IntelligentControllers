classdef AdamTestings < handle    
    methods (Access = public)
        function self = AdamTestings()
            close, clc
            self.run()
        end
        
        function run(self)
            randd = @(a,b,f,c) a + (b-a)*rand(f,c);
            optimizer = IOptimizer();
            
            neurons = 5;
            outputs = 2;
            interval = 0.1;
            
            weights = randd(-interval, interval, outputs, neurons)
            gradient = randd(-5*interval, 5*interval, outputs, neurons)
            moment = zeros(outputs, neurons)
            vector = zeros(outputs, neurons)
            
            for i = 1:25
                disp(i)
                [weights, moment, vector] = optimizer.ApplyAdam(weights, moment, vector, gradient, i)
                pause(0.5)
                clc
            end
        end
    end
end