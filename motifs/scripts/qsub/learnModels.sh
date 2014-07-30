#!/bin/bash

usage()
{
cat <<EOF
usage: `basename $0` options SCANDIR
Runs crossValidateCluster.py for a list of clusters read from STDIN.

For each file <pref>.bed.gz it will look for feature matrices 
starting with <pref>_vs_ in SCANDIR. The corresponding random backgrounds
should be in SCANDIR/random_bg and have the same prefix.
However, if you provide the -b option, it will use this file as background.
If you provide the -r option, it will use a shuffled version of the input 
feature matrix as background. If you give both -r and -b it will mix the 
two backgrounds.

By default, output will be written in SCANDIR/cv[_noNeg][/depth$d].

OPTIONS:
   -h     Show this message and exit
   -d STR Comma-separated list of depths.
   -t NUM Number of trees.
   -n     Do not run CV, just learn models on full data.
   -p NUM Number of processors to request [Default: 4].
   -m NUM How many Gb of memory to request [Default: 8].
   -l NUM Minimum number (or fraction) of examples in leaves [Default: 10].
   -e     Set negative scores to 0 before learning.
   -o PATH Change the default output directory.
   -r     Use shuffled input as background.    
   -b PATH Use this file as background instead of the default one.
EOF
}

DEPTHS="2,3,4"
NTREES=200
CV=""
NJOBS=4
MEM=8
MINLEAF=0.1
NONEG=""
OUTDIR=
PERMBG=""
BG=
while getopts "hnd:t:l:p:m:eo:rb:" opt
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
	e)
	    NONEG="--noneg";;
	o) 
	    OUTDIR=$OPTARG;;
	b)
	    BG=$OPTARG;;
	r)
	    PERMBG="--permbg";;
	?)
	    usage
            exit 1;;
    esac    
done

shift "$((OPTIND - 1))"
if [ $# -ne 1 ]; then 
    usage; exit 1;
fi
SCANDIR=$1

if [ -z $OUTDIR ]; then
    OUTDIR=${SCANDIR}/cv
    if [[ $NONEG == "--noneg" ]]; then
	OUTDIR=${OUTDIR}_noNeg
    fi
    if [[ $PERMBG == "--permbg" ]]; then
	OUTDIR=${OUTDIR}/permbg
	if [ ! -z $BG ]; then
	    OUTDIR=${OUTDIR}_plus_random
	fi
    fi
    if [[ $CV == "--nocv" ]]; then
	OUTDIR=${OUTDIR}/depth${DEPTHS}
    fi
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
    params="--njobs $NJOBS --depths $DEPTHS --ntrees $NTREES --minleaf $MINLEAF --balanced $CV $NONEG $PERMBG"
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
    if [[ $PERMBG == "" ]]; then
	bgfile=`ls ${SCANDIR}/random_bg/${pref}_vs_*scores_bg.npz`
	bgfile="--bgfile $bgfile"
    else
	if [ -z $BG ]; then
	    bgfile=""
	else
	    bgfile="--bgfile $BG"
	fi
    fi
    echo "python ${SRCDIR}/python/crossValidateCluster.py $infile $outfile $bgfile $params" >> $script
    qsub -N ${pref}_${suf} -l h_vmem=${MEM}G -l h_rt=6:00:00 -e $errfile -pe shm $NJOBS -o /dev/null $script
done
