% This is the main class that calls the other classes and generates the simulations
classdef Application < handle
    methods (Access = public)
        %{
        %   @returns {object} self Instantiation of the class.
        %}
        function self = Application()
            clc, close all, format short
            
            % Load the packages            
            addpath ('src/+packages/Controllers')
            addpath ('src/+packages/Graphics')
            addpath ('src/+packages/Networks')
            addpath ('src/+packages/Networks/Filters')
            addpath ('src/+packages/Networks/Functions')
            addpath ('src/+packages/Plants')
            addpath ('src/+packages/Repositories')
            addpath ('src/+packages/Strategies')
            addpath ('src/+packages/Tools')
            
            % The configuration values given by the user 
            functionType = FunctionList.wavelet;
            selection = WaveletList.morlet;
            
            tFinal = 10;
            period = 5e-3;
            
            pitchReference = [-40 -20 -20 -20 0 0 10 10 0];
            yawReference = [-20 -20 0 0 20 20 0 0];
            initialPositions = [-40 0 0 0];
            
            inputs  = 2;
            outputs = 2;
            neurons = 3;
            coeffsM = 5;
            coeffsN = 4;
            
            % Instance the strategy, building its components and execute the algorithm.
            context = Context();
            
            context.trajectoryBuilder(tFinal, period, pitchReference, yawReference)
            context.modelBuilder(period, initialPositions)
            context.controllerBuilder()
            context.networkBuilder(functionType, selection, neurons, inputs, outputs, ...
                coeffsM, coeffsN)
            context.execute()
        end
    end
end