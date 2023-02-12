classdef NetworkFactory
    methods (Static)
        function product = create(type)
            switch type
                case NetworkList.WavenetIIR
                    product = IWavenetIIRScheme();
                case NetworkList.ActorCriticWavenetIIR
                    product = IActorCriticScheme();
                case NetworkList.Wavenet
                    product = IWavenetScheme();
            end
        end
    end
end