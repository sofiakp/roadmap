#!/bin/bash

usage()
{
cat <<EOF
usage: `basename $0` options SCANDIRS OUTDIR
Runs crossValidateCluster.py for a list of clusters read from STDIN.
For each file <pref>.bed.gz it will look for feature matrices 
starting with pref in each of the diretories in SCANDIRS.
The directory list should be given like this:
"dir1/*npz dir2/*npz..." (notice the *. This will ensure absolute paths
when running ls).

OPTIONS:
   -h     Show this message and exit
   -d STR Comma-separated list of depths.
   -t NUM Number of trees.
   -n     Do not run CV, just learn models on full data.
   -p NUM Number of processors to request [Default: 4].
EOF
}

DEPTHS="2,3,4"
NTREES=200
CV=""
NJOBS=4

while getopts "hnd:t:p:" opt
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
	p)
	    NJOBS=$OPTARG;;
	?)
	    usage
            exit 1;;
    esac    
done

shift "$((OPTIND - 1))"
if [ $# -ne 2 ]; then 
    usage; exit 1;
fi
SCANDIRS=$1
OUTDIR=$2

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
    params="--njobs $NJOBS --depths $DEPTHS --ntrees $NTREES $CV"
    echo "ls $SCANDIRS | egrep ${pref}_vs_ | python ${SRCDIR}/python/crossValidateCluster.py $outfile $params" >> $script
    qsub -N ${pref}_${suf} -q standard -l h_vmem=4G -l h_rt=6:00:00 -e $errfile -pe shm $NJOBS -o /dev/null $script
done
