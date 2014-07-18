#!/bin/bash

usage()
{
cat <<EOF
usage: `basename $0` options SCANDIRS OUTDIR
Runs crossValidateCluster.py for a list of clusters read from STDIN.
For each file <pref>.bed.gz it will look for feature matrices 
starting with <pref>_vs_ in SCANDIR. The corresponding random backgrounds
should be in SCANDIR/random_bg and have the same prefix.

OPTIONS:
   -h     Show this message and exit
   -d STR Comma-separated list of depths.
   -t NUM Number of trees.
   -n     Do not run CV, just learn models on full data.
   -p NUM Number of processors to request [Default: 4].
   -m NUM How many Gb of memory to request [Default: 4].
   -l NUM Minimum number (or fraction) of examples in leaves [Default: 10].
EOF
}

DEPTHS="2,3,4"
NTREES=200
CV=""
NJOBS=4
MEM=4
MINLEAF=0.1

while getopts "hnd:t:l:p:m:" opt
do
    case $opt in
	h)
	    usage; exit;;
	n)
	    CV="--nocv";;
	d)
	    DEPTHS=$OPTARG;;
	t)
	    NTREES=$OPTARG;;
	l)
	    MINLEAF=$OPTARG;;
	p)
	    NJOBS=$OPTARG;;
	m)
	    MEM=$OPTARG;;
	?)
	    usage
            exit 1;;
    esac    
done

shift "$((OPTIND - 1))"
if [ $# -ne 2 ]; then 
    usage; exit 1;
fi
SCANDIR=$1
OUTDIR=$2

if [[ $CV == "--nocv" ]]; then
    OUTDIR=${OUTDIR}/depth${DEPTHS}
fi

if [ ! -d ${OUTDIR}/tmp ]; then
    mkdir -p ${OUTDIR}/tmp 
fi

SRCDIR="${LABHOME}/roadmap/src/motifs/"

while read -r bedfile; do
    pref=$(basename $bedfile)
    pref=${pref/.bed/}
    pref=${pref/.gz/}
    if [[ $CV == "" ]]; then
	suf="cv"
	ext="npz"
    else
	suf="model"
	ext="pkl"
    fi
    errfile=${OUTDIR}/tmp/${pref}_${suf}.err
    script=${OUTDIR}/tmp/${pref}_${suf}.sh
    outfile=${OUTDIR}/${pref}_${suf}.${ext}

    if [ -f $outfile ]; then
	echo "$outfile exists. Skipping." 1>&2
	continue
    fi

    echo "#!/bin/bash" > $script
    echo "module add python/2.7" >> $script 
    params="--njobs $NJOBS --depths $DEPTHS --ntrees $NTREES --minleaf $MINLEAF $CV"
    count=`ls $SCANDIR | egrep ${pref}_vs_.*_scores.npz | wc -l`
    if [ $count -ne 1 ]; then
	echo "Ambiguous or missing file for prefix $pref. Skipping." 1>&2
	continue
    fi
    count=`ls ${SCANDIR}/random_bg | egrep ${pref}_vs_.*_scores_bg.npz | wc -l`
    if [ $count -ne 1 ]; then
	echo "Ambiguous or missing background file for prefix $pref. Skipping." 1>&2
	continue
    fi
    infile=`ls $SCANDIR/${pref}_vs_*_scores.npz`
    bgfile=`ls ${SCANDIR}/random_bg/${pref}_vs_*scores_bg.npz`
    echo "python ${SRCDIR}/python/crossValidateCluster.py $infile $bgfile $outfile $params" >> $script
    qsub -N ${pref}_${suf} -l h_vmem=${MEM}G -l h_rt=6:00:00 -e $errfile -pe shm $NJOBS -o /dev/null $script
done
