#!/bin/bash

# conffit.sh [v. 1.0] - written by Alechania Misturini [may/2018]
  # ./conffit.sh -h for help

#-------------
 # colors
RED='\033[1;31m'
NC='\033[0m'
BLUE='\033[1;34m'
GREEN='\033[1;32m'
MAG='\033[1;35m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
GRAY='\033[1;37m'
UND='\e[4m'
NUND='\e[24m'

 # pause
function pause(){
   read -p "$*"
}

 # defining flags and options
while getopts "VDCFSTGhi:m:r:d:g:p:" option;
do
 case $option in
  V)
   verbose=1
   ;;
  D)
   direct=1
   ;;
  C)
   conforma=1
   ;;
  F)
   fitting=1
   ;;
  S)
   scatterplots=1
   ;;
  T)
   plotdihe=1
   ;;
  G)
   gausscan=1
   ;;
  h)
   echo -e "${RED}     Help conffit.sh:"
   echo -e "${BLUE}      Use -V option for verbose mode${NC}"
   echo -e "${BLUE}      Use -D option for direct mode${NC} \n"

   echo -e "${GRAY}1st) ${RED}Generate conformations with Conforma, using -C option;${NC}"
   echo -e "${GRAY}      files needed:${YELLOW} mol2name.mol2, mol2name.frcmod, conffit.in ${NC}"
   echo -e "${GRAY}      usage: ${BLUE}./conffit.sh -C -i conffit.in -m mol2name -r RES [residue name] ${NC}"
   echo -e "${GRAY}  Or:${NC}"
   echo -e "${GRAY}     ${RED}Generate conformations running a rigid PES scan in Gaussian;${NC}"
   echo -e "${GRAY}      see example in ${UND}github.com/alexamist/conffit${NUND} \n${NC}"

   echo -e "${GRAY}2nd) ${RED}Run QM inputs in Gaussian, put outputs in qm_outs directory;${NC} \n"

   echo -e "${GRAY}3rd) ${RED}Run Fitting with -F option;${NC}"
   echo -e "${GRAY}      files needed:${YELLOW} RES.prmtop, RES_valid_structures.mdcrd, qm_outs/RES*.out, conffit.in ${NC}"
   echo -e "${GRAY}      usage: ${BLUE}./conffit.sh -F -i conffit.in -r RES [residue name] ${NC}"
   echo -e "${GRAY}  Or:${NC}"
   echo -e "${GRAY}     ${RED}Run Gausscan with -G option;${NC}"
   echo -e "${GRAY}      files needed:${YELLOW} mol2name.mol2, mol2name.frcmod, conffit.in, RES_scan.out [out of rigid PES scan] ${NC}"
   echo -e "${GRAY}      usage: ${BLUE}./conffit.sh -G -i conffit.in -m mol2name -r RES [residue name] ${NC}"
   echo -e "${GRAY}     *obabel is necessary \n${NC}"

   echo -e "${GRAY}4th) ${RED}Visualise structure quality with Scatterplots, using -S option; ${NC}"
   echo -e "${GRAY}      files needed:${YELLOW} RES.prmtop, RES_valid_structures.mdcrd, prms.in, energy_qm_RES.dat ${NC}"
   echo -e "${GRAY}      usage: ${BLUE}./conffit.sh -S -r RES [residue name] ${NC}"
   echo -e "${GRAY}     *in verbose mode, the plot will be shown, so gnuplot is necessary \n${NC}"

   echo -e "${GRAY}     ${RED}Visualise torsional barrier profile, using -T option; ${NC}"
   echo -e "${GRAY}      files needed:${YELLOW} guess.frcmod, fitted.frcmod ${NC}"
   echo -e "${GRAY}      usage: ${BLUE}./conffit.sh -T -d c3-c3-c3-hc [dihedral] -g guess.frcmod -p fitted.frcmod ${NC}"
   echo -e "${GRAY}     *in verbose mode, the plot will be shown, so python is necessary \n${NC}"

   exit
   ;;
  i)
   input=$OPTARG
   ;;
  m)
   mol2name=$OPTARG
   ;;
  r)
   resname=$OPTARG
   ;;
  d)
   pdihe=$OPTARG
   ;;
  g)
   guess=$OPTARG
   ;;
  p)
   fitted=$OPTARG
   ;;
 :)
   echo -e "${RED}Type ./${version} -h for help.${NC}"; exit
   ;;
  *)
   echo -e "${RED}Type ./${version} -h for help.${NC}"; exit
   ;;
 esac
done

