#!/bin/bash

usage()
{
cat <<EOF
usage: `basename $0` options MOTFILE OUTDIR

Reads a list of .bed.gz files from the input and Scans the motifs 
in MOTFILE on each of them. MOTFILE should be a in the HOMER format.
For each bedfile read it will write a python npz file in OUTDIR,
containing an NxM matrix scores, where N is the number of regions
in the bedfile and M is the number of motifs.

If the input bed is big, it will be split into chunks of M regions and
then reassembled (so HOMER doesn't run out of memory). You can control
M using the -m option.

OPTIONS:
   -h     Show this message and exit
   -n NUM Number of lines in split files.    
   -r STR Path to a region file. Can be used to combine scores for 
          regions of the input bed files.
   -d STR Path where merged results will be written.
          Default is OUTDIR/merged.
   -m     Input files have names already [default: False] 
EOF
}

NLINES=1000
REGIONFILE=
MERGEDIR=
HASNAME=0
while getopts "hn:r:d:m" opt
do
    case $opt in
	h)
	    usage; exit;;
	n)
	    NLINES=$OPTARG;;
	r) 
	    REGIONFILE=$OPTARG;;
	d) 
	    MERGEDIR=$OPTARG;;
	m)
	    HASNAME=1;;
	?)
	    usage
            exit 1;;
    esac    
done

shift "$((OPTIND - 1))"
if [ $# -ne 2 ]; then 
    usage; exit 1;
fi

MOTFILE=$1
OUTDIR=$2

if [ ! -d ${OUTDIR}/tmp ]; then
    mkdir -p ${OUTDIR}/tmp
fi

if [ ! -z $REGIONFILE ]; then
    if [ -z $MERGEDIR ]; then
	MERGEDIR=${OUTDIR}/merged
    fi
    if [ ! -d ${MERGEDIR} ]; then
	mkdir ${MERGEDIR}
    fi
fi

HOMERSRC="${LABHOME}/software/homer/bin/"
SRCDIR="${LABHOME}/roadmap/src/motifs/"

suf=$(basename $MOTFILE)
suf=${suf/.txt/}

while read -r bedfile; do
    echo $bedfile
    pref=$(basename $bedfile)
    pref=${pref/.bed.gz/}
    script=${OUTDIR}/tmp/${pref}_vs_${suf}.sh
    errfile=${OUTDIR}/tmp/${pref}_vs_${suf}.err
    regionPref=${OUTDIR}/tmp/${pref}_vs_${suf}_regions_
    scorefile=${OUTDIR}/${pref}_vs_${suf}_scores.txt
    countfile=${OUTDIR}/${pref}_vs_${suf}_counts.txt

    scorenpz=${OUTDIR}/${pref}_vs_${suf}_scores.npz
    mergednpz=${MERGEDIR}/${pref}_vs_${suf}_merged_scores.npz

    if [[ -f $scorenpz ]] && [[ -z $REGIONFILE ]] ; then
	#echo "Output file $scorenpz exists. Skipping" 1>&2
	continue
    fi
    if [[ -f $mergednpz ]] && [[ ! -z $REGIONFILE ]] ; then
	#echo "Output file $mergednpz exists. Skipping" 1>&2
	continue
    fi

    if [ -f $scorefile ]; then
	rm $scorefile
    fi
    if [ -f $countfile ]; then
	rm $countfile
    fi

    echo "#!/bin/bash" > $script
    echo "module add python/2.7" >> $script
    echo "module add perl-scg" >> $script
    echo "PATH=${HOMERSRC}:${PATH}" >> $script

    if [ ! -f $scorenpz ]; then
	touch $scorefile
	touch $countfile

	if [ $HASNAME -eq 0 ]; then
	    echo "zcat $bedfile | awk 'BEGIN{OFS=\"\t\"}{print NR,\$1,\$2,\$3,\"+\"}' | split -d -l $NLINES - $regionPref" >> $script
	else
	   echo "zcat $bedfile | awk 'BEGIN{OFS=\"\t\"}{print \$4,\$1,\$2,\$3,\"+\"}' | split -d -l $NLINES - $regionPref" >> $script
	fi 
	echo "for regionFile in \`ls ${regionPref}*\`; do" >> $script
	echo "    perl ${HOMERSRC}/annotatePeaks.pl \$regionFile hg19 -size given -noann -nogene -m $MOTFILE -mscore >> $scorefile" >> $script
	echo "    perl ${HOMERSRC}/annotatePeaks.pl \$regionFile hg19 -size given -noann -nogene -m $MOTFILE -nmotifs >> $countfile" >> $script
	echo "    rm \$regionFile" >> $script
	echo "done" >> $script

	echo "python ${SRCDIR}/python/mergeHomerAnnotate.py $OUTDIR ${pref}_vs_${suf} $scorenpz --insufs _scores.txt,_counts.txt" >> $script
	echo "rm $scorefile $countfile" >> $script
    fi
    if [ ! -z $REGIONFILE ]; then
	idfile=${MERGEDIR}/${pref}_vs_${suf}_region_ids.txt
	echo "module add bedtools/2.18.0" >> $script
	# Get the closest region for each element of the bed file. If there are multiple overlapping
	# keep only one. If d > 0 (non-overlapping region), then output ".".
	echo "closestBed -a $bedfile -b $REGIONFILE -d -t first | awk '{if(\$11==0){print \$10} else{print \".\"}}' > $idfile" >> $script
	echo "python ${SRCDIR}/python/combineRegionScores.py $scorenpz $idfile $mergednpz" >> $script
    fi

    qsub -q standard -N $pref -l h_vmem=8G -l h_rt=6:00:00 -e $errfile -o /dev/null $script
done
