#!/bin/bash
#PBS -P rnaseq_nod
#PBS -N rsem-pipe
#PBS -J 1-12
#PBS -j oe
#PBS -q workq
#PBS -o /lustre/scratch/users/falko.hofmann/log/160603_rsem-rna/160603_rsem-rna_^array_index^_mapping.log
#PBS -l walltime=24:00:00
#PBS -l select=1:ncpus=8:mem=64gb

# === begin ENVIRONMENT SETUP ===
####set to 0 (false) or 1 (true) to let the repsective code block run
#1. run rsem
run_rsem=1
#2. make plots or not
make_plots=1
#3. delete unecessary files from temp_dir
clean=0
##### specify RSEM parameters
alginer='bowtie'

##### specify folders and variables #####
#set script dir
pipe_dir=/lustre/scratch/users/$USER/pipes/rsem-rna-seq-pipeline
#set ouput base dir
base_dir=/lustre/scratch/users/$USER/rna_seq
#folders for input fastq files
fastq_files=
#folders for temp files
temp_dir=$base_dir/temp
#folder for aligment logs
log_files=$base_dir/logs
#folder for rsem reference
rsem_ref=

##### load modules and assign local repos#####
##### load required modules #####
module load RSEM/1.2.29-foss-2015a
# conditional loading of modules based on aligner to be used by RSEM
if [ "$aligner" -eq "bowtie" ]; then
  module load Bowtie/1.1.2-foss-2015b
fi
if [ "$aligner" -eq "bowtie2" ]; then
  module load Bowtie2/2.2.7-foss-2015b
fi
#TODO: --star not yet supported? if so add star mapping command
if [ "$aligner" -eq "star" ]; then
  module load STAR/2.5.1b-goolf-1.4.10
fi
if [ $make_plots -eq 1 ]; then
  module load R/3.2.3-foss-2016a

fi
##### Obtain Parameters from mapping file using $PBS_ARRAY_INDEX as line number
input_mapper=`sed -n "${PBS_ARRAY_INDEX} p" $mapping_file`
names_mapped=($input_mapper)
sample_name=${names_mapped[1]}

echo 'Starting RSEM RNA-seq pipeline for: '${NAME}
echo 'Rsem reference: ' $rsem_ref
echo 'Aligner to be used: ' $aligner

rsem-calculate-expression --num-threads 8 \
  --paired-end $fastq_files/${NAME}.end1.fq $fastq_files/${NAME}.end2.fq \
  $rsem_ref $sample_name

rsem-plot-model $sample_name $sample_name.pdf

echo 'Finished RSEM RNA-seq pipeline for: '${NAME}
