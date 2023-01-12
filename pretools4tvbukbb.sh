#!/usr/bin/bash

# This is a script used to do the data organization and data format conversion for HSAM dataset.
# The user can modify the path based on their own computer.
# The ultimate goal of this script is to run one file then make everything ready for `tvb-ukbb` pipeline

### 0. prepare the path
# the data structural is that, we have 4 folders, 2 groups (HSAM and control). One is structural+fmri and the other one is DTI. 

# save time
preHSAM=/media/yat-lok/BATW/HSAMData
# get list of the control cases
dir=$(ls -t --color=never $preHSAM/control | cut -d '.' -f 1)
dir_rawdti=$(ls -t --color=never $preHSAM/control_raw_dti | cut -d '.' -f 1)


### 1. untar files and move to a new folder
# the reason for this step is to avoid contaminate the original files. We will do that every step during this process

# get list of raw dti cases
mkdir $preHSAM/control_dti_untar
cd $preHSAM/control_dti_untar

# use a for loop to untar all the tar.gz file, then rename them to their file names.
for i in $dir_rawdti
do
    tar -C . -xzf $preHSAM/control_raw_dti/${i}.tar.gz
    mv raw $i
done

### 2. convert .PAR .REC files to nii file using `dcm2niix` tool for DTI data

# create a folder to storge the niigz files
mkdir control_dti_niigz
for i in $dir_rawdti
do
	cp $preHSAM/control_dti_untar/$i/*.PAR.gz $preHSAM/control_dti_niigz/$i
	cp $preHSAM/control_dti_untar/$i/*.REC.gz $preHSAM/control_dti_niigz/$i
	gzip -d $preHSAM/control_dti_niigz/$i/*
	dcm2niix -f %p_%s $preHSAM/control_dti_niigz/$i
    # clean the redundancy
	rm $preHSAM/control_dti_niigz/$i/*.PAR*
	rm $preHSAM/control_dti_niigz/$i/*.REC*
done

### 3. DTI and struct+fMRI matching

# a dir to put DTI and struct+fMRI
mkdir control_final
# define a function to help us matching
matching () {
	if [ $1 == $2 ];
	then
		cp $preHSAM/control_dti_niigz/$3/*DTI* $preHSAM/control_final/$1
		echo "matching done"
	fi
}

for i in $dir
do
	matching $i 122744 S1
	matching $i 122766 S10
	matching $i 123342 S11
	matching $i 123498 S12
	matching $i 123597 S13
	matching $i 123598 S14
	matching $i 123599 S15
	matching $i 123603 S2
	matching $i 123606 S4
	matching $i 123610 S5
	matching $i 123611 S7
	matching $i 123612 S8
	matching $i 123616 S9
	matching $i 123618 s6
done

### 4. fmri converting process

for i in $dir
do
	gzip -d $preHSAM/control_final/$i/struct+orig.*
	gzip -d $preHSAM/control_final/$i/raw_restinglores_long1+orig.*
	# using 3dAFNItoNIFTI rename the file to what `tvb-ukbb` requires
	3dAFNItoNIFTI -prefix "$i"_T1 $preHSAM/control_final/$i/struct+orig.
	3dAFNItoNIFTI -prefix "$i"_FMRI_RESTING $preHSAM/control_final/$i/raw_restinglores_long1+orig.
	mv "$i"_* $i
	rm $preHSAM/control_final/$i/raw_restinglores*
	rm $preHSAM/control_final/$i/struct+orig.*
    # compress them to nii.gz 
    gzip $preHSAM/control_final/$i/*.nii
	echo "$i" is done	
done


### 5. rename DTI files
# the reason why we have this step is because the matching process. We cannot rename the DTI file before the matching finishes. It's a special condition due to the data itself.

mkdir $preHSAM/control_final2

for i in $dir
do
	file=$(ls -t $preHSAM/control_final2/$i/*DTI* | head -n 1)
	if [ -f "$file" ];
	then
		echo "$i" have DTI files
		mv $prefix/$i/*.bval $prefix/$i/"$i"_dwi.bval
		mv $prefix/$i/*.bvec $prefix/$i/"$i"_dwi.bvec
		mv $prefix/$i/*_6.nii.gz $prefix/$i/"$i"_dwi.nii.gz
		mv $prefix/$i/*.json $prefix/$i/"$i"_dwi.json
	else
		echo "$i" does not have DTI files
	fi
done

	