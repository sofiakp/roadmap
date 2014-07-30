#!/bin/bash

usage()
{
cat <<EOF
usage: `basename $0` options CLUSTPAIRS OUTFILE
Reads a file with pairs of correlated clusters and creates a list of 
correlated enhancers and genes.

The list of enhancer regions is read from ENHFILE. This should have
unique enhancer names in the 4th column. 
The list of promoter regins is read from PROMFILE. This should have 
gene names in the 5th column.

The CLUSTPAIRS file should be like the output of clusterCorr.py.

OPTIONS:
   -h     Show this message and exit
   -w NUM Distance cutoff (in bp) to match enhancers and genes.
   -s NUM Small distance cutoff in case you want to use CTCF sites.
   -p FILE Promoter file.
   -e FILE Enhancer file.   
EOF
}

CTCFFILE=${LABHOME}/roadmap/links/CTCF_intersect.bed.gz
PROMFILE=${LABHOME}/roadmap/segmentations/Oct13/core_15_mergedPromAndFlnk_500bpFromTss_uniq_withDNase_genes.bed
ENHFILE=${LABHOME}/roadmap/segmentations/Oct13/core_15_mergedEnh_notOnProm_withDNase_names.bed
WIN=1000000
SMALLWIN=

while getopts "hw:s:p:e:" opt
do
    case $opt in
	h)
	    usage; exit;;
	w)
	    WIN=$OPTARG;;
	s)
	    SMALLWIN=$OPTARG;;
	p)
	    PROMFILE=$OPTARG;;
	e) 
	    ENHFILE=$OPTARG;;
	?)
	    usage
            exit 1;;
    esac    
done

shift "$((OPTIND - 1))"
if [ $# -ne 2 ]; then 
    usage; exit 1;
fi

CLUSTPAIRS=$1
OUTFILE=$2

HBDIR=/srv/gsfs0/projects/kundaje/commonRepository/epigenomeRoadmap/integrative/regulatoryRegions/ENCODERoadmap/reg2map/HoneyBadger2_release/DNase/p2/

TMPPAIR=${OUTFILE}_tmp
script=${OUTFILE}.sh
errfile=${OUTFILE}.err
tmpprom=${OUTFILE}_prom_tmp.bed
tmpenh=${OUTFILE}_enh_tmp.bed

touch $TMPPAIR

echo "$!/bin/bash" > $script
echo "module add bedtools/2.18.0" >> $script

while read -r cluster1 cluster2; do
    cluster1=${cluster1/promoters/"prom/BED_files_per_cluster"}
    cluster1=${cluster1/enhancers/"enh/BED_files_per_cluster"}
    cluster1=${cluster1/dyadic/"dyadic/BED_files_per_cluster"}
    
    cluster2=${cluster2/promoters/"prom/BED_files_per_cluster"}
    cluster2=${cluster2/enhancers/"enh/BED_files_per_cluster"}
    cluster2=${cluster2/dyadic/"dyadic/BED_files_per_cluster"}

    enhclust=${HBDIR}/${cluster1}.bed.gz
    promclust=${HBDIR}/${cluster2}.bed.gz

    # The first cluster is the enhancer-related one and the second cluster
    # is the promoter-related one.
    # Get all the promoters overlapping the promoter cluster and pair them with all
    # the enhancers overlapping the enhancer cluster (within WIN bp).
    echo "intersectBed -a $PROMFILE -b $promclust -u -wa > $tmpprom" >> $script
    echo "intersectBed -a $ENHFILE -b $enhclust -u -wa > $tmpenh" >> $script
    if [ -z $SMALLWIN ]; then
	echo "windowBed -a $tmpenh -b $tmpprom -w $WIN | awk 'BEGIN{OFS=\"\t\"}{print \$4,\$9}' | sort -u >> $TMPPAIR" >> $script
    else
	echo "windowBed -a $tmpenh -b $tmpprom -w $SMALLWIN | awk 'BEGIN{OFS=\"\t\"}{print \$4,\$9}' | sort -u >> $TMPPAIR" >> $script
	echo "windowBed -a $tmpenh -b $tmpprom -w $WIN | awk 'BEGIN{OFS=\"\t\"}{if(\$2 < \$6){s=\$2}else{s=\$6}; if(\$3 < \$7){e=\$7}else{e=\$3}; print \$1,s,e,\$4,\$9}' | intersectBed -a stdin -b $CTCFFILE -v | awk 'BEGIN{OFS=\"\t\"}{print \$4,\$5}' >> $TMPPAIR" >> $script 
    fi
done < $CLUSTPAIRS

echo "sort -u $TMPPAIR > $OUTFILE" >> $script
echo "rm $tmpprom $tmpenh $TMPPAIR" >> $script

qsub -N getEnhGenePairs -l h_vmem=4G -l h_rt=6:00:00 -e $errfile -o /dev/null $script

