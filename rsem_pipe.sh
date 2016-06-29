#!/bin/bash
#PBS -P rnaseq_nod
#PBS -N rsem-pipe
#PBS -J 1-5
#PBS -j oe
#PBS -q workq
#PBS -o /lustre/scratch/users/falko.hofmann/log/160628_rsem-rna/160628_rsem-rna_^array_index^_mapping.log
#PBS -l walltime=24:00:00
#PBS -l select=1:ncpus=8:mem=48gb

# === begin ENVIRONMENT SETUP ===
####set to 0 (false) or 1 (true) to let the repsective code block run
#1. run rsem
run_rsem=1
#2. make plots or not
make_plots=1
#3. delete unecessary files from temp_dir
clean=0
##### specify RSEM parameters
aligner="star"
##### specify folders and variables #####
#set script dir
pipe_dir=/lustre/scratch/users/$USER/pipelines/rsem-rna-seq-pipeline
#set ouput base dir
base_dir=/lustre/scratch/users/$USER/rna_seq
#folder for aligment logs
log_files=$base_dir/logs
#folder for rsem reference
rsem_ref_dir=/lustre/scratch/users/$USER/indices/rsem/$aligner/nod_v01
#add folder basename as prefix (follows convention from rsem_make_reference)
rsem_ref=$rsem_ref_dir/$(basename $rsem_ref_dir)
#location of the mapping file for the array job
pbs_mapping_file=$pipe_dir/pbs_mapping_file.txt
#super folder of the temp dir, script will create subfolders with $sample_name
temp_dir=$base_dir/temp/

##### conditional loading of the required modules #####
module load RSEM/1.2.30-foss-2016a
# conditional loading of modules based on aligner to be used by RSEM
if [ $aligner == "bowtie" ]; then
  module load Bowtie/1.1.2-foss-2015b
fi
if [ $aligner == "bowtie2" ]; then
  module load Bowtie2/2.2.7-foss-2015b
fi
if [ $aligner == "star" ]; then
  module load rna-star/2.5.2a-foss-2016a
fi
if [ $make_plots -eq 1 ]; then
  module load R/3.2.3-foss-2016a
fi
##### Obtain Parameters from mapping file using $PBS_ARRAY_INDEX as line number
input_mapper=`sed -n "${PBS_ARRAY_INDEX} p" $pbs_mapping_file` #read mapping file
names_mapped=($input_mapper)
sample_dir=${names_mapped[1]} # get the sample dir
sample_name=`basename $sample_dir` #get the base name of the dir as sample name

echo 'Starting RSEM RNA-seq pipeline for: '$sample_name
echo 'Rsem reference: ' $rsem_ref
echo 'Aligner to be used: ' $aligner
echo 'Mapping file: ' $pbs_mapping_file

#make output folder
mkdir -p $sample_dir/rsem/
cd $sample_dir/rsem/

#folders for temp files
temp_dir_s=$temp_dir/$sample_name
mkdir -p $temp_dir_s

# run rsem to calculate the expression levels
# --estimate-rspd: estimate read start position to check if the data has bias
# --output-genome-bam: output bam file as genomic, not transcript coordinates
# --seed 12345 set seed for reproducibility of rng
# --calc-ci calcutates 95% confidence interval of the expression values
# --ci-memory 30000 set memory
if [ $run_rsem -eq 1 ]; then
  rsem-calculate-expression --$aligner --num-threads 8 \
    --temporary-folder $temp_dir_s \
    --fragment-length-min 50 \
    --fragment-length-max 500 \
    --fragment-length-mean 120 \
    --estimate-rspd \
    --output-genome-bam \
    --seed 12345 \
    --calc-ci \
    --ci-memory 30000 \
    --paired-end $sample_dir/$sample_name.trimmed.1.fastq \
                 $sample_dir/$sample_name.trimmed.2.fastq \
    $rsem_ref $sample_name >& $log_files/$sample_name.rsem
fi

#run the rsem plot function
if [ $make_plots -eq 1 ]; then
  rsem-plot-model $sample_dir $sample_dir/$sample_name.pdf
fi

#delete the temp files
if [ $clean -eq 1]: then
  rm -rf $temp_dir_s
fi
echo 'Finished RSEM RNA-seq pipeline for: '$sample_name
