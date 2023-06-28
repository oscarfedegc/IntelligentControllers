import numpy as np
import matplotlib.pyplot as plt

class Plant:
    def __init__(self, init_states, samples, period):
        self.samples = samples
        self.period = period
        self.performance = np.array(np.zeros((samples, 4)))
        self.terms = np.array(np.zeros((samples, 6)))

        self.performance[0] = init_states

    def nonlinear(self, control_signals, iter):
        # Set constants
        m   = 1.3872
        g   = 9.8100
        l   = 0.1860
        Bp  = 0.8000
        By  = 0.3180
        Jp  = 0.0384
        Jy  = 0.0432
        Kpp = 0.2040
        Kyy = 0.0720
        Kyp = 0.0219
        Kpy = 0.0068

        # Current states
        states = self.performance[iter]
        x1 = states[0]
        x2 = states[1]
        x4 = states[3]

        # Differential Equations (Nonlinear model)
        # Representation in state variables
        f1 = -(Bp*x2 + pow(m*(x2*l),2)*np.sin(x1)*np.cos(x1) + m*g*l*np.cos(x1))/(Jp + m*l*l)
        f2 = -(By*x4 + 2*m*np.sin(x1)*np.cos(x1)*x2*x4*l*l)/(Jy + m*pow(l*np.cos(x1),2))

        g11 = Kpp/(Jp + m*l*l)
        g12 = Kpy/(Jp + m*l*l)
        g21 = Kyp/(Jy + m*pow(l*np.cos(x1),2))
        g22 = Kyy/(Jy + m*pow(l*np.cos(x1),2))

        f = np.array([[x2], [f1], [x4], [f2]])
        g = np.array([[0, 0], [g11, g12], [0, 0], [g21, g22]])
        u = np.array(control_signals)

        xdot = np.add(f.transpose(), g.dot(u))
        
        self.performance[iter+1] = self.performance[iter] + self.period*xdot
        self.terms[iter] = [f1, f2, g11, g12, g21, g22]
        
def main():
    time_simulation = 5 # secons
    period = 0.005  # seconds
    samples = round(time_simulation/period)
    init_states = [-0.7, 0, 0, 0]
    signals = np.zeros((samples,2))
    instants = np.zeros((samples,1))

    model = Plant(init_states, samples, period)

    for iter in range(samples-1):
        instants[iter] = iter*period
        pitchCtrl = 10*np.sin(2*iter*period)
        yawCtrl = 5*np.cos(4*iter*period)

        signals[iter] = [pitchCtrl, yawCtrl]

        model.nonlinear(signals[iter], iter)

    fig, axs = plt.subplots(2)
    fig.suptitle('UTHelicopter2DoF')
    axs[0].plot(signals[:,0])
    axs[0].plot(signals[:,1])
    axs[0].set_ylabel('Control signal')
    
    results = model.performance
    
    axs[1].plot(results[:,0])
    axs[1].plot(results[:,3])
    axs[1].set_ylabel('Positions')
    
    fig, axs = plt.subplots(2)
    fig.suptitle('UTHelicopter2DoF - f(x) and g(x)')
    
    terms = model.terms
    
    axs[0].plot(terms[:,0])
    axs[0].plot(terms[:,1])
    axs[0].set_ylabel('f(x)')
    
    axs[1].plot(terms[:,2])
    axs[1].plot(terms[:,3])
    axs[1].plot(terms[:,4])
    axs[1].plot(terms[:,5])
    axs[1].set_ylabel('g(x)')

if __name__ == "__main__":
    main()