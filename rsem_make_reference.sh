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
out_dir=/lustre/scratch/users/falko.hofmann/indices/rsem/$aligner/nod_v01

##### load required modules #####
module load RSEM/1.2.29-foss-2015a

# conditional loading of modules based on aligner to be used by RSEM
if [ $aligner == "bowtie" ]; then
  module load Bowtie/1.1.2-foss-2015b
fi
if [ $aligner == "bowtie2" ]; then
  module load Bowtie2/2.2.7-foss-2015b
fi
#TODO:star not yet supported? if so add star mapping command in rsem_pipe
if [ $aligner == "star" ]; then
  module load STAR/2.5.1b-goolf-1.4.10
fi

# === end ENVIRONMENT SETUP ===

echo 'Building rsem reference...'
echo 'Annotation file: ' $annotation_file
echo 'Fasta file: ' $fasta_file
echo 'Output directory: ' $out_dir
echo 'Aligner to be used: ' $aligner

mkdir -p $out_dir

rsem-prepare-reference --num-threads 8 --gtf $annotation_file --$aligner \
  $fasta_file $out_dir

echo 'Building rsem reference... - Done'
