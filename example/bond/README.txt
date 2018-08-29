#Steps for fitting only Kr of SI-QH bond:

 1) Prepare .mol2, .frcmod and conffit.in files

 2) Generate conformations with Conforma
    Type: ./conffit.sh -Ci conffit.in -m m3 -r bm3

 3) Run in gaussian all inputs in qm_inps/ directory

 4) Put output in qm_outs/ directory

 5) Run fitting in Paramfit
    Type: ./conffit.sh -DVFi conffit.in -r bm3
    you can run it again other times, files will be generated with a crescent index
    Type: cat *rep* (to see results of all runs you did)

 6) Evaluate results
