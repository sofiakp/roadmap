#!/bin/bash

usage()
{
cat <<EOF
usage: `basename $0` options MOTDIR CLUSTDIR OUTDIR 


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

suf=$(basename $MOTDIR)
suf=${suf/.txt/}

for bedfile in `ls ${CLUSTDIR}/cluster_86.bed.gz`; do
    pref=$(basename $bedfile)
    pref=${pref/.bed.gz/}
    script=${OUTDIR}/tmp/${pref}_vs_${suf}.sh
    errfile=${OUTDIR}/tmp/${pref}_vs_${suf}.err
    tmpbed=${OUTDIR}/tmp/${pref}_vs_${suf}_regions.txt

    if [[ -f $scorefile ]] && [[ -f $countfile ]]; then
	echo "Output files for $pref exist. Skipping" 1>&2
	continue
    fi

    echo "#!/bin/bash" > $script
    echo "module add perl-scg" >> $script
    echo "PATH=${HOMERSRC}:${PATH}" >> $script
    echo "zcat $bedfile | awk 'BEGIN{OFS=\"\t\"}{print NR,\$1,\$2,\$3,\"+\"}' > $tmpbed" >> $script
    if [ -f $MOTDIR ]; then
	scorefile=${OUTDIR}/${pref}_vs_${suf}_scores.txt
	countfile=${OUTDIR}/${pref}_vs_${suf}_counts.txt
	echo "perl ${HOMERSRC}/annotatePeaks.pl $tmpbed hg19 -size given -noann -nogene -m $MOTDIR -mscore > $scorefile" >> $script
	echo "perl ${HOMERSRC}/annotatePeaks.pl $tmpbed hg19 -size given -noann -nogene -m $MOTDIR -nmotifs > $countfile" >> $script
    else
	for motfile in `ls ${MOTDIR}/*motif.txt`; do
	    suf=$(basename $motfile)
	    suf=${suf/.txt/}
	    scorefile=${OUTDIR}/${pref}_vs_${suf}_scores.txt
	    countfile=${OUTDIR}/${pref}_vs_${suf}_counts.txt
	    echo "perl ${HOMERSRC}/annotatePeaks.pl $tmpbed hg19 -size given -noann -nogene -m $motfile -mscore > $scorefile" >> $script
	    echo "perl ${HOMERSRC}/annotatePeaks.pl $tmpbed hg19 -size given -noann -nogene -m $motfile -nmotifs > $scorefile" >> $script
	done
	# TODO: Merge files
	# Remove all text files
	for motfile in `ls ${MOTDIR}/*motif.txt`; do
	    suf=$(basename $motfile)
	    suf=${suf/.txt/}
	    scorefile=${OUTDIR}/${pref}_vs_${suf}_scores.txt
	    countfile=${OUTDIR}/${pref}_vs_${suf}_counts.txt
	    #echo "rm $scorefile $countfile" >> $script
	done
    fi
    echo "rm $tmpbed" >> $script
    qsub -q standard -N $pref -l h_vmem=4G -l h_rt=2:00:00 -e $errfile -o /dev/null $script
done
