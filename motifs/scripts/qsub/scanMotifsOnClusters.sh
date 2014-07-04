#!/bin/bash

usage()
{
cat <<EOF
usage: `basename $0` options MOTDIR CLUSTDIR OUTDIR 

OPTIONS:
   -h     Show this message and exit

EOF
}

NLINES=1000
while getopts "hn:" opt
do
    case $opt in
	h)
	    usage; exit;;
	n)
	    NLINES=$OPTARG;;
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

    if [[ -f $scorenpz ]]; then
	echo "Output file $scorenpz exists. Skipping" 1>&2
	continue
    fi

    if [ -f $scorefile ]; then
	rm $scorefile
    fi
    if [ -f $countfile ]; then
	rm $countfile
    fi

    touch $scorefile
    touch $countfile

    echo "#!/bin/bash" > $script
    echo "module add python/2.7" >> $script
    echo "module add perl-scg" >> $script
    echo "PATH=${HOMERSRC}:${PATH}" >> $script
    echo "zcat $bedfile | awk 'BEGIN{OFS=\"\t\"}{print NR,\$1,\$2,\$3,\"+\"}' | split -d -l $NLINES - $regionPref" >> $script
    
    echo "for regionFile in \`ls ${regionPref}*\`; do" >> $script
    echo "    perl ${HOMERSRC}/annotatePeaks.pl \$regionFile hg19 -size given -noann -nogene -m $MOTFILE -mscore >> $scorefile" >> $script
    echo "    perl ${HOMERSRC}/annotatePeaks.pl \$regionFile hg19 -size given -noann -nogene -m $MOTFILE -nmotifs >> $countfile" >> $script
    echo "    rm \$regionFile" >> $script
    echo "done" >> $script

    echo "python ${SRCDIR}/python/mergeHomerAnnotate.py $OUTDIR ${pref}_vs_${suf} $scorenpz --insufs _scores.txt,_counts.txt" >> $script
    echo "rm $scorefile $countfile" >> $script

    qsub -q standard -N $pref -l h_vmem=4G -l h_rt=6:00:00 -e $errfile -o /dev/null $script
done
