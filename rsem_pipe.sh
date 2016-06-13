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
#3. make plots or not
make_plots=1
#4. delete unecessary files from temp_dir
clean=0
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

##### Obtain Parameters from mapping file using $PBS_ARRAY_INDEX as line number
input_mapper=`sed -n "${PBS_ARRAY_INDEX} p" $mapping_file`
names_mapped=($input_mapper)
NAME=${names_mapped[1]}


echo 'Starting RSEM RNA-seq pipeline for '${NAME}
echo 'Starting RSEM RNA-seq pipeline for '${NAME}
