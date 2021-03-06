#!/bin/bash

usage()
{
cat <<EOF
usage: `basename $0` options FEATDIR MODELDIR
Gets rules from a set of models read from MODELDIR and applies them on
(samples from) the feature matrices in FEATDIR.

The models should be MODELDIR/*model.pkl. Rules will be extracted
from the models using the importance percentile and similarity cutoffs given.
The rules will be written in 
MODELDIR/RULEPREF/RULEPREF.pkl
RULEPREF=rules_imp<prc>_sim<sim>_trees<ntrees>

The feature matrices will be read from FEATDIR/*_scores.npz. For each
input feature matrix, it will create a binary rule matrix in
MODELDIR/RULEPREF/<pref>_vs_RULEPREF.npz, 
based on the extracted rules (pref is the prefix of the input feature matrix).

OPTIONS:
   -h     Show this message and exit
   -p NUM Cutoff of feature importance (see getModelRules.py).
   -m NUM Similarity cutoff for removing redundant rules.
   -s FILE File with cluster sizes (see applyRules.py).
   -t STR Number of trees to use from each RF.
   -x NUM Maximum number of samples per cluster (ignored if -s is provided).
   -r FILE Use the provided rules file instead of the default one. 
   -n      Set negative thresholds to 0.
EOF
}

IMP=0.01
SIM=1
SIZEFILE=
MAXEX=10000
NTREES=0
RULES=
NONEG=""

while getopts "hp:m:s:t:x:r:n" opt
do
    case $opt in
	h)
	    usage; exit;;
	p)
	    IMP=$OPTARG;;
	m)
	    SIM=$OPTARG;;
	s)
	    SIZEFILE=$OPTARG;;
	t) 
	    NTREES=$OPTARG;;
	x) 
	    MAXEX=$OPTARG;;
	r)
	    RULES=$OPTARG;;
	n)
	    NONEG="--noneg";;
	?)
	    usage
            exit 1;;
    esac    
done

shift "$((OPTIND - 1))"
if [ $# -ne 2 ]; then 
    usage; exit 1;
fi

FEATDIR=$1
MODELDIR=$2

if [ -z $SIZEFILE ]; then
    sizes=""
else
    echo "Will read cluster sizes from $SIZEFILE" 1>&2
    sizes="--sizes $SIZEFILE"
fi

if [ -z $RULES ]; then
    pref=rules_imp${IMP}_sim${SIM}_trees${NTREES}
    if [[ $NONEG == "--noneg" ]]; then
	pref=${pref}_noNeg
    fi
    ruledir=${MODELDIR}/${pref}
    rulefile=${ruledir}/${pref}.pkl
else
    rulefile=$RULES
    if [ ! -f $RULES ]; then
	echo "Provided rules file does not exist." 1>&2
	exit 1
    fi
    pref=$(basename $rulefile)
    pref=${pref/.pkl/}
    ruledir=${MODELDIR}/${pref}
fi

echo "Will write results in $ruledir" 1>&2

if [ ! -d ${ruledir}/tmp ]; then
    mkdir -p ${ruledir}/tmp
fi
script=${ruledir}/tmp/${pref}.sh
errfile=${ruledir}/tmp/${pref}.err

SRCDIR="${LABHOME}/roadmap/src/motifs/"

if [ -f $rulefile ]; then
    echo "Rule file $rulefile exists." 1>&2
else
    echo "#!/bin/bash" > $script
    echo "module add python/2.7" >> $script
    echo "Will write rule file in $rulefile." 1>&2
    params="--imp $IMP --similarity $SIM --ntrees $NTREES $NONEG"
    echo "ls ${MODELDIR}/*model.pkl | python ${SRCDIR}/python/getModelRules.py $params $rulefile" >> $script
    qsub -N createRules -l h_vmem=4G -l h_rt=6:00:00 -e $errfile -o /dev/null $script
fi

if [ -z $SIZEFILE ]; then
    pref=${pref}_max$MAXEX
fi

for featfile in `ls ${FEATDIR}/*_scores.npz`; do
    c=$(basename $featfile)
    c=${c/_vs_*/}
    outfile=${ruledir}/${c}_vs_${pref}.npz
    
    if [ ! -f $outfile ]; then
	errfile=${ruledir}/tmp/${c}_vs_${pref}.err
	script=${ruledir}/tmp/${c}_vs_${pref}.sh

	echo "#!/bin/bash" > $script
	echo "module add python/2.7" >> $script
	echo "python ${SRCDIR}/python/applyRules.py $featfile $rulefile $outfile $sizes --maxsize $MAXEX" >> $script
	qsub -N ${c}_vs_${pref} -hold_jid createRules -l h_vmem=4G -l h_rt=6:00:00 -e $errfile -o /dev/null $script
    else
	echo "$outfile exist. Skipping." 1>&2
    fi
done

