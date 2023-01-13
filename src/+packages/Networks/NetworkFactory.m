classdef NetworkFactory
    methods (Static)
        function product = create(type)
            switch type
                case NetworkList.Wavenet
                    product = IWavenetScheme();
                case NetworkList.ActorCritic
                    product = IActorCriticScheme();
            end
        end
    end
end