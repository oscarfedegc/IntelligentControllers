classdef FunctionFactory
    methods (Static)
        function product = create(functionType, functionSelected, neurons)
            switch functionType
                case FunctionList.wavelet
                    product = IWavelet(functionSelected, neurons);
                case FunctionList.window
                    product = IWindow(functionSelected, neurons);
                case FunctionList.atomic
                    product = IAtomic(neurons);
            end
        end
    end
end