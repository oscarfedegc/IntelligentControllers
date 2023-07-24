classdef IOptimizer < handle
    methods (Static)
        function [a,b,W,C,D] = GradientDescent(a,b,W,C,D,GDa,GDb,GDW,GDC,GDD,rate)
            a = IOptimizer.ApplyGradientDescent(a, rate(1), GDa);
            b = IOptimizer.ApplyGradientDescent(b, rate(2), GDb);
            W = IOptimizer.ApplyGradientDescent(W, rate(3), GDW);
            C = IOptimizer.ApplyGradientDescent(C, rate(4), GDC);
            D = IOptimizer.ApplyGradientDescent(D, rate(5), GDD);
        end
        
        
    	function rst = ApplyGradientDescent(current, learningRate, gradient)
            rst = current + learningRate.*gradient;
        end
        
        function [newParameter, newMoment, newVector] = ...
                ApplyAdam(parameter, moment, vector, gradient, iteration)
            BETA1 = 0.9;
            BETA2 = 0.999;
            EPSILON = 10e-8;
            ETA = 1e-5;
            
            newMoment = BETA1 .* moment + (1 - BETA1) .* gradient;
            newVector = BETA2 .* vector + (1 - BETA2) .* gradient.^2;
            
            hatMoment = newMoment ./ (1 - BETA1^iteration);
            hatVector = newVector ./ (1 - BETA2^iteration);
            
            newParameter = parameter + ETA.*(hatMoment ./ (sqrt(hatVector) - EPSILON));
        end
    end
end