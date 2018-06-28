### Conffit.sh v. 1.0

Script for parameterizing single molecules using Paramfit.
Automatized steps of Paramfit tutorial (http://ambermd.org/tutorials/advanced/tutorial23/index.html), avoiding human errors.

### Quick Guide:

Use -v option for verbose mode 

**1st)** Generate conformations with Conforma, using -c option;

files needed: `mol2name.mol2`, `mol2name.frcmod`, `conffit.in`

usage: `./conffit.sh -c -i conffit.in -m mol2name -r RES [residue name] `

**2nd)** Run QM inputs in Gaussian, put outputs in qm_outs directory; 

**3rd)** Run Fitting with -f option;

files needed: `RES.prmtop`, `RES_valid_structures.mdcrd`, `qm_outs/RES*.out`, `conffit.in`

usage: `./conffit.sh -f -i conffit.in -r RES [residue name] `

**4th) +** Visualise structure quality with Scatterplots, using -s option;

files needed: `RES.prmtop`, `RES_valid_structures.mdcrd`, `prms.in`, `energy_qm_RES.dat`

usage: `./conffit.sh -s -r RES [residue name]`

*in verbose mode, the plot will be shown, so **gnuplot** is necessary

**+** Visualise torsional barrier profile, using -t option; 

files needed: `guess.frcmod`, `fitted.frcmod`

usage: `./conffit.sh -t -d c3-c3-c3-hc [dihedral] -g guess.frcmod -p fitted.frcmod`

*in verbose mode, the plot will be shown, so **python** is necessary 




