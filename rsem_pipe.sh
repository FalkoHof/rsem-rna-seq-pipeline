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
trim_adaptors=1
run_rsem=1
#2. make plots or not
make_plots=0
#3. delete unecessary files from temp_dir
clean=0
##### specify RSEM parameters
aligner="star"
seq_mode="PE"
file_type="fastq"
threads=8 #set this to the number of available cores
##### specify folders and variables #####
#set script dir
pipe_dir=/lustre/scratch/users/$USER/pipelines/rsem-rna-seq-pipeline
#set ouput base dir
base_dir=/lustre/scratch/users/$USER/rna_seq
#folder for rsem reference
rsem_ref_dir=/lustre/scratch/users/$USER/indices/rsem/$aligner/nod_v01
#add folder basename as prefix (follows convention from rsem_make_reference)
rsem_ref=$rsem_ref_dir/$(basename $rsem_ref_dir)
#location of the mapping file for the array job
pbs_mapping_file=$pipe_dir/pbs_mapping_file.txt
#super folder of the temp dir, script will create subfolders with $sample_name
temp_dir=$base_dir/temp

#####loading of the required modules #####
module load RSEM/1.2.30-foss-2016a
module load BEDTools/v2.17.0-goolf-1.4.10
module load SAMtools/1.3-foss-2015b
#module load cutadapt/1.9.1-foss-2016a-Python-2.7.11
module load Trim_Galore/0.4.1-foss-2015a
nextera_r1="CTGTCTCTTATACACATCTCCGAGCCCACGAGAC"
nextera_r2="CTGTCTCTTATACACATCTGACGCTGCCGACGA"

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
file_type=${names_mapped[2]} # get the file type
seq_type=${names_mapped[3]} # get the seq type
adaptor_type=${names_mapped[4]} # get the adaptor type

sample_name=`basename $sample_dir` #get the base name of the dir as sample name

#print some output for logging
echo '#########################################################################'
echo 'Starting RSEM RNA-seq pipeline for: '$sample_name
echo 'Sample directory: ' $sample_dir
echo 'Rsem reference: ' $rsem_ref
echo 'Aligner to be used: ' $aligner
echo 'Mapping file: ' $pbs_mapping_file
echo 'Specified file type: ' $file_type
echo 'Specified sequencing mode: ' $seq_type
echo 'Specified adaptor type: ' $adaptor_type
echo '#########################################################################'

#some error handling function
function error_exit
{
  echo "$1" 1>&2
  exit 1
}

#make output folder
mkdir -p $sample_dir/rsem/
cd $sample_dir

#folders for temp files
temp_dir_s=$temp_dir/$sample_name
mkdir -p $temp_dir_s


if [ $run_rsem -eq 1 ]; then
  #1. check file typ and convert to fastq
  case $file_type in
    "bam")
      f=($(ls $sample_dir | grep -e ".bam")) # get all bam files in folder
      if [[ "${#f[@]}" -ne "1" ]]; then #throw error if more than 1 is present
        error_exit "Error: wrong number of bam files in folder"
      fi
      samtools sort -n -m 4G -@ $threads -o $sample_dir/${f%.*}.sorted.bam \
        $sample_dir/$f
      bedtools_params="bedtools bamtofastq -i $sample_dir/${f%.*}.sorted.bam "
      case $seq_type in
        "PE") #modify bedtools params for PE conversion
          bedtools_params=$bedtools_params" -fq $sample_dir/${f%.*}.1.fq"\
            " -fq2 $sample_dir/${f%.*}.2.fq"
          ;;
        "SE") #modify bedtools params for SE conversion
          bedtools_params=$bedtools_params" -fq $sample_dir/${f%.*}.fq"
          ;;
        *) #exit when unexpected input is encountered
          error_exit "Error: wrong paramter for seq type selected! Select PE or SE."
          ;;
      esac
      #print the command to be exectuted
      echo "Command exectuted for converting bam to fastq:\n $bedtools_params"
      eval $bedtools_params #run the command
    "fq")
      # do nothing...
    *) #exit when unexpected input is encountered
      error_exit "Error: wrong paramter for file type selected! Select bam or fq."
      ;;
  esac

