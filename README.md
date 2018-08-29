### Conffit.sh

Script for parameterizing single molecules using Paramfit.

Automatized steps of Paramfit tutorial (http://ambermd.org/tutorials/advanced/tutorial23/index.html) and some other tools.

For help, type:  `./conffit.sh -h` 

### Functionalities

Generation of conformations in 3 ways:

   **a)**imposing $RANDOM values;

  **b)**imposing specific values;

  **c)**from running a rigid PES scan in Gaussian;

Run fitting in 2 ways:

  d)Fitting with paramfit, after running (in Gaussian) qm_inps generated in steps a) or b);

  e)Fitting with paramfit, after running (in Gaussian) a rigid PES scan;

Visualise structure quality with Scatterplots;

Visualise torsional barrier profile, using -T option;
