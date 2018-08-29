### Conffit.sh

Script for parameterizing single molecules using Paramfit. Automatized steps of Paramfit tutorial (http://ambermd.org/tutorials/advanced/tutorial23/index.html) and some other tools.

For help, type:  `./conffit.sh -h` 

### Functionalities

--Generation of conformations in 3 ways:

  **a)** imposing $RANDOM values (-C option, and `$genconf = random` at input - default).
  _$RANDOM generates a **normal** distribuition of values, so, probability of a value appear isn't iqual for all range (gaussian form)_;
  
  **b)** imposing fixed values bettween a specific range (-C option and `$genconf = fixeddt` at input).
  _Ensure values in all desired range, separated by a fixed value, given by (range of parameter to fit / nstructures)_;

  **c)** from running a rigid PES scan in Gaussian (see example of input for gaussian); 


--Run fitting in 2 ways:

  **d)** Fitting with paramfit, after running (in Gaussian) qm_inps generated in steps a) or b) (-F option); 

  **e)** Fitting with paramfit, after running (in Gaussian) a rigid PES scan (-G option);


--Visualise structure quality with Scatterplots (-S option);


--Visualise torsional barrier profile (-T option);
