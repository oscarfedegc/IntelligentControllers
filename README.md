# Intelligent controllers with WaveNet-IIR

This project implements intelligent controllers using wavelet neural networks (WaveNet) and infinite impulse response (IIR) filters to the positions control of nonlinear models, i.e., 2 Degree-of-Freedom (DoF) Quanser Helicopter model.

**The last update is on November 22th, 2023.**

## Requirement
1. MATLAB R2014 or later.

## Installation
1. Extract the ZIP file (or clone the git repository) somewhere you can easly reach it.
2. Open the 'Application.m' file in MATLAB.
3. Running the class Application from your command window or press the F5 key.

## Control strategies
This project implemented two kind of controllers: the Proportional-Integral-Derivative (PID) and the Proportional Multiresolution (PMR). The code for each is in 'src/+packages/Strategies/', each strategy are described below:

- IClassicalPIDPert.m: Implements a simulation using the classical PID adding disturbances at system's output.
- IWIIRPIDPert.m: Implements a simulation using the WaveNet-IIR PID adding disturbances at system's output.
- IWIIRPMRPert.m: Implements a simulation using the WaveNet-IIR PMR adding disturbances at system's output.

A control strategy is call by 'Application.m' as follows: 
```python
  # Instruction:
    algorithm.setAlgorithm(NameStrategy())

  # Example
    algorithm.setAlgorithm(IWIIRPMRPert()) 
```

Then, running the class Application. 

## License
This code is distributed under MIT LICENSE

## More information
> Author: Oscar Federico Garcia-Castro. \
> Contact by Telegram <https://t.me/oscar_fede>.
