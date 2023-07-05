classdef UTGradients < matlab.unittest.TestCase
    properties
        TestNeuralNetwork
        instant, inputSignals
    end

    methods (TestMethodSetup)
        function createNeuralNetwork(testCase)            
            % Wavenet-IIR configuration
            nnaType = NetworkList.WavenetIIR;
            functionType = FunctionList.wavelet;
            functionSelected = WaveletList.morlet;
            
            inputs = 2;
            outputs = 2;
            amountFunctions = 6;
            feedbacks = 4;
            feedforwards = 3;
            persistentSignal = 1;
            
            learningRates = [10e-5 10e-5 5e-6 5e-1 5e-2];
            rangeSynapticWeights = 0.1;
            
            samples = 12000;
            
            % Deta from LabVIEW
            scales = [1 1 1 1 1 1];
            shifts = [1 2 3 4 5 6];
            weights = [1 2; 3 4; 5 6; 7 8; 9 10; 11 12];
            initFeedbacks =  [1 2; 3 4; 5 6; 7 8];
            initForwards = [1 2; 3 4; 5 6];
            
            % Building the Wavenet-IIR
            neuralNetwork = NetworkFactory.create(nnaType);
            neuralNetwork.setSynapticRange(rangeSynapticWeights)
            neuralNetwork.buildNeuronLayer(functionType, functionSelected, ...
                amountFunctions, inputs, outputs)
            neuralNetwork.buildFilterLayer(inputs, outputs, feedbacks, ...
                feedforwards, persistentSignal)
            neuralNetwork.setLearningRates(learningRates)
            neuralNetwork.bootInternalMemory()
            neuralNetwork.bootPerformance(samples)
            neuralNetwork.setStatus(true)
            
            neuralNetwork.setInitialValues(scales, shifts, weights, ...
                initFeedbacks, initForwards)
            
            % Save the instance
            testCase.TestNeuralNetwork = neuralNetwork;
            testCase.instant = 3.005;
            testCase.inputSignals = 8.792;
        end
    end

    methods (Test)
        function defaultTauParameter(testCase)
            % Data from LabVIEW
            tau = [1.000 0.600 0.200 -0.200 -0.600 -1.000];
            
            [tau_, ~, ~] = testCase.TestNeuralNetwork.getTau([0 testCase.inputSignals], ...
                testCase.instant);
            
            testCase.verifyEqual(tau,round(tau_,3))
        end
        
        function defaultWavelet(testCase)
            % Data from LabVIEW
            wavelet = [0.532 0.798 0.975 0.975 0.798 0.532];
            
            [~, wavelet_, ~] = testCase.TestNeuralNetwork.getTau([0 testCase.inputSignals], ...
                testCase.instant);
            
            testCase.verifyEqual(wavelet,round(wavelet_,3))
        end
        
        function defaultGradients(testCase)
            [~, ~, ~] = testCase.TestNeuralNetwork.getTau([0 testCase.inputSignals], ...
                testCase.instant);
            
            [GradientW, Gradienta, Gradientb, GradientC, GradientD] = ...
                testCase.TestNeuralNetwork.getGradients(...
                testCase.inputSignals, [-0.36 -0.58])
        end
    end
end