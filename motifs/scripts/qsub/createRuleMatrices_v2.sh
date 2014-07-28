#!/bin/bash

usage()
{
cat <<EOF
usage: `basename $0` options RULEFILE OUTDIR

Applies rules to all the motif score matrices read from STDIN.
For each input feature matrix, it will create a binary rule matrix in
OUTDIR/<pref>_vs_RULEPREF.npz, where 
pref is the prefix of the input feature matrix and 
RULEPREF is the prefix of the RULEFILE.

OPTIONS:
   -h     Show this message and exit

EOF
}

while getopts "h" opt
do
    case $opt in
	h)
	    usage; exit;;
	?)
	    usage
            exit 1;;
    esac    
done

shift "$((OPTIND - 1))"
if [ $# -ne 2 ]; then 
    usage; exit 1;
fi

RULES=$1
OUTDIR=$2

rulefile=$RULES
if [ ! -f $RULES ]; then
    echo "Provided rules file does not exist." 1>&2
    exit 1
fi
pref=$(basename $rulefile)
pref=${pref/.pkl/}

if [ ! -d ${OUTDIR}/tmp ]; then
    mkdir -p ${OUTDIR}/tmp
fi

SRCDIR="${LABHOME}/roadmap/src/motifs/"

while read -r featfile; do
    c=$(basename $featfile)
    c=${c/_vs_*/}
    c=${c/_scores.npz/}
    outfile=${OUTDIR}/${c}_vs_${pref}.npz
    
    if [ ! -f $outfile ]; then
	errfile=${OUTDIR}/tmp/${c}_vs_${pref}.err
	script=${OUTDIR}/tmp/${c}_vs_${pref}.sh

	echo "#!/bin/bash" > $script
	echo "module add python/2.7" >> $script
	echo "python ${SRCDIR}/python/applyRules.py $featfile $rulefile $outfile" >> $script
	qsub -N ${c}_vs_${pref} -l h_vmem=8G -l h_rt=6:00:00 -e $errfile -o /dev/null $script
    fi
done

