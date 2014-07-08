[['['#!/bin/bash
Count=1
InputDirectory='/srv/gsfs0/projects/kundaje/commonRepository/epigenomeRoadmap/integrative/regulatoryRegions/ENCODERoadmap/WM20140519_DNaseI_region_clustering_prom_1kb/BED_files/'
OutputDirectory='/srv/gsfs0/projects/kundaje/users/summerStudents/2014/changken/clusters/promoters'

for i in $(find $InputDirectory -name '*.gz')
do
    echo "Preparing to process cluster "$Count;
    zcat $i | awk 'BEGIN{OFS="\t"}{print $1,$2,$3,"cluster_'$Count'_"NR,$5,$6}' > $OutputDirectory/cluster_$Count.bed;
    let Count=Count+1;
done
