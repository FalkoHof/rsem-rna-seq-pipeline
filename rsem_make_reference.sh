#!/bin/bash
#PBS -P rnaseq_nod
#PBS -N make_rsem_reference
#PBS -J 1
#PBS -j oe
#PBS -q workq
#PBS -o /lustre/scratch/users/falko.hofmann/log/160603/160603_make_rsem_reference.log
#PBS -l walltime=1:00:00
#PBS -l select=1:ncpus=8:mem=64gb

# === begin ENVIRONMENT SETUP ===
##### specify folders and variables #####
annotation_file=
fasta_file=
ref_dir=
aligner='bowtie'

##### load required modules #####
module load RSEM/1.2.29-foss-2015a

# conditional loading of modules based on aligner to be used by RSEM
if [ "$aligner" -eq "bowtie" ]; then
  module load Bowtie/1.1.2-foss-2015b
fi
if [ "$aligner" -eq "bowtie2" ]; then
  module load Bowtie2/2.2.7-foss-2015b
fi
#TODO:star not yet supported? if so add star mapping command in rsem_pipe
if [ "$aligner" -eq "star" ]; then
  module load STAR/2.5.1b-goolf-1.4.10
fi

# === end ENVIRONMENT SETUP ===

echo 'Building rsem reference...'
echo 'Annotation file: ' $annotation_file
echo 'Fasta file: ' $fasta_file
echo 'Output directory: ' $ref_dir
echo 'Aligner to be used: ' $aligner

rsem-prepare-reference --num-threads 8 --gtf $gft_file --$aligner \
  $fasta_file $ref_dir

echo 'Building rsem reference... - Done'
