#!/bin/bash
#PBS -P rnaseq_nod
#PBS -N lib_complexity_pipe
#PBS -J 1-22
#PBS -j oe
#PBS -q workq
#PBS -o /lustre/scratch/users/falko.hofmann/log/160202-lib_complexity
#PBS -l walltime=48:00:00
#PBS -l select=1:ncpus=8:mem=16gb

#set variables

##### specify folders and variables #####
#set script dir
pipe_dir=/lustre/scratch/users/$USER/pipelines/rsem-rna-seq-pipeline
#set ouput base dir
base_dir=/lustre/scratch/users/$USER/rna_seq
#location of the mapping file for the array job
pbs_mapping_file=$pipe_dir/pbs_mapping_file.txt
#super folder of the temp dir, script will create subfolders with $sample_name
temp_dir=$base_dir/temp/lib_complexity
#some output folders
picard_bin=lustre/scratch/users/$USER/software/picard/dist

preseq_ouput=$base_dir/preseq
picard_ouput=$base_dir/picard

## build array index
##### Obtain Parameters from mapping file using $PBS_ARRAY_INDEX as line number
input_mapper=`sed -n "${PBS_ARRAY_INDEX} p" $pbs_mapping_file` #read mapping file
names_mapped=($input_mapper)
sample_dir=${names_mapped[1]} # get the sample dir
sample_name=`basename $sample_dir` #get the base name of the dir as sample name

temp_dir_s=$temp_dir/$sample_name
bam_file=$sample_dir/rsem/$sample_name.genome.bam
bam_file_concordant=$temp_dir_s/$sample_name.concordant.bam
bed_file=$temp_dir_s/$sample_name.bed
bed_file_sorted=$temp_dir_s/$sample_name.sorted.bed

#load modules
module load SAMtools/1.3-goolf-1.4.10
module load BamTools/2.2.3-goolf-1.4.10
module load BEDTools/v2.17.0-goolf-1.4.10
module load preseq/2.0.2-goolf-1.4.10
module load Java/1.8.0_66

#print some output for logging
echo '#########################################################################'
echo 'Estimating libary complexity for: '$sample_name
echo 'Sample directory: ' $sample_dir
echo '#########################################################################'

#create some directories
mkdir -p $preseq_ouput
mkdir -p $picard_ouput
mkdir -p $temp_dir_s

samtools view -b -f 0x2 $bam_file > $bam_file_concordant

bedtools bamtobed -i $bam_file_concordant > $bed_file
sort -k 1,1 -k 2,2n -k 3,3n -k 6,6 $bed_file > $bed_file_sorted

#run preseq
preseq c_curve -P -s 100000 -o $preseq_ouput/$sample_name'_preseq_c_curve.txt' \
  $bed_file_sorted
preseq lc_extrap -P -s 100000 -n 1000 -o $preseq_ouput/$sample_name'_lc_extrap.txt' \
  $bed_file_sorted

cd $picard_bin
java -Xmx15G -jar picard.jar EstimateLibraryComplexity\
  INPUT=$bam_file_concordant \
  OUTPUT=$picard_ouput/$sample_name'_picard_complexity.txt'

#clean up
rm -rf $temp_dir_s

echo 'Finished libary complexity pipeline for: '$sample_name
