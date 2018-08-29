#!/usr/bin/env python

import numpy as np
from matplotlib import pyplot as plt

phi = np.linspace(0., 2. * np.pi, num=50)

 # guess
def dihedral_guess(phi, v_barrier=float(1.40), n=float(3), phase=float(0.0), divider=float(9)):
    return v_barrier * (1. + np.cos(n * phi - phase)) / divider

energy_guess = dihedral_guess(phi)



 # fitted
def dihedral_fitted(phi, v_barrier=float(0.1347), n=float(3.0000), phase=float(0.0000), divider=float(1)):
    return v_barrier * (1. + np.cos(n * phi - phase)) / divider

energy_fitted = dihedral_fitted(phi)



phi = np.linspace(0., 2. * np.pi, num=50)
energy_guess = dihedral_guess(phi)
energy_fitted = dihedral_fitted(phi)

plt.plot(phi * 180./ np.pi, energy_guess, 'b--')
plt.plot(phi * 180./ np.pi, energy_fitted, 'r-')
plt.title("Torsion c3-J3-SI-QS")
plt.xlabel('Phi (degrees)')
plt.ylabel('E torsion (Kcal/mol)')
plt.legend(['guess', 'fitted'])

plt.show()