#------------- defining conforma
function conforma(){

 # checking for needed options
if [ -n "${input}" ]; then
  if [ -n "${mol2name}" ]; then
    if [ -n "${resname}" ]; then
    echo -e "${CYAN}Running Conforma!${NC}"
    else
    echo -e "${RED}Define -r option! Type ./${version} -h for help.${NC}" ; exit
    fi
  else
  echo -e "${RED}Define -m option! Type ./${version} -h for help.${NC}" ; exit
  fi
else
echo -e "${RED}Define -i option! Type ./${version} -h for help.${NC}" ; exit
fi

 # making sure there is no intermediary files from previous attempts
if [ -a 'add' ]; then rm add ; fi
if [ -a 'varimp2' ]; then rm add ; fi
if [ -a 'impose' ]; then rm impose ; fi
if [ -a "leap*" ]; then rm leap* ; fi
if [ -a 'random' ]; then rm random ; fi
if [ -a 'bond' ]; then rm bond ; fi
if [ -a 'angle' ]; then rm angle ; fi
if [ -a 'dihe' ]; then rm dihe ; fi
if [ -a 'gaussian.header' ]; then rm gaussian.header ; fi
if [ -a 'gen_mdcrd.traj' ]; then rm gen_mdcrd.traj ; fi
if [ -a 'job.in' ]; then rm job.in ; fi
if [ -a 'dummy.dat' ]; then rm dummy.dat ; fi
if [[ -d ./amber_inps ]]; then rm -rf ./amber_inps ; fi
if [[ -d ./qm_inps ]]; then rm -rf ./qm_inps ; fi

 # make molecule.prmtop and .crd
echo -e "${GRAY}*Generating system topology and coordinates...${NC}"

ff=$(grep '$ff' ${input} | awk '{print $3}')

   # tleap input file generation
cat > leap.in << EOF
source ${ff}
${resname} = loadmol2 ${mol2name}.mol2
loadamberparams ${mol2name}.frcmod
saveamberparm ${resname} ${mol2name}.prmtop ${mol2name}.inpcrd
quit
EOF

   #addition of new atom types
awk '/\$addAT/{flag=1;next}/\$endaddAT/{flag=0}flag' ${input} > add

if [ -z "$(cat add)" ]
then
  echo -e "${YELLOW}you don't added new atom types!${NC}"
else
  sed -i "/source/r add" leap.in
fi

 # generate conformations
echo -e "${GRAY}*Generating conformations...${NC}"

if [[ ! -d ./amber_inps ]]; then
  mkdir ./amber_inps
fi

nstruct=$(grep '$nstruct' ${input} | awk '{print $3}')

awk '/\$bond/{flag=1;next}/\$endbond/{flag=0}flag' ${input} | awk '{ $9 = $8 - $7 } 1' | awk '{print "bond" NR " " $0}' | awk '{ $11 = $10 / '"$nstruct"' } 1' > bond
awk '/\$angle/{flag=1;next}/\$endangle/{flag=0}flag' ${input} | awk '{ $11 = $10 - $9 } 1' | awk '{print "angle" NR " " $0}' | awk '{ $13 = $12 / '"$nstruct"' } 1' > angle
awk '/\$dihedral/{flag=1;next}/\$enddihedral/{flag=0}flag' ${input} | awk '{ $13 = $12 - $11 } 1' | awk '{print "dihe" NR " " $0}' | awk '{ $16 = $14 / '"$nstruct"' } 1' > dihe

genconf=$(grep '$genconf' ${input} | awk '{print $3}')

if [ "$(grep '$genconf' ${input} | wc -l)" = 0 ] || [ "$(grep '$genconf' ${input} | awk '{print $3}')" = "random" ]; then
  if [ -z "$(cat bond)" ]
  then
    echo -e "${YELLOW}you don't wanna fit any bond parameter!${NC}"
  else
    awk '{print $1"=$( echo \"scale=4; " $8"+$RANDOM/32767*"$10"\" | bc ) # bond between "$8" and " $9" Angstrom"}' bond > random
    awk '{print "impose ${resname} {1}, { {\""$5"\" \""$6"\" ${"$1"}} }"}' bond > impose
  fi
  if [ -z "$(cat angle)" ]
  then
    echo -e "${YELLOW}you don't wanna fit any angle parameter!${NC}"
  else
    awk '{print $1"=$( echo \"scale=4; " $10"+$RANDOM/32767*"$12"\" | bc ) # angle between "$10" and " $11" degrees"}' angle >> random
    awk '{print "impose ${resname} {1}, { {\""$6"\" \""$7"\" \""$8"\" ${"$1"}} }"}' angle >> impose
  fi
  if [ -z "$(cat dihe)" ]
  then
    echo -e "${YELLOW}you don't wanna fit any dihedral parameter!${NC}"
  else
    awk '{print $1"=$( echo \"scale=4; " $12"+$RANDOM/32767*"$14"\" | bc ) # dihedral between "$12" and " $13" degrees"}' dihe >> random
    awk '{print "impose ${resname} {1}, { {\""$7"\" \""$8"\" \""$9"\" \""$10"\" ${"$1"}} }"}' dihe >> impose
  fi

sed '/saveamberparm/d' leap.in > leap2.in
sed -i "/loadamberparams/a saveamberparm \$\{resname\} \$\{resname\}.prmtop \"amber_inps\/\$\{resname\}_struc_\$\{idx\}.mdcrd\" " leap2.in
sed -i "/loadamberparams/r impose" leap2.in
sed -i 's/\"/\\"/g' leap2.in

echo "\$idx" > varimp
grep 'bond' impose | awk '{print $7}'| sed 's/}}/}/g' >> varimp
grep 'angle' impose | awk '{print $8}'| sed 's/}}/}/g' >> varimp
grep 'dihe' impose | awk '{print $9}'| sed 's/}}/}/g' >> varimp
cat varimp | tr '\n' ' ' > varimp2 ; echo -en '\n' >> varimp2 ; rm varimp
cat varimp2 > values.dat

   # generate tleap input file of conformations
echo -e "${MAG}This step may take a while, please wait...${NC}"

  idx=0
  for ((idx=0; idx<$nstruct; idx++)); do
    source random

    template="$(cat leap2.in)"
    eval "echo \"${template}\" > leap3.in"

   # run tleap for conformations
    tleap -f leap3.in  2&> /dev/null
    echo "trajin amber_inps/${resname}_struc_${idx}.mdcrd" >> gen_mdcrd.traj

    varimp="$(cat varimp2)"
    eval "echo \"${varimp}\" >> values.dat"
  done
  sed -e 's/\$//g' -e 's/{//g' -e 's/}//g' values.dat > values.tmp
  cat values.tmp | column -t > values.dat ; rm values.tmp
else
  if [ "$(grep '$genconf' ${input} | awk '{print $3}')" = "fixeddt" ]; then
    if [ -z "$(cat bond)" ]
    then
      echo -e "${YELLOW}you don't wanna fit any bond parameter!${NC}"
    else
      awk '{print $1"=$( echo \"scale=4; " $8"+"$11"*$ndx\" | bc )"}' bond > random
      awk '{print "impose ${resname} {1}, { {\""$5"\" \""$6"\" ${"$1"}} }"}' bond > impose
    fi
    if [ -z "$(cat angle)" ]
    then
      echo -e "${YELLOW}you don't wanna fit any angle parameter!${NC}"
    else
      awk '{print $1"=$( echo \"scale=4; " $10"+"$13"*$ndx\" | bc )"}' angle >> random
      awk '{print "impose ${resname} {1}, { {\""$6"\" \""$7"\" \""$8"\" ${"$1"}} }"}' angle >> impose
    fi
    if [ -z "$(cat dihe)" ]
    then
      echo -e "${YELLOW}you don't wanna fit any dihedral parameter!${NC}"
    else
      awk '{print $1"=$( echo \"scale=4; " $12"+"$16"*$ndx\" | bc )"}' dihe >> random
      awk '{print "impose ${resname} {1}, { {\""$7"\" \""$8"\" \""$9"\" \""$10"\" ${"$1"}} }"}' dihe >> impose
    fi

sed '/saveamberparm/d' leap.in > leap2.in
sed -i "/loadamberparams/a saveamberparm \$\{resname\} \$\{resname\}.prmtop \"amber_inps\/\$\{resname\}_struc_\$\{idx\}.mdcrd\" " leap2.in
sed -i "/loadamberparams/r impose" leap2.in
sed -i 's/\"/\\"/g' leap2.in

echo "\$idx" > varimp
grep 'bond' impose | awk '{print $7}'| sed 's/}}/}/g' >> varimp
grep 'angle' impose | awk '{print $8}'| sed 's/}}/}/g' >> varimp
grep 'dihe' impose | awk '{print $9}'| sed 's/}}/}/g' >> varimp
cat varimp | tr '\n' ' ' > varimp2 ; echo -en '\n' >> varimp2 ; rm varimp
cat varimp2 > values.dat

   # generate tleap input file of conformations
echo -e "${MAG}This step may take a while, please wait...${NC}"

    idx=0
    for ((idx=0; idx<$nstruct; idx++)); do
    ndx=$((${idx} + 1))
    source random

    template="$(cat leap2.in)"
    eval "echo \"${template}\" > leap3.in"

   # run tleap for conformations
    tleap -f leap3.in  2&> /dev/null
    echo "trajin amber_inps/${resname}_struc_${idx}.mdcrd" >> gen_mdcrd.traj

    varimp="$(cat varimp2)"
    eval "echo \"${varimp}\" >> values.dat"
    done
    sed -e 's/\$//g' -e 's/{//g' -e 's/}//g' values.dat > values.tmp
    cat values.tmp | column -t > values.dat ; rm values.tmp
  fi
fi

#---------------------------------

   # collate all structures into a single trajectory file
echo "trajout ${resname}_all_structures.mdcrd" >> gen_mdcrd.traj
echo "go" >> gen_mdcrd.traj
cpptraj -p ${resname}.prmtop < gen_mdcrd.traj > /dev/null

rm gen_mdcrd.traj

echo -e "${BLUE}Successfully put $idx structures in ${resname}_all_structures.mdcrd${NC}"

 # clean up bad structures
echo -e "${GRAY}*Cleaning up bad conformations...${NC}"

echo -e "${MAG}This step may take a while, please wait...${NC}"

prmtop=${resname}.prmtop
encutoff=$(grep '$encutoff' ${input} | awk '{print $3}')

echo "0.000" > dummy.dat
cat > job.in << EOF
ALGORITHM=NONE
NSTRUCTURES=1
COORDINATE_FORMAT=RESTART
EOF
echo > gen_mdcrd.traj

good=0
for ((idx=0; idx<$nstruct; idx++)); do
  en=$(paramfit -i job.in -p $prmtop -c amber_inps/${resname}_struc_${idx}.mdcrd -q dummy.dat | grep "Calculated energy with initial parameters" | awk '{print $10'})
    if [[ $(echo "$en<${encutoff}" | bc -l) -eq 1 ]]; then
      echo "${resname}_struc_${idx}.mdcrd" >> ${resname}_valid_structures.dat
      echo "trajin amber_inps/${resname}_struc_${idx}.mdcrd" >> gen_mdcrd.traj
      (( good++ ))
    fi
