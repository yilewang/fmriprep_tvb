#!/usr/bin/bash

# This is a script used to do the data organization and data format conversion for HSAM dataset.
# The user can modify the path based on their own computer.
# The ultimate goal of this script is to run one file then make everything ready for `tvb-ukbb` pipeline

### 0. prepare the path
# the data structural is that, we have 4 folders, 2 groups (HSAM and control). One is structural+fmri and the other one is DTI. 

# save time
preHSAM=/media/yat-lok/BATW/HSAMData
raw_dir=control_raw_dti
# get list of the control cases
dir=$(ls -t --color=never $preHSAM/control | cut -d '.' -f 1)
dir_rawdti=$(ls -t --color=never $preHSAM/raw_dir | cut -d '.' -f 1)


### 1. untar files and move to a new folder
# the reason for this step is to avoid contaminate the original files. We will do that every step during this process

# get list of raw dti cases
mkdir $preHSAM/dti_untar

# use a for loop to untar all the tar.gz file, then rename them to their file names.
for i in $dir_rawdti
do
    tar -C $preHSAM/dti_untar -xzf $preHSAM/$raw_dir/${i}.tar.gz
    mv $preHSAM/dti_untar/raw $preHSAM/dti_untar/$i
done

### 2. convert .PAR .REC files to nii file using `dcm2niix` tool for DTI data

# create a folder to storge the niigz files
mkdir $preHSAM/dti_niigz
for i in $dir_rawdti
do
	cp $preHSAM/dti_untar/$i/*.PAR.gz $preHSAM/dti_niigz/$i
	cp $preHSAM/dti_untar/$i/*.REC.gz $preHSAM/dti_niigz/$i
	gzip -d $preHSAM/dti_niigz/$i/*
	dcm2niix -f %p_%s $preHSAM/dti_niigz/$i
    # clean the redundancy
	rm $preHSAM/dti_niigz/$i/*.PAR*
	rm $preHSAM/dti_niigz/$i/*.REC*
done

### 3. DTI and struct+fMRI matching

# a dir to put DTI and struct+fMRI
mkdir $preHSAM/final
# define a function to help us matching
matching () {
	if [ $1 == $2 ];
	then
		cp $preHSAM/dti_niigz/$3/*DTI* $preHSAM/final/$1
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
	gzip -d $preHSAM/final/$i/struct+orig.*
	gzip -d $preHSAM/final/$i/raw_restinglores_long1+orig.*
	# using 3dAFNItoNIFTI rename the file to what `tvb-ukbb` requires
	3dAFNItoNIFTI -prefix "$i"_T1 $preHSAM/final/$i/struct+orig.
	3dAFNItoNIFTI -prefix "$i"_FMRI_RESTING $preHSAM/final/$i/raw_restinglores_long1+orig.
	mv "$i"_* $i
	rm $preHSAM/final/$i/raw_restinglores*
	rm $preHSAM/final/$i/struct+orig.*
    # compress them to nii.gz 
    gzip $preHSAM/final/$i/*.nii
	echo "$i" is done	
done


### 5. rename DTI files
# the reason why we have this step is because the matching process. We cannot rename the DTI file before the matching finishes. It's a special condition due to the data itself.

mkdir $preHSAM/final2
prefix=$preHSAM/final2
for i in $dir
do
	file=$(ls -t $prefix/$i/*DTI* | head -n 1)
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

	