#2. do adaptor trimming according to seq_type and adaptor_type
  #ge
  f=($(ls $sample_dir | grep -e ".fq.gz\|.fastq.gz"))
  #check if more than 0 zipped files are present, if so unzip
  if [[ "${#f[@]}" -gt "0" ]]; then
    gunzip ${f[@]}
  fi
  f=($(ls $sample_dir| grep -e ".fq\|.fastq"))

  trim_params="trim_galore --dont_gzip --stringency 4 -o $sample_dir"
  case $adaptor_type in
    "nextera")
      trimming=$trimming" --nextera"
    "illumina")
      trimming=$trimming" --illumina"
    "unknown") #run trim galore with autodetect
      #do nothing == autodetect
    "none")
      trim_params="No trimming selected..." #Don't trimm
    ^[NCAGTncagt]+$) #check if alphabet corresponds to the genetic alphabet
      if [[ $seq_type == "SE" ; then
        trimming=$trimming" -a $adaptor_type"
      else
        error_exit "Error: Wrong paramter for adaptor or seq type selected!" \
          "See documentation for valid types"
      fi
    ^[NCAGTncagt\/]+$) #check if alphabet corresponds to the genetic alphabet
      if [[ $seq_type == "PE" ; then
        seqs=(${adaptor_type//\// })
        trimming=$trimming" -a ${seqs[0]} -a2 ${seqs[1]}"
      else
        error_exit "Error: Wrong paramter for adaptor or seq type selected!" \
          "See documentation for valid types"
      fi
    *) #exit when unexpected input is encountered
      error_exit "Error: Wrong paramter for adaptor type selected!" \
        "See documentation for valid types"
      ;;
  esac

  case $seq_type in
    "PE")
      trim_params=$trim_params" --paired"
      trim_params=$trim_params" $sample_dir/${f%.*}.1.fq $sample_dir/${f%.*}.2.fq"
      ;;
    "SE")
      trim_params=$trim_params" $sample_dir/${f%.*}.fq "
      ;;
  esac
  #print the command to be exectuted
  echo "Command exectuted for adaptor trimming:\n $trim_params"
  if [[ $adaptor_type != "none" ]]; then
    eval "$trim_params" #run the command
  fi


  # #TODO: think about how to replace the ugly ifs with a case switch
  # #initalize variable
  # rsem_opts=""
  # if [ $seq_mode = "PE" ]; then #add paired-end flag if data is PE
  #   rsem_opts=$rsem_opts"--paired-end "
  # fi
  # if [ $file_type = "bam" ]; then #convert to fastq if input is bam
  #   f=($(ls  $sample_dir | grep -e ".bam")) # get all bam files in folder
  #   file_number=${#f[@]} # get length of the array
  #   if [ "$file_number" = "1" ]; then
  #     #sort bam file
  #     samtools sort -n -m 4G -@ $threads -o $sample_dir/${f%.*}.sorted.bam \
  #     $sample_dir/$f
  #     if [ $seq_mode = "PE" ]; then
  #       #convert bam to fastq then add to rsem_opts string
  #       bedtools bamtofastq -i $sample_dir/${f%.*}.sorted.bam \
  #         -fq $sample_dir/${f%.*}.1.fq \
  #         -fq2 $sample_dir/${f%.*}.2.fq
  #
  #       cutadapt --match-read-wildcards -f fastq -O 4 -a $nextera_r1 $1 -o $2 > $3
  #       cutadapt --match-read-wildcards -f fastq -O 4 -a $nextera_r2 $1 -o $2 > $3
  #
  #       rsem_opts=$rsem_opts"$sample_dir/${f%.*}.1.fq $sample_dir/${f%.*}.2.fq"
  #     fi
  #     if [ $seq_mode = "SE" ]; then
  #       #convert bam to fastq then add to rsem_opts string
  #       bedtools bamtofastq -i $sample_dir/${f%.*}.sorted.bam \
  #         -fq $sample_dir/${f%.*}.fq
  #       rsem_opts=$rsem_opts"$sample_dir/${f%.*}.fq "
  #     fi
  #   else
  #     echo "Only one bam file per sample folder allowed! Aborting."\
  #          "Files present: $file_number" 1>&2
  #     exit 1
  #   fi
  # elif [ $file_type = "fastq" ]; then
  #   rsem_opts=$rsem_opts
  #   #check if fastq files are zipped and unzip them if needed
  #   f=($(ls  $sample_dir | grep -e ".fq.gz\|.fastq.gz"))
  #   file_number=${#f[@]}
  #   if [ $file_number -eq 1 ] || [ $file_number -eq 2 ]; then
  #     gunzip ${f[@]}
  #   fi
  #   #get files with .fq or .fastq extention
  #   f=($(ls  $sample_dir| grep -e ".fq\|.fastq"))
  #   file_number=${#f[@]}
  #   #some Error:handling. Check if only the expected number of fq files is there
  #   if [ $file_number -eq 1 ]  && [ "$seq_mode" = "SE" ]; then
  #     rsem_opts=$rsem_opts"$sample_dir/$f"
  #   elif [ $file_number -eq 2 ]  && [ "$seq_mode" = "PE" ]; then
  #     rsem_opts=$rsem_opts"$sample_dir/${f[0]} $sample_dir/${f[1]}"
  #   else
  #     echo "Wrong number of fastq files in sample folder! Aborting."\
  #          "Files present: $file_number" 1>&2
  #     exit 1
  #   fi
  # else
  #   echo "Unsupported file type selected! Aborting." 1>&2
  #   exit 1
  # fi





# run rsem to calculate the expression levels
# --estimate-rspd: estimate read start position to check if the data has bias
# --output-genome-bam: output bam file as genomic, not transcript coordinates
# --seed 12345 set seed for reproducibility of rng
# --calc-ci calcutates 95% confidence interval of the expression values
# --ci-memory 30000 set memory
rsem_params="--$aligner \
--num-threads $threads \
--temporary-folder $temp_dir_s \
--append-names \
--estimate-rspd \
--output-genome-bam \
--sort-bam-by-coordinate \
--seed 12345 \
--calc-ci \
--ci-memory 40000 \
$rsem_opts \
$rsem_ref \
$sample_name"
#cd into output dir
cd $sample_dir/rsem/
#rsem command that should be run
echo "rsem-calculate-expression $rsem_params >& $sample_name.log"
eval "rsem-calculate-expression $rsem_params >& $sample_name.log"
fi

#run the rsem plot function
if [ $make_plots -eq 1 ]; then
  rsem-plot-model $sample_dir/rsem/$sample_name $sample_dir/rsem/$sample_name.pdf
fi

#delete the temp files
if [ $clean -eq 1 ]; then
  gzip $sample_dir/*.fq $sample_dir/*.fastq
  rm $sample_dir/${f%.*}.sorted.bam
  rm $sample_dir/rsem/*.transcript.bam
  rm -rf $temp_dir_s
fi

echo 'Finished RSEM RNA-seq pipeline for: '$sample_name
