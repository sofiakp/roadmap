#!/bin/bash

inputClusterDir=""
clusterNumber=""
cellType=""
signalName=""
BWdirectory="/srv/gsfs0/projects/kundaje/commonRepository/epigenomeRoadmap/signal/stdnames30M/macs2signal/pval/"
cluster=""

#You will use the H3K4me3 files for the promoter and dyadic clusters and the H3K4me1 ones for the enhancer clusters

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
    echo "Error reading input file"
    exit 1;;
    
    esac
done

if [ $cluster -eq "enhancer" ]; then
    BWDirectory="srv/gsfs0/projects/kundaje/users/summerStudents/2014/changken/clusters/testBigWig/E"$clusterNumber"-H3K4e1.pval.signal.bigwig"
fi

if [ $cluster -eq "promoter" ]; then
    BWDirectory="srv/gsfs0/projects/kundaje/users/summerStudents/2014/changken/clusters/testBigWig/E"$clusterNumber"-H3K4me3.pval.signal.bigwig"

if [ $cluster -eq "dyadic" ]; then
    BWDirectory="srv/gsfs0/projects/kundaje/users/summerStudents/2014/changken/clusters/testBigWig/E"$clusterNumber"-H3K4me3.pval.signal.bigwig"


module add ucsc_tools/2.7.2

bigWigAverageOverBed $BWDirectory $inputClusterDir /srv/gsfs0/projects/kundaje/users/summerStudents/2014/changken/clusters/signals/$cellType/$cellType"_"$signalName"_"$clusterNumber.tab

