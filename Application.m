% This is the main class that calls the other classes and generates the simulations
classdef Application < handle
    methods (Access = public)
        % The constructor of the Application class.
        %
        %   @returns {object} self Instantiation of the class.
        %
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
            addpath ('src/+packages/UnitTestings')

            % Instance the algorithm
            algorithm = Algorithm();
            
            % Changes the algorithm to use.
            %   NOTE: The user can implement new classes for new control strategies.
            % SINTAX: algorithm.setAlgorithm(nameClass())
            algorithm.setAlgorithm(IWIIRPMR())
            
            % Simulation setup
            algorithm.setup()
            
            % Creates objects for model, controllers, neural networks, and trajectories
            algorithm.builder()
            
            % Executes the algorithm
            algorithm.execute()
            
            % Writes the simulations results to CSV files
            algorithm.writeCSV()

            % Shows the simulation results in graphs
            algorithm.charts()
        end
    end
end