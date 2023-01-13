classdef RepositoryFactory
    methods (Static)
        function product = create(object)
            switch class(object)
                case 'IWavelet'
                    product = IFunctionRepository(object.wavelet);
            end
        end
    end
end