#!/bin/bash
OutputDirectory="/srv/gsfs0/projects/kundaje/users/summerStudents/2014/changken/signals"
enhDirectory="/srv/gsfs0/projects/kundaje/commonRepository/epigenomeRoadmap/signal/stdnames30M/macs2signal/pval/"
InputDirectory=""
#You will use the H3K4me3 files for the promoter and dyadic clusters and the H3K4me1 ones for the enhancer clusters

usage()
{
    cat <<EOF
Specify a directory with -p. This directory should point to the locations of the .bed files you want to compute
signals for. Make sure you use an absolute path or else funny things might happen.  
EOF
}

while getopts "hp"
do
    case $opt in
	h)
	    usage;
	    exit;;
	p)
	    InputDirectory=$OPTARG;;
	?)
	    usage
	    exit 1;;
    esac
done

for i in $(find $InputDirectory -name '*.bed')
do
    
done
