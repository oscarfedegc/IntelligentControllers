classdef RepositoryFactory
    methods (Static)
        function product = create(type)
            switch type
                case NetworkList.WavenetIIR
                    product = IRepositoryWNETIIRPMR();
                case NetworkList.Wavenet
                    product = IRepositoryWNETPMR();
            end
        end
    end
end