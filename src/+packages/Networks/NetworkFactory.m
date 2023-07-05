% This class represents a "Factory" of neural networks and needs the
% NetworkList class.
classdef NetworkFactory
    methods (Static)
        % Calls a specific implementation of controller.
        %
        %   @params {NetworkList} nnType Indicates the neural network
        %                                to implements.
        %   @returns {Network} product Indicates the object created by the factory.
        %
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