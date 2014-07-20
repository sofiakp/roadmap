#!/bin/bash

usage()
{
cat <<EOF
usage: `basename $0` options OUTDIR
Merge enhancer, promoter, and dyadic DNase peaks for each cell type.

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
if [ $# -ne 1 ]; then 
    usage; exit 1;
fi

OUTDIR=$1

if [ ! -f ${OUTDIR}/tmp ]; then
    mkdir -p ${OUTDIR}/tmp
fi

HBDIR=/srv/gsfs0/projects/kundaje/commonRepository/epigenomeRoadmap/integrative/regulatoryRegions/ENCODERoadmap/reg2map/HoneyBadger2_release/DNase/p2/

for filename in `ls ${HBDIR}/enh/BED_files_per_sample/`; do
    celltype=$(basename $filename)
    celltype=${celltype/regions_enh_/}
    celltype=${celltype/.bed.gz/}

    f1=${HBDIR}/enh/BED_files_per_sample/$filename
    f2=${HBDIR}/prom/BED_files_per_sample/regions_prom_${celltype}.bed.gz
    f3=${HBDIR}/dyadic/BED_files_per_sample/regions_dyadic_${celltype}.bed.gz
    
    outfile=${OUTDIR}/regions_all_${celltype}.bed.gz
    errfile=${OUTDIR}/tmp/regions_all_${celltype}.err
    script=${OUTDIR}/tmp/regions_all_${celltype}.sh

    echo "#!/bin/bash" > $script
    echo "module add bedtools/2.18.0" >> $script
    echo "zcat $f1 $f2 $f3 | sort -V | mergeBed -i stdin | gzip > $outfile" >> $script
    qsub -N ${celltype}_regions_all -l h_vmem=4G -l h_rt=6:00:00 -e $errfile -o /dev/null $script
done