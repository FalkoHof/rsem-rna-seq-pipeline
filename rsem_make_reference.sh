#!/bin/bash
#PBS -P rnaseq_nod
#PBS -N make_rsem_reference
#PBS -j oe
#PBS -q workq
#PBS -o /lustre/scratch/users/falko.hofmann/log/160625/160625_make_rsem_reference.log
#PBS -l walltime=00:30:00
#PBS -l select=1:ncpus=8:mem=64gb

# === begin ENVIRONMENT SETUP ===
##### specify folders and variables #####
aligner="star"
annotation_file=/lustre/scratch/users/$USER/Ath_annotations/nod_v01/Arabidopsis_thaliana.TAIR10.30.nod_v01.gtf
fasta_file=/lustre/scratch/users/$USER/indices/fasta/Col_mS.fa
out_dir=/lustre/scratch/users/$USER/indices/rsem/$aligner/nod_v01
prefix=`basename $out_dir`

##### load required modules #####
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

# === end ENVIRONMENT SETUP ===

echo 'Building rsem reference...'
echo 'Annotation file: ' $annotation_file
echo 'Fasta file: ' $fasta_file
echo 'Output directory: ' $out_dir
echo 'Aligner to be used: ' $aligner

mkdir -p $out_dir
#TODO: change implementation, so that file extention is automatically recognized
rsem-prepare-reference --num-threads 8 --gtf $annotation_file --$aligner \
  $fasta_file $out_dir/$prefix

echo 'Building rsem reference... - Done'
