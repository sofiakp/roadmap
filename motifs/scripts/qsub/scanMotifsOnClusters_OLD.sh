#!/bin/bash

usage()
{
cat <<EOF
usage: `basename $0` options MOTDIR CLUSTDIR OUTDIR 


OPTIONS:
   -h     Show this message and exit

EOF
}

MOTIFLIST=
while getopts "hm:" opt
do
    case $opt in
	h)
	    usage; exit;;
	m)
	    MOTIFLIST=$OPTARG;;
	?)
	    usage
            exit 1;;
    esac    
done

shift "$((OPTIND - 1))"
if [ $# -ne 3 ]; then 
    usage; exit 1;
fi

MOTDIR=$1
CLUSTDIR=$2
OUTDIR=$3

if [ ! -d ${OUTDIR}/tmp ]; then
    mkdir -p ${OUTDIR}/tmp
fi

HOMERSRC="${LABHOME}/software/homer/bin/"
SCRDIR="${LABHOME}/roadmap/src/motifs/"

for bedfile in `ls ${CLUSTDIR}/cluster_1.bed.gz`; do
    pref=$(basename $bedfile)
    pref=${pref/.bed.gz/}
    suf=$(basename $MOTDIR)
    suf=${suf/.txt/}
    script=${OUTDIR}/tmp/${pref}_vs_${suf}.sh
    errfile=${OUTDIR}/tmp/${pref}_vs_${suf}.err
    tmpbed=${OUTDIR}/tmp/${pref}_vs_${suf}_regions.txt

    scorenpz=${OUTDIR}/${pref}_vs_${suf}_scores.npz

    if [[ -f $scorenpz ]]; then
	echo "Output file $scorenpz exists. Skipping" 1>&2
	continue
    fi

    echo "#!/bin/bash" > $script
    echo "module add python/2.7" >> $script
    echo "module add perl-scg" >> $script
    echo "PATH=${HOMERSRC}:${PATH}" >> $script
    echo "zcat $bedfile | awk 'BEGIN{OFS=\"\t\"}{print NR,\$1,\$2,\$3,\"+\"}' > $tmpbed" >> $script
    if [ -f $MOTDIR ]; then
	# MOTDIR is actually a motif file. Just scan the motifs in this.

	scorefile=${OUTDIR}/${pref}_vs_${suf}_scores.txt
	countfile=${OUTDIR}/${pref}_vs_${suf}_counts.txt
    
	echo "perl ${HOMERSRC}/annotatePeaks.pl $tmpbed hg19 -size given -noann -nogene -m $MOTDIR -mscore > $scorefile" >> $script
	echo "perl ${HOMERSRC}/annotatePeaks.pl $tmpbed hg19 -size given -noann -nogene -m $MOTDIR -nmotifs > $countfile" >> $script
    else
	# MOTDIR is a directory with motif files. The list of motif files is read from 
	# MOTIFLIST.

	if [ -z $MOTIFLIST ]; then
	    echo "Motif list is missing. Aborting." 1>&2
	    exit 1
	fi

	for motname in `cat ${MOTIFLIST}`; do
	    suf=${motname/">"/}
	    motfile=${MOTDIR}/${suf}_motif.txt
	    scorefile=${OUTDIR}/${pref}_vs_${suf}_scores.txt
	    countfile=${OUTDIR}/${pref}_vs_${suf}_counts.txt

	    echo "perl ${HOMERSRC}/annotatePeaks.pl $tmpbed hg19 -size given -noann -nogene -m $motfile -mscore > $scorefile" >> $script
	    echo "perl ${HOMERSRC}/annotatePeaks.pl $tmpbed hg19 -size given -noann -nogene -m $motfile -nmotifs > $countfile" >> $script
	done
	# Merge files
	echo "python ${SRCDIR}/python/mergeHomerAnnotate.py $OUTDIR ${pref}_vs_ $MOTIFLIST $scorenpz --insufs _scores.txt,_counts.txt" >> $script

	# Remove all text files
	for motname in `cat ${MOTIFLIST}`; do
	    suf=${motname/">"/}
	    scorefile=${OUTDIR}/${pref}_vs_${suf}_scores.txt
	    countfile=${OUTDIR}/${pref}_vs_${suf}_counts.txt
	    echo "rm $scorefile $countfile" >> $script
	done
    fi
    echo "rm $tmpbed" >> $script
    qsub -q standard -N $pref -l h_vmem=4G -l h_rt=6:00:00 -e $errfile -o /dev/null $script
done
