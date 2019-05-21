#!/bin/bash
#SBATCH -p batch
#SBATCH -N 1
#SBATCH -n 16
#SBATCH --time=24:00:00
#SBATCH --mem=48GB
#SBATCH -o /data/biohub/20180328_Atkins_RatFracture/slurm/%x_%j.out
#SBATCH -e /data/biohub/20180328_Atkins_RatFracture/slurm/%x_%j.err
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=stephen.pederson@adelaide.edu.au

## Note that the FastQC reports on the raw data were previously generated 
## for a preliminary meeting

## Cores
CORES=16

## Modules
module load FastQC/0.11.7
module load STAR/2.7.0d-foss-2016b
module load SAMtools/1.9-foss-2016b
module load AdapterRemoval/2.2.1-foss-2016b
module load Subread/1.5.2-foss-2016b

## Genomic Data Files
REFS=/data/biorefs/reference_genomes/ensembl-release-96/rattus_norvegicus
GTF=${REFS}/Rattus_norvegicus.Rnor_6.0.96.chr.gtf.gz
if [ ! -f "${GTF}" ]; then
  echo -e "Couldn't find ${GTF}"
  exit 1
fi

## Directories
PROJROOT=/data/biohub/20180328_Atkins_RatFracture

## Directories for Initial FastQC
RAWDATA=${PROJROOT}/0_rawData

## Setup for Trimmed data
TRIMDATA=${PROJROOT}/1_trimmedData

## Setup for genome alignment
ALIGNDATA=${PROJROOT}/2_alignedData


##--------------------------------------------------------------------------------------------##
## FastQC on the raw data 
##--------------------------------------------------------------------------------------------##

fastqc -t ${CORES} -o ${RAWDATA}/FastQC --noextract ${RAWDATA}/fastq/*fastq.gz

##--------------------------------------------------------------------------------------------##
## Trimming the Merged data
##--------------------------------------------------------------------------------------------##

for R1 in ${RAWDATA}/fastq/*R1.fastq.gz
  do

    echo -e "Currently working on ${R1}"

    # Now create the output filenames
    out1=${TRIMDATA}/fastq/$(basename $R1)
    BNAME=${TRIMDATA}/fastq/$(basename ${R1%_R1.fastq.gz})
    echo -e "Output file 1 will be ${out1}"

    echo -e "Trimming:\t${R1}"
    # Trim
    AdapterRemoval \
      --gzip \
      --trimns \
      --trimqualities \
      --minquality 30 \
      --minlength 50 \
      --threads ${CORES} \
      --basename ${BNAME} \
      --output1 ${out1} \
      --file1 ${R1} 

  done

# Move the log files into their own folder
mv ${TRIMDATA}/fastq/*settings ${TRIMDATA}/log

# Run FastQC
fastqc -t ${CORES} -o ${TRIMDATA}/FastQC --noextract ${TRIMDATA}/fastq/*fastq.gz


##--------------------------------------------------------------------------------------------##
## Aligning trimmed data to the genome
##--------------------------------------------------------------------------------------------##

## Aligning, filtering and sorting
for R1 in ${TRIMDATA}/fastq/*R1.fastq.gz
  do

  BNAME=$(basename ${R1%_R1.fastq.gz})
  echo -e "STAR will align:\t${R1}"

    STAR \
        --runThreadN ${CORES} \
        --genomeDir ${REFS}/star \
        --readFilesIn ${R1} \
        --readFilesCommand gunzip -c \
        --outFileNamePrefix ${ALIGNDATA}/bams/${BNAME} \
        --outSAMtype BAM SortedByCoordinate

  done

# Move the log files into their own folder
mv ${ALIGNDATA}/bams/*out ${ALIGNDATA}/log
mv ${ALIGNDATA}/bams/*tab ${ALIGNDATA}/log

# Fastqc and indexing
for BAM in ${ALIGNDATA}/bams/*.bam
 do
   fastqc -t ${CORES} -f bam_mapped -o ${ALIGNDATA}/FastQC --noextract ${BAM}
   samtools index ${BAM}
 done


##--------------------------------------------------------------------------------------------##
## featureCounts
##--------------------------------------------------------------------------------------------##

## Feature Counts - obtaining all sorted bam files
sampleList=`find ${ALIGNDATA}/bams -name "*out.bam" | tr '\n' ' '`

## Running featureCounts on the sorted bam files
${featureCounts} -Q 10 \
  -s 2 \
  --fracOverlap 1 \
  -T ${CORES} \
  -a <(zcat ${GTF}) \
  -o ${ALIGNDATA}/featureCounts/counts.out ${sampleList}

## Storing the output in a single file
cut -f1,7- ${ALIGNDATA}/featureCounts/counts.out | \
sed 1d > ${ALIGNDATA}/featureCounts/genes.out


##--------------------------------------------------------------------------------------------##
## kallisto 
##--------------------------------------------------------------------------------------------##

## Just submit these as independent jobs at this point as we don't need to do any
## post alignment QC now
for R1 in ${TRIMDATA}/fastq/*R1.fastq.gz
  do
  	sbatch ${PROJROOT}/bash/kallistoSingle.sh ${R1}
  done
