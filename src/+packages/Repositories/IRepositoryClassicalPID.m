classdef IRepositoryClassicalPID < Repository
    properties (Access = public)
        FOLDER;
    end
    
    methods (Access = public)
        function self = IRepositoryClassicalPID(folder)
            self.FOLDER = upper(folder);
            self.isCutOffResults = false;
        end

        function writeConfiguration(~)
            return
        end
        
        function writeModelFiles(self, states)
            instants = self.trajectories.getInstants();
            desired = rad2deg(self.trajectories.getAllReferences());
            measurement = rad2deg(self.model.getPerformance(states));
            trackingError = desired - measurement;
            
            instants = instants(self.indexes);
            desired = desired(self.indexes,:);
            measurement = measurement(self.indexes,:);
            trackingError = trackingError(self.indexes,:);
            
            tags = {'ref', 'mes', 'epsilon'};
            labels = self.model.getLabels();
            
            T = [instants, desired, measurement, trackingError];
            T = array2table(T, 'VariableNames', self.getVarNames(tags, labels));
            
            self.writeParameterFile(T, 'PERFMODEL')
        end
        
        function  writeNeuralNetworkFiles(~)
            return
        end
        
        function writeControllerFiles(self, offsets)
            instants = self.trajectories.getInstants();
            instants = instants(self.indexes);
            labels = self.model.getLabels();
            
            for i = 1:length(self.controllers)
                performance = self.controllers(i).getPerformance();
                performance(self.indexes,1) = offsets(i) + performance(self.indexes,1);
                
                performance(1,1) = 0;
                
                performance = [instants performance(self.indexes,:)];

                self.writeParameterFile(performance, ...
                    upper(sprintf('perfcontroller %s', string(labels(i)))))
            end
        end

        function writeFinalParameters(~)
            return
        end
        
        function [scales, shifts, weights, feedbacks, feedforwards] = readParameters(~)
            scales = [];
            shifts = [];
            weights = [];
            feedbacks = [];
            feedforwards = [];
        end
    end
end