done

echo "trajout ${resname}_valid_structures.mdcrd" >> gen_mdcrd.traj
echo "go" >> gen_mdcrd.traj
cpptraj -p $prmtop < gen_mdcrd.traj > /dev/null

rm job.in
rm dummy.dat
rm gen_mdcrd.traj

echo -e "${BLUE}Wrote $good structures to ${resname}_valid_structures.dat${NC}"

 # generate QM single poit inputs for gaussian
echo -e "${GRAY}*Generating QM single point inputs for Gaussian...${NC}"

cat > paramfit_qm_inp.in << EOF
  # use the first ${good} structures in the input trajectory format file
NSTRUCTURES=${good}
COORDINATE_FORMAT=TRAJECTORY
  # we want to create quantum input files for the Gaussian package
RUNTYPE=CREATE_INPUT
QMFILEFORMAT=GAUSSIAN
  # before the coordinates section in the input file, prepend the text in
  # gaussian.header, which will specify the run options
QMHEADER=gaussian.header
  # name the files qm_inps/${resname}###.gjf
QMFILEOUTSTART=qm_inps/${resname}
QMFILEOUTEND=.gjf
EOF


   # generate dir for inps
if [[ ! -d ./qm_inps ]]; then
  mkdir ./qm_inps
fi

   # generate dir for outs
if [[ ! -d ./qm_outs ]]; then
  mkdir ./qm_outs
fi

nproc=$(grep '$nproc' ${input} | awk '{print $3}')
mem=$(grep '$mem' ${input} | awk '{print $3}')
level=$(grep '$level' ${input} | awk '{print $3}')

   # make gaussian.header for inps
cat > gaussian.header << EOF
%nproc=${nproc}
%mem=${mem}
%RWF=${resname}.rwf
%chk=${resname}.chk
%NoSave
#SP ${level} geom=connectivity
EOF

 # run paramfit to get qm-inps
if [ "${verbose}" = "1" ]; then
paramfit -i paramfit_qm_inp.in -p ${resname}.prmtop -c ${resname}_valid_structures.mdcrd | tee paramfit_qm_inp.out
else
paramfit -i paramfit_qm_inp.in -p ${resname}.prmtop -c ${resname}_valid_structures.mdcrd > paramfit_qm_inp.out
cat paramfit_qm_inp.out
fi

 # save some files in amber_inps for checking conformers generation
mv leap* amber_inps
mv ${resname}_all_structures.mdcrd amber_inps/
mv ${resname}_valid_structures.dat amber_inps/
mv values.dat amber_inps/
cp ${resname}_valid_structures.mdcrd amber_inps/

 # clean up intermediary files
rm add
rm varimp2
rm impose
rm random
if [ -a 'bond' ]; then rm bond ; fi
if [ -a 'angle' ]; then rm angle ; fi
if [ -a 'dihe' ]; then rm dihe ; fi
if [ -a 'confdihe' ]; then rm confdihe ; fi
rm gaussian.header

laststuct=$(( ${good} - 1 ))
differ=$(diff qm_inps/${resname}0.gjf qm_inps/${resname}${laststuct}.gjf|wc -l)
diffmin=4

if [[ "${differ}" < "${diffmin}" ]] || [[ "${differ}" = "${diffmin}" ]] ; then
  echo -e "${RED}WARNING! Conformations generated by LEaP are all equal, i.e., impose doesn't worked in the parameter you are trying to fit! Check input informations, atom names/types, etc.${NC}"
else
  echo -e "${RED}If it's all ok, run this single-points in Gaussian, put .out at qm_out directory, and then use -f option for fitting!${NC}"
fi

}
#-------------- end conforma

