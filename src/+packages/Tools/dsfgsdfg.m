classdef IOptimizer < handle 
    properties
        EPSILON = 1e-8;
        GAMMA = 0.9;
    end
    
    methods (Static)        
        function [newAccumulated, delta] = AdaGrad(nabla, accumulated, epsilon)
            newAccumulated = accumulated + nabla.^2;
            root = sqrt(accumulated + epsilon);
            delta = nabla./root;
        end
        
        function [Phi, Delta, Gamma] = AdaDelta(nabla, alpha, delta, gamma, epsilon)
            newAlpha = gamma*alpha + (1-gamma)*nabla.^2;
            learningRate = sqrt(delta + epsilon) ./ sqrt(alpha + epsilon);
            newDelta_lambda = -nabla .* learningRate;
            newDelta_x = gamma * delta + (1-gamma).*newDelta_lambda.^2;
        end
    end
end