#!/bin/bash

inputClusterDir=""
clusterNumber=""
cellType=""
signalName=""
BWdirectory="/srv/gsfs0/projects/kundaje/commonRepository/epigenomeRoadmap/signal/stdnames30M/macs2signal/pval/"
cluster=""

#You will use the H3K4me3 files for the promoter and dyadic clusters and the H3K4me1 ones for the enhancer clusters

usage()
{
    cat <<EOF
This script needs to have the directory to the clusters you will be analyzing, the signal name, cluster number, cell type and cluster name. 
EOF
}

while getopts "i:s:n:t:c:" opt
do
    case $opt in
    i)
	    inputClusterDir=$OPTARG;;
    
    s)
	    signalName=$OPTARG;;

    n)
	    clusterNumber=$OPTARG;;

    t)
	    cellType=$OPTARG;;

    c)
	    cluster=$OPTARG;;

    ?)
	    usage
	    exit 1;;
    esac
done

BWCount=129 #Number of BW files to look though. ends at 130 cause it goes from 1-129
bw=1 #BW iterator byte

while [[ $bw -lt $BWCount ]]; do
printf -v tempBWnumber "%03d" $bw

if [[ $signalName = "enhancer" ]]; then
    BWDirectory="/srv/gsfs0/projects/kundaje/commonRepository/epigenomeRoadmap/signal/stdnames30M/macs2signal/pval/E$tempBWnumber-H3K4me1.pval.signal.bigwig"
fi

if [[ $signalName = "promoter" ]]; then
    BWDirectory="/srv/gsfs0/projects/kundaje/commonRepository/epigenomeRoadmap/signal/stdnames30M/macs2signal/pval/E$tempBWnumber-H3K4me3.pval.signal.bigwig"
fi

if [[ $signalName = "dyadic" ]]; then
    BWDirectory="/srv/gsfs0/projects/kundaje/commonRepository/epigenomeRoadmap/signal/stdnames30M/macs2signal/pval/E$tempBWnumber-H3K4me3.pval.signal.bigwig"
fi

echo "Adding module"
module add ucsc_tools/2.7.2

echo "Calculating BW"
bigWigAverageOverBed $BWDirectory $inputClusterDir /srv/gsfs0/projects/kundaje/users/summerStudents/2014/cha\
ngken/signals/$signalName/"E"$tempBWnumber"_"$signalName"_"$cluster.tab

#echo "bigWigAverageOverBed $BWDirectory $inputClusterDir /srv/gsfs0/projects/kundaje/users/summerStudents/2014/changken/signals/$signalName/"E"$tempBWnumber"_"$signalName"_"$cluster.tab"
let bw=bw+1;
done