#-------------- define fitting
function fitting(){

 # checking for needed options
if [ -n "${input}" ]; then
  if [ -n "${resname}" ]; then
  echo -e "${CYAN}Running Fitting!${NC}"
  else
  echo -e "${RED}Define -r option! Type ./${version} -h for help.${NC}" ; exit
  fi
else
echo -e "${RED}Define -i option! Type ./${version} -h for help.${NC}" ; exit
fi

 # making sure there is no intermediary files from previous attempts
if [ -a 'nconfs.dat' ]; then rm nconfs.dat ; fi
if [ -a 'prmdihe' ]; then rm prmdihe ; fi
if [ -a 'tmpdihe' ]; then rm tmpdihe ; fi
if [ -a 'prms.in' ]; then rm prms.in ; fi
if [ -a 'job_fit.in' ]; then rm job_fit.in ; fi
if [ -a "energy_qm_${resname}.dat" ]; then rm "energy_qm_${resname}.dat" ; fi

 # for another attempt
if [ -a "${resname}_valid_structures.mdcrd.bak" ]; then rm ${resname}_valid_structures.mdcrd ; mv ${resname}_valid_structures.mdcrd.bak ${resname}_valid_structures.mdcrd ; fi


 # variables
mdcrd="${resname}_valid_structures.mdcrd"
outdir=qm_outs  # defined in conforma.sh
offset=1 # n of lines that aren't strucures in mdcrd (first one)
natom=$(grep -A 2 "%FLAG POINTERS" ${resname}.prmtop | tail -n 1 | awk '{print $1}')
nlines=$(echo "a=${natom}*3; b=10; if ( a%b ) a/b+1 else a/b" | bc) # n of lines for each structure in mdcrd

 # check structures in mdcrd file
echo -e "${GRAY}*Checking structures in .mdcrd file...${NC}"

nl=$(cat ${mdcrd} | wc -l)
a=$(( ( ${nl} - ${offset} ) / ${nlines} ))
echo -e "Your ${mdcrd} has ${RED}${UND}${a}${NUND}${NC} structures!"

 # make a backup of mdcrd file
cp ${mdcrd} ${mdcrd}.bak

 # set nconfs with error
grep "Error termination" ${outdir}/*.out | awk '{print $1}' | sed -e "s/${outdir}\/${resname}//g" | sed -e "s/.out://g" > nconfs.dat

sort -r -k1 -n nconfs.dat > nconfs # sort ndx in descending order

rm nconfs.dat

 # delete bad structures in mdcrd file
echo -e "${GRAY}*Removing bad structures from mdcrd file...${NC}"
echo -e "${MAG}This step may take a while, please wait.${NC}"

for nconf in $(cat nconfs)
  do ndx=$(( ${nconf} + 1 )) # correct index structure (cause starts in 0)
     xb=$(( ( ${ndx} * ${nlines} ) + 1 ))
     xa=$(( ${xb} - ( ${nlines} - 1) ))
     sed -i -e "${xa},${xb}d" ${mdcrd}
done

 # check mdcrd file
nlold=$(cat ${mdcrd}.bak | wc -l)
sold=$(( ( ${nlold} - ${offset} ) / ${nlines} ))

nlnew=$(cat ${mdcrd} | wc -l)
snew=$(( ( ${nlnew} - ${offset} ) / ${nlines} ))

echo -e "Old .mdcrd has ${UND}${RED}${sold}${NC}${NUND} structures!"
echo -e "New .mdcrd has ${UND}${RED}${snew}${NC}${NUND} structures!"

sconfs=$(cat nconfs | wc -l)

diff=$(( ${sold} - ${snew} ))

echo -e "${MAG}You tried to remove ${UND}${sconfs}${NUND} structures? Cause new .mdcrd has ${UND}${diff}${NUND} strucures less.${NC}"

if [ "${direct}" != "1" ]; then
pause $(echo -e "${BLUE}*If this step is ok, press [Enter] key to continue...${NC}")
fi

rm nconfs

 # extract energies from .out (gaussian single points)

for ((i=0;i<${sold};i++)); do
#  echo $i
  grep "SCF Done" "${outdir}/${resname}${i}.out" | awk '{print $5}' \
   >> energy_qm_${resname}.dat
done

nenergy=$(cat energy_qm_${resname}.dat | wc -l)

echo -e "You have ${RED}${UND}${nenergy}${NUND}${NC} energy values, and ${RED}${UND}${snew}${NUND}${NC} structures."

if [ "${direct}" != "1" ]; then
pause $(echo -e "${BLUE}*If this step is ok, press [Enter] key to continue...${NC}")
fi

 # make .in for fit K
cat > fitK_${resname}.in <<EOF
# Use the first ${snew} structures of the input trajectory
NSTRUCTURES=${snew}
COORDINATE_FORMAT=TRAJECTORY
# We want to fit the K parameter
RUNTYPE=FIT
PARAMETERS_TO_FIT=K_ONLY
# Fit to quantum energies that are in units of Hartree
FUNC_TO_FIT=SUM_SQUARES_AMBER_STANDARD
QM_ENERGY_UNITS=HARTREE
EOF

echo -e "${GRAY}*Fitting K...${NC}"
echo -e "${MAG}This step may take a while, please wait.${NC}"

 # fitting K
if [ "${verbose}" = "1" ]; then
paramfit -i fitK_${resname}.in -p ${resname}.prmtop -c ${mdcrd} -q energy_qm_${resname}.dat | tee fitK_${resname}.out
else
paramfit -i fitK_${resname}.in -p ${resname}.prmtop -c ${mdcrd} -q energy_qm_${resname}.dat > fitK_${resname}.out
fi

echo -e "${GRAY}*Simplified report of K fitting... (fitK.txt)${NC}"
echo "   ----------------------------------------------------------------------------------" > fitK.txt
awk '/FINAL PARAMETERS/ {p=1}; p; /kcal\/mol/ {p=0}' fitK_${resname}.out | grep "K = " | awk '{print "     " $1, $2, $3, $4}' >> fitK.txt
awk '/FINAL PARAMETERS/{flag=1;next}/Calculated energy with fitted/{flag=0}flag' fitK_${resname}.out | grep "R^2" |awk '{print "     " $8, $9, $10}' >> fitK.txt
echo "   ----------------------------------------------------------------------------------" >> fitK.txt
cat fitK.txt

 # generate prms.in
fitoptions=$( awk '/\$fitting/{flag=1;next}/\$endfitting/{flag=0}flag' ${input} )

cat > prms.in << EOF
#V2 AUTO-GENERATED PARAMETER FILE - DO NOT MODIFY
#
# BOND INFORMATION:
#### BOND       REQ     KR ####
EOF

if [ -n "$( awk '/\$bond/{flag=1;next}/\$endbond/{flag=0}flag' ${input} )" ]; then

  if [ -z "${fitoptions}" ]; then parb=$(echo "1 1")
  else
    if [ -n "$(echo ${fitoptions} | grep 'REQ')" ] ; then
      if [ -n "$(echo ${fitoptions} | grep 'KR')" ] ; then parb=$(echo "1 1")
      else
      parb=$(echo "1 0")
      fi
    else
      if [ -n "$(echo ${fitoptions} | grep 'KR')" ] ; then parb=$(echo "0 1")
      fi
    fi
  fi

awk '/\$bond/{flag=1;next}/\$endbond/{flag=0}flag' ${input} | awk '{print $1 " " $2 " '"${parb}"' "}' |awk '{ printf("%10s %2s %3s %7s\n", $1, $2, $3, $4)}' >> prms.in
fi

cat >> prms.in << EOF
#
# ANGLE PARAMETERS:
#### ANGLE      KT      THEQ ####
EOF

if [ -n "$( awk '/\$angle/{flag=1;next}/\$endangle/{flag=0}flag' ${input} )" ]; then

  if [ -z "${fitoptions}" ]; then para=$(echo "1 1")
  else
    if [ -n "$(echo ${fitoptions} | grep 'KT')" ] ; then
      if [ -n "$(echo ${fitoptions} | grep 'THEQ')" ] ; then para=$(echo "1 1")
      else
      para=$(echo "1 0")
      fi
    else
      if [ -n "$(echo ${fitoptions} | grep 'THEQ')" ] ; then para=$(echo "0 1")
      fi
    fi
  fi

awk '/\$angle/{flag=1;next}/\$endangle/{flag=0}flag' ${input} | awk '{print $1 " " $2 " " $3  " '"${para}"' "}' |awk '{ printf("%10s %2s %2s %8s %7s\n", $1, $2, $3, $4, $5)}' >> prms.in
fi

cat >> prms.in << EOF
#
# DIHEDRAL PARAMETERS:
#### DIHEDRAL   TERM    KP      NP      PHASE ####
EOF

if [ -n "$( awk '/\$dihedral/{flag=1;next}/\$enddihedral/{flag=0}flag' ${input} )" ]; then

  if [ -z "${fitoptions}" ]; then pard=$(echo "1 1 1")
  else
    if [ -n "$(echo ${fitoptions} | grep 'KP')" ] ; then
      if [ -n "$(echo ${fitoptions} | grep 'NP')" ] ; then
        if [ -n "$(echo ${fitoptions} | grep 'PHASE')" ] ; then pard=$(echo "1 1 1")
        else
        pard=$(echo "1 1 0")
        fi
      else
        if [ -n "$(echo ${fitoptions} | grep 'PHASE')" ] ; then pard=$(echo "1 0 1")
        else
        pard=$(echo "1 0 0")
        fi
      fi
    else
      if [ -n "$(echo ${fitoptions} | grep 'NP')" ] ; then
        if [ -n "$(echo ${fitoptions} | grep 'PHASE')" ] ; then pard=$(echo "0 1 1")
        else
        pard=$(echo "0 1 0")
        fi
      else
        if [ -n "$(echo ${fitoptions} | grep 'PHASE')" ] ; then pard=$(echo "0 0 1")
        fi
      fi
    fi
  fi

awk '/\$dihedral/{flag=1;next}/\$enddihedral/{flag=0}flag' ${input} | awk '{print $1" "$2" "$3" "$4" "$14}' > prmdihe
  while read line
  do
  c2=$(echo $line | awk '{print $5}')
  c1=$(echo $line | awk '{print $1" "$2" "$3" "$4}')
  idx=0
    for ((idx=0; idx<$c2; idx++))
    do
    echo "$c1 $idx ${pard}" >> tmpdihe
    done
  done < prmdihe

  awk '{printf("%10s %2s %2s %2s %5s %7s %7s %7s\n", $1, $2, $3, $4, $5, $6, $7, $8)}' tmpdihe >> prms.in
fi

if [ "${direct}" != "1" ]; then
pause $(echo -e "${BLUE}*If this step is ok, press [Enter] key to continue...${NC}")
fi

 # remove intermediary files
if [ -a 'prmdihe' ]; then rm prmdihe ; fi
if [ -a 'tmpdihe' ]; then rm tmpdihe ; fi

 # make input for fitting
kfit=$(grep -A 3 "FINAL PARAMETERS" fitK_${resname}.out | grep "kcal/mol" | awk '{print $3}')

algorithm=$(grep '$ALGORITHM' ${input} | awk '{print $3}')
optimizations=$(grep '$OPTIMIZATIONS' ${input} | awk '{print $3}')
maxgen=$(grep '$MAX_GENERATIONS' ${input} | awk '{print $3}')
genconv=$(grep '$GENERATIONS_TO_CONV' ${input} | awk '{print $3}')
gensimplex=$(grep '$GENERATIONS_TO_SIMPLEX' ${input} | awk '{print $3}')
genwoutsimplex=$(grep '$GENERATIONS_WITHOUT_SIMPLEX' ${input} | awk '{print $3}')
mutation=$(grep '$MUTATION_RATE' ${input} | awk '{print $3}')
parentper=$(grep '$PARENT_PERCENT' ${input} | awk '{print $3}')
searchspace=$(grep '$SEARCH_SPACE' ${input} | awk '{print $3}')

if ls fit_*.out 1> /dev/null 2>&1 ; then
oldndx=$( ls fit_*.out |  sed -e "s/fit_//" -e "s/.out//" | sort -V | tail -n 1 )
fitndx=$(( $oldndx +1 ))
else
fitndx=1
fi

cat > job_fit.in <<EOF
# Run a fit to energies using the parameters defined earlier
RUNTYPE=FIT
COORDINATE_FORMAT=TRAJECTORY
NSTRUCTURES=${snew}
K=${kfit}
PARAMETERS_TO_FIT=LOAD
PARAMETER_FILE_NAME=prms.in
FUNC_TO_FIT=SUM_SQUARES_AMBER_STANDARD
QM_ENERGY_UNITS=HARTREE
# Use the genetic algorithm with the following settings
ALGORITHM=${algorithm}
OPTIMIZATIONS=${optimizations}
MAX_GENERATIONS=${maxgen}
GENERATIONS_TO_CONV=${genconv}
GENERATIONS_TO_SIMPLEX=${gensimplex}
GENERATIONS_WITHOUT_SIMPLEX=${genwoutsimplex}
MUTATION_RATE=${mutation}
PARENT_PERCENT=${parentper}
SEARCH_SPACE=${searchspace}
WRITE_FRCMOD=fit_${fitndx}_${resname}.frcmod
SORT_MDCRDS=OFF
# Output files for later analysis
WRITE_ENERGY=fit_${fitndx}_energy.dat
EOF

echo -e "${GRAY}*Paramters Fitting (attempt ${fitndx})...${NC}"
echo -e "${MAG}This step may take a while, please wait.${NC}"

if [ "${verbose}" = "1" ]; then
paramfit -i job_fit.in -p ${resname}.prmtop -c ${resname}_valid_structures.mdcrd -q energy_qm_${resname}.dat | tee fit_${fitndx}.out
else
paramfit -i job_fit.in -p ${resname}.prmtop -c ${resname}_valid_structures.mdcrd -q energy_qm_${resname}.dat > fit_${fitndx}.out
fi

echo -e "${GRAY}*Simplified report of final fitted parameters... (fit_${fitndx}_report.txt)${NC}"
grep "FINAL PARAMETERS" fit_${fitndx}.out > fit_${fitndx}_report.txt
awk '/FINAL PARAMETERS/{flag=1;next}/----------------/{flag=0}flag' fit_${fitndx}.out  | grep -e "\*" >> fit_${fitndx}_report.txt
echo "   ----------------------------------------------------------------------------------" >> fit_${fitndx}_report.txt
awk '/FINAL PARAMETERS/ {p=1}; p; /kcal\/mol/ {p=0}' fit_${fitndx}.out | grep "K = " | awk '{print "     " $1, $2, $3, $4}' >> fit_${fitndx}_report.txt
awk '/FINAL PARAMETERS/{flag=1;next}/Calculated energy with fitted/{flag=0}flag' fit_${fitndx}.out | grep "R^2" |awk '{print "     " $8, $9, $10}' >> fit_${fitndx}_report.txt
#sed -i 's/(\* means parameter is NOT constant during fit)/(   \* assign fitted parameters in this run\)/g' fit_${fitndx}_report.txt
echo "   ----------------------------------------------------------------------------------" >> fit_${fitndx}_report.txt

cat fit_${fitndx}_report.txt

echo -e "${RED}Now, verify your results. See at Paramfit tutorial some strategies to refine them!${NC}"
}
#-------------- end fitting


#-------------- gausscan
function gausscan(){

 # checking for needed options
if [ -n "${input}" ]; then
  if [ -n "${mol2name}" ]; then
    if [ -n "${resname}" ]; then
    echo -e "${CYAN}Running Gausscan!${NC}"
    else
    echo -e "${RED}Define -r option! Type ./${version} -h for help.${NC}" ; exit
    fi
  else
  echo -e "${RED}Define -m option! Type ./${version} -h for help.${NC}" ; exit
  fi
else
echo -e "${RED}Define -i option! Type ./${version} -h for help.${NC}" ; exit
fi

 # gout to xyz
gout="${resname}_scan.out"
natoms=$(grep -m 1 'NAtoms=' ${gout} | awk '{print $2}')

if [ -d 'xyz' ] ; then rm -r xyz/ ; fi

ngrep=$(( ${natoms} + 5 ))

pref=$(echo $resname)
ngrep=$(( ${natoms} + 5 ))
i=$((${#pref}-1))
spac=$(echo "${pref:$i:1}")

grep -A ${ngrep} 'Z-Matrix orientation:' ${gout} > allxyz
csplit -s -f ${resname} -b '%02d.xy' -z allxyz /Z-Matrix\ orientation:/ '{*}'
ls *.xy | sort -n -t ${spac} -k 2 > estructs

while read file
  do
  sed '1,5d' $file | sed '/--/d' |awk '{print $2" "$4" "$5" "$6}' | column -t > ${file}z
  sed -i "1s/^/${natoms}\nestructure ${file}\n/" ${file}z
done < estructs

mkdir xyz
cp *.xyz xyz/
rm *.xy estructs allxyz

 # xyz to pdb
ls *.xyz | sort -n -t ${spac} -k 2 > list

while read file
 do
  idx=$(echo $file)
  idx=${idx#$"$resname"}
  idx=${idx%$".xyz"}
  echo $idx
  obabel -ixyz ${file} -opdb -O ${resname}_${idx}.pdb
done < list

rm list

 # pdb to mdcrd
ls *.pdb| sort -n -t _ -k 2 | awk '{print "trajin "$1}' > cpptraj.inp
echo "trajout ${resname}_valid_structures.mdcrd" >> cpptraj.inp
parm=$(head -n 1 cpptraj.inp)
sed -i "1i${parm}" cpptraj.inp
sed -i '1s/trajin/parm/g' cpptraj.inp

cpptraj -i cpptraj.inp

rm *.xyz cpptraj.inp
mv *pdb xyz/

 # make energy data
grep "SCF Done" ${gout} | awk '{print $5}' > energy_qm_${resname}.dat

if [ "${direct}" != "1" ]; then
pause $(echo -e "${BLUE}*If this step is ok, press [Enter] key to continue...${NC}")
fi

 # make molecule.prmtop and .crd
echo -e "${GRAY}*Generating system topology and coordinates...${NC}"

ff=$(grep '$ff' ${input} | awk '{print $3}')

cat > leap.in << EOF
source ${ff}
${resname} = loadmol2 ${mol2name}.mol2
loadamberparams ${mol2name}.frcmod
saveamberparm ${resname} ${resname}.prmtop ${resname}.inpcrd
quit
EOF

  # addition of new atom types
awk '/\$addAT/{flag=1;next}/\$endaddAT/{flag=0}flag' ${input} > add

if [ -z "$(cat add)" ]
then
  echo -e "${YELLOW}you don't added new atom types!${NC}"
else
  sed -i "/source/r add" leap.in
fi

if [ -a 'add' ]; then rm add ; fi

tleap -f leap.in

nstru=$(cat energy_qm_${resname}.dat|wc -l)
mdcrd="${resname}_valid_structures.mdcrd"

 # make .in for fit K
cat > fitK_${resname}.in <<EOF
# Use the first ${snew} structures of the input trajectory
NSTRUCTURES=${nstru}
COORDINATE_FORMAT=TRAJECTORY
# We want to fit the K parameter
RUNTYPE=FIT
PARAMETERS_TO_FIT=K_ONLY
# Fit to quantum energies that are in units of Hartree
FUNC_TO_FIT=SUM_SQUARES_AMBER_STANDARD
QM_ENERGY_UNITS=HARTREE
EOF

echo -e "${GRAY}*Fitting K...${NC}"
echo -e "${MAG}This step may take a while, please wait.${NC}"

 # fitting K
if [ "${verbose}" = "1" ]; then
paramfit -i fitK_${resname}.in -p ${resname}.prmtop -c ${mdcrd} -q energy_qm_${resname}.dat | tee fitK_${resname}.out
else
paramfit -i fitK_${resname}.in -p ${resname}.prmtop -c ${mdcrd} -q energy_qm_${resname}.dat > fitK_${resname}.out
fi

echo -e "${GRAY}*Simplified report of K fitting... (fitK.txt)${NC}"
echo "   ----------------------------------------------------------------------------------" > fitK.txt
awk '/FINAL PARAMETERS/ {p=1}; p; /kcal\/mol/ {p=0}' fitK_${resname}.out | grep "K = " | awk '{print "     " $1, $2, $3, $4}' >> fitK.txt
awk '/FINAL PARAMETERS/{flag=1;next}/Calculated energy with fitted/{flag=0}flag' fitK_${resname}.out | grep "R^2" |awk '{print "     " $8, $9, $10}' >> fitK.txt
echo "   ----------------------------------------------------------------------------------" >> fitK.txt
cat fitK.txt

 # generate prms.in
fitoptions=$( awk '/\$fitting/{flag=1;next}/\$endfitting/{flag=0}flag' ${input} )

cat > prms.in << EOF
#V2 AUTO-GENERATED PARAMETER FILE - DO NOT MODIFY
#
# BOND INFORMATION:
#### BOND       REQ     KR ####
EOF

if [ -n "$( awk '/\$bond/{flag=1;next}/\$endbond/{flag=0}flag' ${input} )" ]; then

  if [ -z "${fitoptions}" ]; then parb=$(echo "1 1")
  else
    if [ -n "$(echo ${fitoptions} | grep 'REQ')" ] ; then
      if [ -n "$(echo ${fitoptions} | grep 'KR')" ] ; then parb=$(echo "1 1")
      else
      parb=$(echo "1 0")
      fi
    else
      if [ -n "$(echo ${fitoptions} | grep 'KR')" ] ; then parb=$(echo "0 1")
      fi
    fi
  fi

awk '/\$bond/{flag=1;next}/\$endbond/{flag=0}flag' ${input} | awk '{print $1 " " $2 " '"${parb}"' "}' |awk '{ printf("%10s %2s %3s %7s\n", $1, $2, $3, $4)}' >> prms.in
fi

cat >> prms.in << EOF
#
# ANGLE PARAMETERS:
#### ANGLE      KT      THEQ ####
EOF

if [ -n "$( awk '/\$angle/{flag=1;next}/\$endangle/{flag=0}flag' ${input} )" ]; then

  if [ -z "${fitoptions}" ]; then para=$(echo "1 1")
  else
    if [ -n "$(echo ${fitoptions} | grep 'KT')" ] ; then
      if [ -n "$(echo ${fitoptions} | grep 'THEQ')" ] ; then para=$(echo "1 1")
      else
      para=$(echo "1 0")
      fi
    else
      if [ -n "$(echo ${fitoptions} | grep 'THEQ')" ] ; then para=$(echo "0 1")
      fi
    fi
  fi

awk '/\$angle/{flag=1;next}/\$endangle/{flag=0}flag' ${input} | awk '{print $1 " " $2 " " $3  " '"${para}"' "}' |awk '{ printf("%10s %2s %2s %8s %7s\n", $1, $2, $3, $4, $5)}' >> prms.in
fi

cat >> prms.in << EOF
#
# DIHEDRAL PARAMETERS:
#### DIHEDRAL   TERM    KP      NP      PHASE ####
EOF

if [ -n "$( awk '/\$dihedral/{flag=1;next}/\$enddihedral/{flag=0}flag' ${input} )" ]; then

  if [ -z "${fitoptions}" ]; then pard=$(echo "1 1 1")
  else
    if [ -n "$(echo ${fitoptions} | grep 'KP')" ] ; then
      if [ -n "$(echo ${fitoptions} | grep 'NP')" ] ; then
        if [ -n "$(echo ${fitoptions} | grep 'PHASE')" ] ; then pard=$(echo "1 1 1")
        else
        pard=$(echo "1 1 0")
        fi
      else
        if [ -n "$(echo ${fitoptions} | grep 'PHASE')" ] ; then pard=$(echo "1 0 1")
        else
        pard=$(echo "1 0 0")
        fi
      fi
    else
      if [ -n "$(echo ${fitoptions} | grep 'NP')" ] ; then
        if [ -n "$(echo ${fitoptions} | grep 'PHASE')" ] ; then pard=$(echo "0 1 1")
        else
        pard=$(echo "0 1 0")
        fi
      else
        if [ -n "$(echo ${fitoptions} | grep 'PHASE')" ] ; then pard=$(echo "0 0 1")
        fi
      fi
    fi
  fi

awk '/\$dihedral/{flag=1;next}/\$enddihedral/{flag=0}flag' ${input} | awk '{print $1" "$2" "$3" "$4" "$14}' > prmdihe
  while read line
  do
  c2=$(echo $line | awk '{print $5}')
  c1=$(echo $line | awk '{print $1" "$2" "$3" "$4}')
  idx=0
    for ((idx=0; idx<$c2; idx++))
    do
    echo "$c1 $idx ${pard}" >> tmpdihe
    done
  done < prmdihe

  awk '{printf("%10s %2s %2s %2s %5s %7s %7s %7s\n", $1, $2, $3, $4, $5, $6, $7, $8)}' tmpdihe >> prms.in
fi

if [ "${direct}" != "1" ]; then
pause $(echo -e "${BLUE}*If this step is ok, press [Enter] key to continue...${NC}")
fi

 # remove intermediary files
if [ -a 'prmdihe' ]; then rm prmdihe ; fi
if [ -a 'tmpdihe' ]; then rm tmpdihe ; fi

 # make input for fitting
kfit=$(grep -A 3 "FINAL PARAMETERS" fitK_${resname}.out | grep "kcal/mol" | awk '{print $3}')

algorithm=$(grep '$ALGORITHM' ${input} | awk '{print $3}')
optimizations=$(grep '$OPTIMIZATIONS' ${input} | awk '{print $3}')
maxgen=$(grep '$MAX_GENERATIONS' ${input} | awk '{print $3}')
genconv=$(grep '$GENERATIONS_TO_CONV' ${input} | awk '{print $3}')
gensimplex=$(grep '$GENERATIONS_TO_SIMPLEX' ${input} | awk '{print $3}')
genwoutsimplex=$(grep '$GENERATIONS_WITHOUT_SIMPLEX' ${input} | awk '{print $3}')
mutation=$(grep '$MUTATION_RATE' ${input} | awk '{print $3}')
parentper=$(grep '$PARENT_PERCENT' ${input} | awk '{print $3}')
searchspace=$(grep '$SEARCH_SPACE' ${input} | awk '{print $3}')

if ls fit_*.out 1> /dev/null 2>&1 ; then
oldndx=$( ls fit_*.out |  sed -e "s/fit_//" -e "s/.out//" | sort -V | tail -n 1 )
fitndx=$(( $oldndx +1 ))
else
fitndx=1
fi

cat > job_fit.in <<EOF
# Run a fit to energies using the parameters defined earlier
RUNTYPE=FIT
COORDINATE_FORMAT=TRAJECTORY
NSTRUCTURES=${nstru}
K=${kfit}
PARAMETERS_TO_FIT=LOAD
PARAMETER_FILE_NAME=prms.in
FUNC_TO_FIT=SUM_SQUARES_AMBER_STANDARD
QM_ENERGY_UNITS=HARTREE
# Use the genetic algorithm with the following settings
ALGORITHM=${algorithm}
OPTIMIZATIONS=${optimizations}
MAX_GENERATIONS=${maxgen}
GENERATIONS_TO_CONV=${genconv}
GENERATIONS_TO_SIMPLEX=${gensimplex}
GENERATIONS_WITHOUT_SIMPLEX=${genwoutsimplex}
MUTATION_RATE=${mutation}
PARENT_PERCENT=${parentper}
SEARCH_SPACE=${searchspace}
WRITE_FRCMOD=fit_${fitndx}_${resname}.frcmod
SORT_MDCRDS=OFF
# Output files for later analysis
WRITE_ENERGY=fit_${fitndx}_energy.dat
EOF

echo -e "${GRAY}*Paramters Fitting (attempt ${fitndx})...${NC}"
echo -e "${MAG}This step may take a while, please wait.${NC}"

if [ "${verbose}" = "1" ]; then
paramfit -i job_fit.in -p ${resname}.prmtop -c ${resname}_valid_structures.mdcrd -q energy_qm_${resname}.dat | tee fit_${fitndx}.out
else
paramfit -i job_fit.in -p ${resname}.prmtop -c ${resname}_valid_structures.mdcrd -q energy_qm_${resname}.dat > fit_${fitndx}.out
fi

echo -e "${GRAY}*Simplified report of final fitted parameters... (fit_${fitndx}_report.txt)${NC}"
grep "FINAL PARAMETERS" fit_${fitndx}.out > fit_${fitndx}_report.txt
awk '/FINAL PARAMETERS/{flag=1;next}/----------------/{flag=0}flag' fit_${fitndx}.out  | grep -e "\*" >> fit_${fitndx}_report.txt
echo "   ----------------------------------------------------------------------------------" >> fit_${fitndx}_report.txt
awk '/FINAL PARAMETERS/ {p=1}; p; /kcal\/mol/ {p=0}' fit_${fitndx}.out | grep "K = " | awk '{print "     " $1, $2, $3, $4}' >> fit_${fitndx}_report.txt
awk '/FINAL PARAMETERS/{flag=1;next}/Calculated energy with fitted/{flag=0}flag' fit_${fitndx}.out | grep "R^2" |awk '{print "     " $8, $9, $10}' >> fit_${fitndx}_report.txt
#sed -i 's/(\* means parameter is NOT constant during fit)/(   \* assign fitted parameters in this run\)/g' fit_${fitndx}_report.txt
echo "   ----------------------------------------------------------------------------------" >> fit_${fitndx}_report.txt

cat fit_${fitndx}_report.txt

rm leap*
rm ${resname}.inpcrd
rm struc.prmtop

echo -e "${RED}Now, verify your results. See at Paramfit tutorial some strategies to refine them!${NC}"
}
#-------------- end gausscan


#-------------- scatterplots
function scatterplots(){

 # checking for needed options
if [ -n "${resname}" ]; then
echo -e "${CYAN}Running Scatterplots!${NC}"
else
echo -e "${RED}Define -r option! Type ./${version} -h for help.${NC}" ; exit
fi

 #remove results of previous attempt
for fileb in *.bond* ; do if [ -e "$fileb"  ]; then rm *.bond* ; fi ; done
for filea in *.angle* ; do if [ -e "$filea"  ]; then rm *.angle* ; fi ; done
for filed in *.dihe* ; do if [ -e "$filed"  ]; then rm *.dihe* ; fi ; done

offset=1 # n of lines that aren't strucures in mdcrd (first one)
nlines=5 # n of lines for each structure
mdcrd="${resname}_valid_structures.mdcrd"
nlnew=$(cat ${mdcrd} | wc -l)
snew=$(( ( ${nlnew} - ${offset} ) / ${nlines} ))

 # generate job_scatterplots.in
cat > job_scatterplots.in <<EOF
# Do a dummy fit
RUNTYPE=FIT
ALGORITHM=NONE
NSTRUCTURES=${snew}
COORDINATE_FORMAT=TRAJECTORY
# Load the paramter file
PARAMETERS_TO_FIT=LOAD
PARAMETER_FILE_NAME=prms.in
# Output dihedral scatterplots
SCATTERPLOTS=YES
EOF

 # run paramfit for scatterplots
if [ "${verbose}" = "1" ]; then
paramfit -i job_scatterplots.in -p ${resname}.prmtop -c ${resname}_valid_structures.mdcrd -q energy_qm_${resname}.dat | tee scatterplots.out
else
paramfit -i job_scatterplots.in -p ${resname}.prmtop -c ${resname}_valid_structures.mdcrd -q energy_qm_${resname}.dat > scatterplots.out
fi

 # rename files with ? at end
for fileb in *.bond* ; do if [ -e "$fileb"  ]; then for i in *bonde* ; do mv "${i}" "${i%?}" ; done ; rename  's/e$/eq/' *bonde*  ; fi ; done
for filea in *.angle* ; do if [ -e "$filea"  ]; then for i in *angle* ; do mv "${i}" "${i%?}" ; done ; rename  's/e$/eq/' *angle*  ; fi ; done
for filed in *.dihe* ; do if [ -e "$filed"  ]; then for i in *dihe* ; do mv "${i}" "${i%?}" ; done ; rename  's/e$/eq/' *dihe*  ; fi ; done


if [ "${verbose}" = "1" ]; then
  if [ "$(ls *.bondeq | wc -l)" != "0" ]; then
  scatb="$(ls *.bondeq | head -n 1)"
  $AMBERHOME/AmberTools/src/paramfit/scripts/scatterplots.sh $scatb
  else
    if [ "$(ls *.angleq | wc -l)" != "0" ]; then
    scata="$(ls *.angleq | head -n 1)"
    $AMBERHOME/AmberTools/src/paramfit/scripts/scatterplots.sh $scata
    else
      if [ "$(ls *.diheq | wc -l)" != "0" ]; then
      scatd="$(ls *.diheq | head -n 1)"
      $AMBERHOME/AmberTools/src/paramfit/scripts/scatterplots.sh $scatd
      else
      echo -e "${RED}You don't generate any scatterplot! Check for errors${NC}"
      fi
    fi
  fi
else
echo -e "${RED}Visualise your results with Gnuplot and \$AMBERHOME/AmberTools/src/paramfit/scripts/scatterplots.sh!${NC}"
fi

}
#-------------- end scatterplots

#-------------- plotdihe
function plotdihe(){

 # checking for needed options
if [ -n "${pdihe}" ]; then
  if [ -n "${guess}" ]; then
    if [ -n "${fitted}" ]; then
    echo -e "${CYAN}Running plot_dihedral!${NC}"
    else
    echo -e "${RED}Define -p option! Type ./${version} -h for help.${NC}" ; exit
    fi
  else
  echo -e "${RED}Define -g option! Type ./${version} -h for help.${NC}" ; exit
  fi
else
echo -e "${RED}Define -d option! Type ./${version} -h for help.${NC}" ; exit
fi

 # making sure there is no intermediary files from previous attempts
if [ -a 'ftmp' ]; then rm ftmp ; fi
if [ -a 'gtmp' ]; then rm gtmp ; fi
if [ -a 'floop' ]; then rm floop ; fi
if [ -a 'gloop' ]; then rm gloop ; fi

 # generate print_${pdihe}.py
gdiv=$(grep "$pdihe" ${guess} | head -1 | awk '{print $2}')
gbar=$(grep "$pdihe" ${guess} | head -1 | awk '{print $3}')
gph=$(grep "$pdihe" ${guess} | head -1 | awk '{print $4}')
gn=$(grep "$pdihe" ${guess} | head -1 | awk '{print $5}')

cat > print_${pdihe}.py <<EOF
#!/usr/bin/env python

import numpy as np
from matplotlib import pyplot as plt

phi = np.linspace(0., 2. * np.pi, num=50)

 # guess
def dihedral_guess(phi, v_barrier=float(${gbar}), n=float(${gn}), phase=float(${gph}), divider=float(${gdiv})):
    return v_barrier * (1. + np.cos(n * phi - phase)) / divider

EOF

grep "$pdihe" ${guess} | sed '1d' > gloop

if [ "$(cat gloop | wc -l)" != 0 ]; then
echo -e "energy_guess = dihedral_guess(phi)\n+" > gtmp
  while read line
  do
  ggdiv=$(echo $line | awk '{print $2}')
  ggbar=$(echo $line | awk '{print $3}')
  ggph=$(echo $line | awk '{print $4}')
  ggn=$(echo $line | awk '{print $5}')
  echo -e "dihedral_guess(phi, v_barrier=float(${ggbar}), n=float(${ggn}), phase=float(${ggph}), divider=float(${ggdiv}))\n+" >> gtmp
  done < gloop
else
cat >> print_${pdihe}.py <<EOF
energy_guess = dihedral_guess(phi)

EOF
fi

cat gtmp | sed '$ d' | tr '\n' ' ' >> print_${pdihe}.py
echo -e "\n" >> print_${pdihe}.py

fdiv=$(grep "$pdihe" ${fitted} | head -1 | awk '{print $2}')
fbar=$(grep "$pdihe" ${fitted} | head -1 | awk '{print $3}')
fph=$(grep "$pdihe" ${fitted} | head -1 | awk '{print $4}')
fn=$(grep "$pdihe" ${fitted} | head -1 | awk '{print $5}')

cat >> print_${pdihe}.py <<EOF
 # fitted
def dihedral_fitted(phi, v_barrier=float(${fbar}), n=float(${fn}), phase=float(${fph}), divider=float(${fdiv})):
    return v_barrier * (1. + np.cos(n * phi - phase)) / divider

EOF

grep "$pdihe" ${fitted} | sed '1d' > floop

if [ "$(cat floop | wc -l)" != 0 ]; then
echo -e "energy_fitted = dihedral_fitted(phi)\n+" > ftmp
  while read line
  do
  ffdiv=$(echo $line | awk '{print $2}')
  ffbar=$(echo $line | awk '{print $3}')
  ffph=$(echo $line | awk '{print $4}')
  ffn=$(echo $line | awk '{print $5}')
  echo -e "dihedral_fitted(phi, v_barrier=float(${ffbar}), n=float(${ffn}), phase=float(${ffph}), divider=float(${ffdiv}))\n+" >> ftmp
  done < floop
else
cat >> print_${pdihe}.py <<EOF
energy_fitted = dihedral_fitted(phi)

EOF
fi

cat ftmp | sed '$ d' | tr '\n' ' ' >> print_${pdihe}.py
echo -e "\n" >> print_${pdihe}.py

cat >> print_${pdihe}.py <<EOF
phi = np.linspace(0., 2. * np.pi, num=50)
energy_guess = dihedral_guess(phi)
energy_fitted = dihedral_fitted(phi)

plt.plot(phi * 180./ np.pi, energy_guess, 'b--')
plt.plot(phi * 180./ np.pi, energy_fitted, 'r-')
plt.title("Torsion ${pdihe}")
plt.xlabel('Phi (degrees)')
plt.ylabel('E torsion (Kcal/mol)')
plt.legend(['guess', 'fitted'])

plt.show()
EOF

if [ -a 'ftmp' ]; then rm ftmp ; fi
if [ -a 'gtmp' ]; then rm gtmp ; fi
if [ -a 'floop' ]; then rm floop ; fi
if [ -a 'gloop' ]; then rm gloop ; fi

if [ "${verbose}" = "1" ]; then
python print_${pdihe}.py
else
echo -e "${RED}Visualise ${pdihe} profile running: python print_${pdihe}.py ${NC}"
fi

}
#-------------- end plotdihe




 # testing flags and options
if [ "${conforma}" = "1" ] && [ "${fitting}" = "1" ]; then
echo -e "${RED}You can use just one flag (-C, -F, -G, -S or -T)! Type ./${version} -h for help.${NC}" ; exit
fi
if  [ "${conforma}" = "1" ] && [ "${scatterplots}" = "1" ]; then
echo -e "${RED}You can use just one flag (-C, -F, -G, -S or -T)! Type ./${version} -h for help.${NC}" ; exit
fi
if  [ "${conforma}" = "1" ] && [ "${plotdihe}" = "1" ]; then
echo -e "${RED}You can use just one flag (-C, -F, -G, -S or -T)! Type ./${version} -h for help.${NC}" ; exit
fi
if  [ "${fitting}" = "1" ] && [ "${scatterplots}" = "1" ]; then
echo -e "${RED}You can use just one flag (-C, -F, -G, -S or -T)! Type ./${version} -h for help.${NC}" ; exit
fi
if  [ "${fitting}" = "1" ] && [ "${plotdihe}" = "1" ]; then
echo -e "${RED}You can use just one flag (-C, -F, -G, -S or -T)! Type ./${version} -h for help.${NC}" ; exit
fi
if  [ "${plotdihe}" = "1" ] && [ "${scatterplots}" = "1" ]; then
echo -e "${RED}You can use just one flag (-C, -F, -G, -S or -T)! Type ./${version} -h for help.${NC}" ; exit
fi
if [ "${conforma}" = "1" ] && [ "${gausscan}" = "1" ]; then
echo -e "${RED}You can use just one flag (-C, -F, -G, -S or -T)! Type ./${version} -h for help.${NC}" ; exit
fi
if [ "${fitting}" = "1" ] && [ "${gausscan}" = "1" ]; then
echo -e "${RED}You can use just one flag (-C, -F, -G, -S or -T)! Type ./${version} -h for help.${NC}" ; exit
fi
if [ "${scatterplots}" = "1" ] && [ "${gausscan}" = "1" ]; then
echo -e "${RED}You can use just one flag (-C, -F, -G, -S or -T)! Type ./${version} -h for help.${NC}" ; exit
fi
if [ "${plotdihe}" = "1" ] && [ "${gausscan}" = "1" ]; then
echo -e "${RED}You can use just one flag (-C, -F, -G, -S or -T)! Type ./${version} -h for help.${NC}" ; exit
fi

if [ "${conforma}" = "1" ]; then
conforma
else
  if [ "${fitting}" = "1" ]; then
  fitting
  else
    if [ "${scatterplots}" = "1" ]; then
    scatterplots
    else
      if [ "${plotdihe}" = "1" ]; then
      plotdihe
      else
        if [ "${gausscan}" = "1" ]; then
        gausscan
        fi
      fi
    fi
  fi
fi
