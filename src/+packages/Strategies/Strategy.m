classdef Strategy < handle
    methods (Abstract = true)
        trajectoryBuilder();
        modelBuilder();
        controllerBuilder();
        networkBuilder();
        saveResults();
        execute();
    end
end