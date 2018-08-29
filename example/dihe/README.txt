#Steps for fitting only Kp of c3-J3-SI-QS torsion angle:

 1) Prepare .mol2, .frcmod and conffit.in files

 2) Generate conformations with Conforma
    Type: ./conffit.sh -Ci conffit.in -m m3 -r d23

 3) Run in gaussian all inputs in qm_inps/ directory

 4) Put output in qm_outs/ directory

 5) Run fitting in Paramfit
    Type: ./conffit.sh -DVFi conffit.in -r d23
    you can run it again other times, files will be generated with a crescent index
    Type: cat *rep* (to see results of all runs you did)

 6) Evaluate results

 7) Print potential energy profile, comparing guess parameters and fitted ones
    Type: ./conffit.sh -VTd c3-J3-SI-QS -g m3.frcmod -p fit_1_d23.frcmod 
    *with V option, python is needed
