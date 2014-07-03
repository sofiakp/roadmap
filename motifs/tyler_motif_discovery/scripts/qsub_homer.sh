#!/bin/bash

source ~/.bash_profile
#split up file and path names in order to dynamically create outputs
xpath=${1%/*}
xbase=${1##*/}
xpref=${xbase%.*}


if [[ -n "$2" ]]; then
	output_dir=$2
else
	output_dir="${xpref}_motifs"
fi

error_file="${output_dir}/${xpref}_error.log"
stdout_file="${output_dir}/${xpref}_stdout.txt"
job_name=$(echo $output_dir | tr "/" "_")

if [[ ! -d "$output_dir" ]]; then
	mkdir $output_dir
fi

#this gives the name of the directory which this script is in.
#we need this because even though the scripts below (eg "homer_on_cluster.sh")
#are executable from anywhere, qsub needs the entire file path. This means,
#we need to keep these files and THIS (current) file in the same directory 
#for this to not break.
this_script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


if [[ "$#" -eq 3 && "$3" = "default" ]]; then
	qsub -N $job_name -m ea -M ${USER}@stanford.edu -w e -e $error_file -o $stdout_file -wd $(pwd) -l h_rt=12:00:00 -l h_vmem=10G ${this_script_dir}/homer_default_bg.sh $1 $output_dir

else
	
	qsub -N $job_name -m ea -M ${USER}@stanford.edu -w e -e $error_file -o $stdout_file -wd $(pwd) -l h_rt=12:00:00 -l h_vmem=10G ${this_script_dir}/homer_on_cluster.sh $1 $output_dir

fi
