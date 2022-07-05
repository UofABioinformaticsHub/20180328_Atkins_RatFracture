#!/bin/bash

## Directories
PROJROOT=/data/biohub/20180328_Atkins_RatFracture
TRIMDATA=${PROJROOT}/1_trimmedData

## Setup for kallisto output
mkdir -p ${PROJROOT}/3_kallisto

## Fire off the alignments
FQ=$(ls ${TRIMDATA}/fastq/*R1.fastq.gz)
echo -e "Found:\n\t${FQ}"

for F1 in ${FQ}
	do 
	sbatch ${PROJROOT}/bash/singleKallisto.sh ${F1}
done
