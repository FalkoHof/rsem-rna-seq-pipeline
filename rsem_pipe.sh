#!/bin/bash
#PBS -P rnaseq_nod
#PBS -N rsem-pipe
#PBS -J 1-2
#PBS -j oe
#PBS -q workq
#PBS -o /lustre/scratch/users/falko.hofmann/log/160705_rsem/rsem-rna_^array_index^_mapping.log
#PBS -l walltime=24:00:00
#PBS -l select=1:ncpus=8:mem=48gb

# === begin ENVIRONMENT SETUP ===
####set to 0 (false) or 1 (true) to let the repsective code block run
#1. run rsem
run_rsem=1
#2. make plots or not
make_plots=0
#3. delete unecessary files from temp_dir
clean=0
##### specify RSEM parameters
aligner="star"
seq_mode="PE"
file_type="fastq"
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
temp_dir=$base_dir/temp

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

#print some output for logging
echo '#########################################################################'
echo 'Starting RSEM RNA-seq pipeline for: '$sample_name
echo 'Rsem reference: ' $rsem_ref
echo 'Aligner to be used: ' $aligner
echo 'Mapping file: ' $pbs_mapping_file
echo 'Selected file type: ' $file_type
echo 'Selected sequencing mode: ' $seq_mode
echo '#########################################################################'

#some paramter checking
if [ $seq_mode != "PE" ] && [ $seq_mode != "SE" ]; then
  echo "Wrong parameters selected for seq_mode! Aborting." 1>&2
  exit 1
fi
if [ $file_type != "bam" ] && [ $file_type != "fastq" ]; then
  echo "Wrong parameters selected for file_type! Aborting." 1>&2
  exit 1
fi

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

#some function to check the number of files present
function get_files {
  # get all files at a location with a specific extention
  f=($(ls "$1" | grep -e "$2"))
  echo $f
}

if [ $run_rsem -eq 1 ]; then
  #initalize variable
  rsem_opts=""
  #add paired-end flag if data is PE
  if [ $seq_mode = "PE" ]; then
    rsem_opts=$rsem_opts"--paired-end "
  fi
  if [ "$file_type" = "bam" ]; then
    f=($(ls  $sample_dir| grep -e ".bam"))
    #f=$(get_files $sample_dir bam)
    # get lenght of the array
    file_number=${#f[@]}
    if [ "$file_number" = "1" ]; then
      rsem_opts=$rsem_opts"--bam $sample_dir/$f"
    else
      echo "Only one bam file per sample folder allowed! Aborting."\
           "Files present: $file_number" 1>&2
      exit 1
    fi
  elif [ "$file_type" = "fastq" ]; then
    rsem_opts=$rsem_opts
    f=($(ls  $sample_dir| grep -e ".fq\|.fastq"))
    #f=$(get_files $sample_dir .fq\|.fastq)
    file_number=${#f[@]}
    #some error handling. Check if only the expected number of fq files is there
    if [ $file_number -eq 1 ]  && [ "$seq_mode" = "SE" ]; then
      rsem_opts=$rsem_opts"$sample_dir/$f"
    elif [ $file_number -eq 2 ]  && [ "$seq_mode" = "PE" ]; then
      rsem_opts=$rsem_opts"$sample_dir/${f[0]} $sample_dir/${f[1]}"
    else
      echo "Wrong number of fastq files in sample folder! Aborting."\
           "Files present: $file_number" 1>&2
      exit 1
    fi
  else
    echo "Unsupported file type selected! Aborting." 1>&2
    exit 1
  fi

rsem_params="--$aligner \
--num-threads 8 \
--temporary-folder $temp_dir_s \
--append-names \
--estimate-rspd \
--output-genome-bam \
--seed 12345 \
--calc-ci \
--ci-memory 40000 \
$rsem_opts \
$rsem_ref \
$sample_name"
#rsem command that should be run
echo "rsem-calculate-expression $rsem_params >& $log_files/$sample_name.rsem"
eval "rsem-calculate-expression $rsem_params >& $log_files/$sample_name.rsem"
fi

#run the rsem plot function
if [ $make_plots -eq 1 ]; then
  rsem-plot-model $sample_dir/rsem/$sample_name $sample_dir/rsem/$sample_name.pdf
fi

#delete the temp files
if [ $clean -eq 1 ]; then
  rm -rf $temp_dir_s
fi

echo 'Finished RSEM RNA-seq pipeline for: '$sample_name
