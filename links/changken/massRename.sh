ls#!/bin/bash

#This is a mass renaming script

Count=1
Stop=86
Directory="/srv/gsfs0/projects/kundaje/users/summerStudents/2014/changken/signals/promoter"

while [[ $Count -lt $Stop ]]; do
    printf -v spacedNumber "%03d" $Count
    mv "$Directory/"$Count"_promoter_"$Count".tab" "$Directory/E"$spacedNumber"_promoter_"$Count".tab"
    #mv $Directory/"E_enhancer_"$Count".tab" "$Directory/E"$spacedNumber"_enhancer_"$Count".tab"
    let Count=Count+1;
done
