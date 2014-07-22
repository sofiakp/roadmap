#!/bin/bash

usage()
{
cat <<EOF
usage: `basename $0` options OUTDIR
Gets rules from a set of models. The list of model files is read from STDIN.

Rules will be extracted from the models using the importance and similarity 
cutoffs given.

OPTIONS:
   -h     Show this message and exit
   -p NUM Cutoff of feature importance (see getModelRules.py).
   -m NUM Similarity cutoff for removing redundant rules.
   -t STR Number of trees to use from each RF.
   -n     Set negative rule thresholds to 0.
EOF
}

IMP=0.01
SIM=1
NTREES=0
NONEG=""
while getopts "hp:m:t:n" opt
do
    case $opt in
	h)
	    usage; exit;;
	p)
	    IMP=$OPTARG;;
	m)
	    SIM=$OPTARG;;
	t) 
	    NTREES=$OPTARG;;
	n)
	    NONEG="--noneg";;
	?)
	    usage
            exit 1;;
    esac    
done

shift "$((OPTIND - 1))"
if [ $# -ne 1 ]; then 
    usage; exit 1;
fi

OUTDIR=$1

pref=combined_rules_imp${IMP}_sim${SIM}_trees${NTREES}
if [[ $NONEG == "--noneg" ]]; then
    pref=${pref}_noNeg
fi
ruledir=${OUTDIR}/${pref}
rulefile=${ruledir}/${pref}.pkl

if [ ! -d ${ruledir}/tmp ]; then
    mkdir -p ${ruledir}/tmp
fi

script=${ruledir}/tmp/${pref}.sh
errfile=${ruledir}/tmp/${pref}.err

SRCDIR="${LABHOME}/roadmap/src/motifs/"

filelist=""
while read -r filename; do
    filelist="${filelist}$filename "
done

echo "#!/bin/bash" > $script
echo "module add python/2.7" >> $script
params="--imp $IMP --similarity $SIM --ntrees $NTREES $NONEG"
echo "ls $filelist | python ${SRCDIR}/python/getModelRules.py $params $rulefile" >> $script
qsub -N createMergedRules -l h_vmem=4G -l h_rt=6:00:00 -e $errfile -o /dev/null $script
