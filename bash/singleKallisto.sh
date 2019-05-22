#!/bin/bash
#SBATCH -p batch
#SBATCH -N 1
#SBATCH -n 1
#SBATCH --time=01:00:00
#SBATCH --mem=4GB
#SBATCH -o /data/biohub/20180328_Atkins_RatFracture/slurm/%x_%j.out
#SBATCH -e /data/biohub/20180328_Atkins_RatFracture/slurm/%x_%j.err
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=stephen.pederson@adelaide.edu.au

# Load modules
module load kallisto/0.43.1-foss-2016b
module load SAMtools/1.3.1-foss-2016b

## Reference Files
IDX=/data/biorefs/reference_genomes/ensembl-release-96/rattus_norvegicus/kallisto/Rattus_norvegicus.Rnor_6.0.cdna.all.idx

## Directories
PROJROOT=/data/biohub/20180328_Atkins_RatFracture
TRIMDATA=${PROJROOT}/1_trimmedData

## Setup for kallisto output
ALIGNDATA=${PROJROOT}/3_kallisto

## Now organise the input files
F1=$1

## Organise the output files
OUTDIR=${ALIGNDATA}/$(basename ${F1%_R1.fastq.gz})
echo -e "Creating ${OUTDIR}"
mkdir -p ${OUTDIR}
OUTBAM=${OUTDIR}/$(basename ${F1%_R1.fastq.gz}.bam)

echo -e "Currently aligning:\n\t${F1}"
echo -e "Output will be written to ${OUTDIR}"
kallisto quant \
	-b 50 \
	--single \
	--rf-stranded \
	-l 300 \
	-s 20 \
	-i ${IDX} \
	-o ${OUTDIR} \
	${F1} 