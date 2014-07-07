#!/bin/bash
OutputDirectory="/srv/gsfs0/projects/kundaje/users/summerStudents/2014/changken/signals"
enhDirectory="/srv/gsfs0/projects/kundaje/commonRepository/epigenomeRoadmap/signal/stdnames30M/macs2signal/pval/"
InputDirectory=""
name=""
Count=0

#You will use the H3K4me3 files for the promoter and dyadic clusters and the H3K4me1 ones for the enhancer clusters

usage()
{
    cat <<EOF
This is the script that you should run to start submitting the cluster bed files for signal processing. 

Input syntax: 
signalComp2.sh -n <enhancer/promoter/dyadic>

Usage:
     -h
          Displays Help
     -n
          Define the type of gene you are analyzing. Recognized inputs are "enhancer", "promoter", "dyadic"

EOF
}

while getopts "hn:" opt
do
    case $opt in
	h)
	    usage;
	    exit;;
	n)
	    name=$OPTARG;;
	?)
	    usage;
	    exit 1;;
    esac
done


if [ "$name" == "dyadic" ]; then
    echo "Directing files to ""/srv/gsfs0/projects/kundaje/users/summerStudents/2014/changken/clusters/$name"
    InputDirectory="/srv/gsfs0/projects/kundaje/users/summerStudents/2014/changken/clusters/$name"
else
    echo "Directing files to ""/srv/gsfs0/projects/kundaje/users/summerStudents/2014/changken/clusters/$name""s"
    InputDirectory="/srv/gsfs0/projects/kundaje/users/summerStudents/2014/changken/clusters/$name""s"
fi

#HEY LISTENA. YOU HAD A PROBLEM WHERE THE NAME TRIES TO OPEN THE DIRECTORY ENHANCER, BUT THE REAL DIRECTORY IS NAMED ENHANCERSSSSSSSS WITH AN S. FIND A WAY TO GET IT TO GO TO THE RIGHT DIRECTORY. 

Count=194  #ls *.bed | wc -l This should be the number of files. Right now its hard coded but whatever. Hackish programming works for the time being. 240 
i=1


#HEY! so you have to change the loop so that it computes ALL of the bigwig files for each cluster. For example. cluster_1.bed will be averaged over all 127 bigwig files, then output it, then proceed onto cluster 2, etc. 

while [[ $i -lt $Count ]]; do
#    echo "i: "$i
	qsub -w e -N CSig_C$i -l h_vmem=3G -l h_rt=00:30:00 -o $OutputDirectory/output.txt -e $OutputDirectory/ErrorCalc.txt -b y /srv/gsfs0/projects/kundaje/users/summerStudents/2014/changken/scripts/computeBigWig.sh -i $InputDirectory/cluster_$i.bed -s $name -n $i -t $i -c $i
#    echo "\n All BW Files computed for cluster "$i" moving onto next cluster." 
    let i=i+1;
done
