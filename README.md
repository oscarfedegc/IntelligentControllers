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
This project implemented two kind of controllers: the Proportional-Integral-Derivative (PID) and the Proportional Multiresolution (PMR). The strategy codes are in 'src/+packages/Strategies/', and described below:

- IClassicalPIDPert.m: Implements a simulation using the classical PID adding disturbances at system's output.
- IWIIRPIDPert.m: Implements a simulation using the WaveNet-IIR PID adding disturbances at system's output.
- IWIIRPMRPert.m: Implements a simulation using the WaveNet-IIR PMR adding disturbances at system's output.

To configurate a control strategy, there is a 'function setup(self)' in the listings, where you can determinate the simulation time, sampling period, initial controller gains, the WaveNet-IIR configuration, and reference signals.

The 'Application.m' call a control strategy as follows: 
```python
  # Instruction:
    algorithm.setAlgorithm(NameStrategy())

  # Example
    algorithm.setAlgorithm(IWIIRPMRPert()) 
```

Then, running the class Application. If you need create another control strategy, you can copy someone existent and modify.

## License
This code is distributed under MIT LICENSE

## More information
> Author: Oscar Federico Garcia-Castro. \
> Contact by Telegram <https://t.me/oscar_fede>.
