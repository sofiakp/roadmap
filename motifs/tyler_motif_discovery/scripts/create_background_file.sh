#!/bin/bash

# send mail when job ends or aborts
# -m ea
#
# specify an email address
# -M tsdavis@stanford.edu
#
# check for errors in the job submission options
# -w e
#
# print error output to error.log
# -e bgfile_error.log
#
# print standard output to stdout.txt
# -o bgfile_stdout.txt
#
# Set the working directory for the job
# -wd /home/tsdavis


#create bed file with all regions EXCEPT current cluster
xpath=${1%/*}
xbase=${1##*/}
xpref=${xbase%.*}
if [ -n "$2" ]; then
	background_file=$2
else
	background_file="${xpref}_background.bed"
fi

cluster_file_list=""
cluster_files="${xpath}/cluster_*.bed"
for var in $cluster_files
do
	if [ "$var" != "$1" ]; then
        	cluster_file_list="$cluster_file_list $var"
	fi
done
#echo $cluster_file_list
cat $cluster_file_list > $background_file
#bedtools complement -i $1 -g all_enhancers.bed > background/$background_file
#./add_unique_ids.sh background

