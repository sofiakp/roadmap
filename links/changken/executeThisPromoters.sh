#This is for the promoter genes, 85 known gz files
OutputDirectory='/srv/gsfs0/projects/kundaje/users/summerStudents/2014/changken/clusters/'

qsub -w e -N KenUnpackJob -l h_vmem=1G -l h_rt=00:01:00 -o $OutputDirectory/output.txt -e $OutputDirectory/ErrorRename.txt renamePromoter.sh
