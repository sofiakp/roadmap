#!/bin/bash

usage()
{
cat <<EOF
usage: `basename $0` options SCANDIR
Creates random backgrounds for a list of score matrices read 
from the specified directory.
The output is written in SCANDIR/random_bg/.

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

SCANDIR=$1
OUTDIR=${SCANDIR}/random_bg
if [ ! -d ${OUTDIR}/tmp ]; then
    mkdir -p ${OUTDIR}/tmp 
fi

SRCDIR="${LABHOME}/roadmap/src/motifs/"

# Create the sizes file if this doesn't exist.
sizefile=${SCANDIR}/cluster_sizes.npz
if [ ! -f $sizefile ]; then
    script=${OUTDIR}/tmp/compute_size.sh
    echo "#!/bin/bash" >> $script
    echo "module add python/2.7" >> $script
    echo "python ${SRCDIR}/python/createBackgrounds.py $SCANDIR $sizefile --sizes" >> $script
    qsub -N compute_sizes -q standard l h_vmem=4G -l h_rt=1:00:00 -e ${outdir}/tmp/compute_sizes.err -o /dev/null $script 
fi

for infile in `ls ${SCANDIR}/*_scores.npz`; do
    pref=$(basename $infile)
    pref=${pref/.npz/}_bg
    outfile=${OUTDIR}/${pref}.npz
    script=${OUTDIR}/tmp/${pref}.sh
    errfile=${OUTDIR}/tmp/${pref}.err

    echo "#!/bin/bash" >> $script
    echo "module add python/2.7" >> $script
    echo "python ${SRCDIR}/python/createBackgrounds.py $SCANDIR $sizefile -i $infile -o $outfile" >> $script
    qsub -N $pref -q standard l h_vmem=4G -l h_rt=4:00:00 -e $errfile -o /dev/null $script 
done