#!/bin/bash

usage()
{
cat <<EOF
usage: `basename $0` options SCANDIR STATEMAP

Finds aggregated motif scores for genes, using only peaks
overlapping each of the input BED files.

A list of score files for all peak regions is read from SCANDIR.
Each such file has the scores for a subset of the regions together
with a list of region names.

A mapping from region names to states is read from STATEMAP.

For each BED file read from the input, the regions of the BED 
are intersected with STATEMAP, to get only the region ids of regions
contained in the BED.
Then, the scores are aggregated on the states.

Finally, the previous aggregated scores are read and re-aggregated,
based on a second mapping, from states to genes.

OPTIONS:
   -h     Show this message and exit
   -g FILE File mapping states to genes.
   -s STR  Suffix of output files.
   -f STR  Extra suffix for output gene files.
   -n      Create off matrices with sequences NOT overlapping the input beds.
EOF
}

SUF=""
SUF2=""
GENEMAP=
MAKEOFF=0
while getopts "hs:g:f:n" opt
do
    case $opt in
	h)
	    usage; exit;;
	s)
	    SUF=$OPTARG;;
	f)
	    SUF2=$OPTARG;;
	g)
	    GENEMAP=$OPTARG;;
	n)
	    MAKEOFF=1;;
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
STATEMAP=$2

OUTDIR=${SCANDIR}/merged
GENEDIR=${OUTDIR}

if [ ! -d ${OUTDIR}/tmp ]; then
    mkdir -p ${OUTDIR}/tmp
fi

SRCDIR="${LABHOME}/roadmap/src/motifs/"

while read -r bedfile; do
    pref=$(basename $bedfile)
    pref=${pref/.gz/}
    pref=${pref/.bed/}
    outfile1=${OUTDIR}/${pref}${SUF}_scores.npz
    outfile2=${GENEDIR}/${pref}${SUF}${SUF2}_gene_scores.npz
    outfile1off=${OUTDIR}/${pref}${SUF}_OFF_scores.npz
    outfile2off=${GENEDIR}/${pref}${SUF}${SUF2}_OFF_gene_scores.npz

    mapfile=${OUTDIR}/tmp/${pref}${SUF}_state_map.txt
    script=${OUTDIR}/tmp/${pref}${SUF}.sh
    errfile=${OUTDIR}/tmp/${pref}${SUF}.err

    if [[ -z $GENEMAP ]] && [[ -f $outfile1 ]]; then 
	if [[ $MAKEOFF -eq  0 ]]; then
	    continue
	fi
	if [[ $MAKEOFF -eq 1 ]] && [[ -f $outfile1off ]]; then
	    continue
	fi
    fi
    if [[ ! -z $GENEMAP ]] && [[ -f $outfile2 ]]; then
	if [[ $MAKEOFF -eq  0 ]]; then
	    continue
	fi 
	if [[ $MAKEOFF -eq 1 ]] && [[ -f $outfile2off ]]; then
	    continue
	fi
    fi

    echo "#!/bin/bash" > $script
    echo "module add python/2.7" >> $script
    echo "module add bedtools/2.18.0" >> $script
    if [ ! -f $outfile1 ]; then
	echo "intersectBed -a $STATEMAP -b $bedfile -wa -u | awk 'BEGIN{OFS=\"\t\"}{print \$4,\$5}' | sort -u > $mapfile" >> $script
	echo "ls ${SCANDIR}/*npz | python $SRCDIR/python/combineRegionScoresMultiFile.py $mapfile $outfile1" >> $script
    fi
    if [[ ! -z $GENEMAP ]] && [[ ! -f $outfile2 ]] ; then
	echo "ls $outfile1 | python $SRCDIR/python/combineRegionScoresMultiFile.py $GENEMAP $outfile2 --cmax" >> $script
    fi

    if [[ $MAKEOFF -eq 1 ]]; then
	if [ ! -f $outfile1off ]; then
	    echo "intersectBed -a $STATEMAP -b $bedfile -wa -v | awk 'BEGIN{OFS=\"\t\"}{print \$4,\$5}' | sort -u > $mapfile" >> $script
	    echo "ls ${SCANDIR}/*npz | python $SRCDIR/python/combineRegionScoresMultiFile.py $mapfile $outfile1off" >> $script
	fi
	if [[ ! -z $GENEMAP ]] && [[ ! -f $outfile2off ]] ; then
	    echo "ls $outfile1off | python $SRCDIR/python/combineRegionScoresMultiFile.py $GENEMAP $outfile2off --cmax" >> $script
	fi
    fi

    qsub -N $pref -P large_mem -l h_vmem=48G -l h_rt=6:00:00 -e $errfile -o /dev/null $script
done


