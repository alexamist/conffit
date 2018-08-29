### Conffit.sh

Script for parameterizing single molecules using Paramfit. Automatized steps of Paramfit tutorial (http://ambermd.org/tutorials/advanced/tutorial23/index.html) and some other tools.

For help, type:  `./conffit.sh -h` 

### Functionalities

--Generation of conformations in 3 ways:

  **a)** imposing $RANDOM values (-C option, and `$genconf = random` at input - default);

  **b)** imposing specific values (-C option and `$genconf = fixeddt` at input); 

  **c)** from running a rigid PES scan in Gaussian (see example of input for gaussian); 


--Run fitting in 2 ways:

  **d)** Fitting with paramfit, after running (in Gaussian) qm_inps generated in steps a) or b) (-F option); 

  **e)** Fitting with paramfit, after running (in Gaussian) a rigid PES scan (-G option);


--Visualise structure quality with Scatterplots (-S option);


--Visualise torsional barrier profile (-T option);
