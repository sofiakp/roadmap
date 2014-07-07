#!/bin/bash

usage()
{
cat <<EOF
usage: `basename $0` options SIGNALDIR SIGNAL OUTDIR

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

SIGNALDIR=$1
SIGNAL=$2
OUTDIR=$3

if [ ! -f ${OUTDIR}/tmp ]; then
    mkdir -p ${OUTDIR}/tmp
fi

while read -r bedfile; do
    suf=$(basename $bedfile)
    suf=${suf/.bed.gz/}
    bedtmp=${OUTDIR}/tmp/${suf}.bed
    errfile=${OUTDIR}/tmp/${suf}.err
    script=${OUTDIR}/tmp/${suf}.sh

    echo "#!/bin/bash" > $script
    echo "module add ucsc_tools/2.7.2" >> $script
    echo "zcat $bedfile | awk 'BEGIN{OFS=\"\t\"}{print \$1,\$2,\$3,NR,\$5,\$6}' > $bedtmp" >> $script

    for signalfile in `ls ${SIGNALDIR}/*${SIGNAL}*.bigwig`; do
	pref=$(basename $signalfile)
	pref=${pref/.pval.signal.bigwig/}
	pref=${pref/-/_}
	outfile=${OUTDIR}/${pref}_${suf}.txt
	if [ ! -f $outfile ]; then
	    echo "bigWigAverageOverBed $signalfile $bedtmp $outfile" >> $script 
	fi
    done
    echo "rm $bedtmp" >> $script
    qsub -N bw_$suf -l h_vmem=4G -l h_rt=6:00:00 -e $errfile -o /dev/null $script
done