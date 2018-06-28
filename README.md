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

**Posterior Analysis:**

**+** Visualise structure quality with Scatterplots, using -s option;

files needed: `RES.prmtop`, `RES_valid_structures.mdcrd`, `prms.in`, `energy_qm_RES.dat`

usage: `./conffit.sh -s -r RES [residue name]`

*in verbose mode, the plot will be shown, so **gnuplot** is necessary

**+** Visualise torsional barrier profile, using -t option; 

files needed: `guess.frcmod`, `fitted.frcmod`

usage: `./conffit.sh -t -d c3-c3-c3-hc [dihedral] -g guess.frcmod -p fitted.frcmod`

*in verbose mode, the plot will be shown, so **python** is necessary 

### Conforma (-c option):
Generate conformations for single point QM calculations in Gaussian, starting from a .mol2 and .frcmod (if necessary). For this step, it’s necessary some definitions in conffit.in:

**Parameters to fit** - look carefully to the mol2 file definitions!

*If you have MORE THAN 1 residue, conffit.sh will need modifications in tleap input file for conformers generation!

*if you don't wan't some parameter fitting, remove its section completely!

**usage:** atom TYPES | atom NAMES | range for generation of random conformations | N (terms, only in dihedral case)

*Bonds in Angstrom, angles and dihedral in degrees

*N (terms) is how many sets of barrier, phase and multiplicity are necessary to discribe some dihedral that you wanna fit.

**Example:**

` $bond

c3 J3 | C2 CJ3 | 1.0 2.0 

J3 SI | CJ3 SI | 1.3 2.3 

$endbond `

` $angle

c3 c3 J3 | C1 C2 CJ3 | 90 130 

c3 J3 SI | C2 CJ3 SI | 90 130 

$endangle`

` $dihedral

c3 c3 J3 hc | C1 C2 CJ3 H6 | 0 180 | 1

c3 c3 J3 SI | C1 C2 CJ3 SI | 0 180 | 3

$enddihedral`

*New atom type info for tleap - if you don't need this, remove completely this section!

**Example:**

` $addAT

addAtomTypes {

{ "SI"  "Si" "sp3" }

{ "J3"  "C" "sp3" }

{ "QS"  "O" "sp3" }

{ "QH"  "O" "sp3" }

}

$endaddAT`

*How generate conformations - random or fixeddt

*default is random (you can remove this section)

*with fixeddt, variation of parameter between each conformer will be calculated by: (range of parameter to fit / nstructures)

**Usage:**

`$genconf = fixeddt`

*Number of conformers to generate - value before equal, maintaining spaces

**Usage:**

`$nstruct = 50`

 *Name of force field source, for tleap input - value before equal, maintaining spaces

**Usage:**

`$ff = leaprc.gaff`

 *Energy cutoff (kcal/mol) for bad structures - value before equal, maintaining spaces

**Usage:**

`$encutoff = 2000.0`

 *Info for GAUSSIAN QM inputs - value before equal, maintaining spaces

*other packages will need codification of conffit.in and conffit.sh!

**Usage:**

`$nproc = 2`

`$mem = 256MB`

`$level = PBE1PBE/Def2TZVP`
