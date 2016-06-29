# Nodine lab RSEM RNA-seq pipeline
This repository contains a collections of scripts to map RNA-seq data via your
aligner of choice and quantify the mapped reads via
[RSEM](https://github.com/deweylab/RSEM).

To get the scripts run in your folder of choice:
```
git clone https://gitlab.com/nodine-lab/rsem-rna-seq-pipeline.git
```
This pipeline contains a collection of three scripts:
1. rsem_make_reference.sh -  a script to build an rsem index
2. make_pbs_mapping_table.sh - a script for creating a mapping table to tell
   rsem_pipe.sh which files/folders should be processed
3. rsem_pipe.sh - the pipeline script to align and quantify rna seq data.


## rsem_make_reference.sh
- A bash script to create an RSEM reference for a certain aligner with a certain
  annotation and fasta file. Edit according to need and preferences (e.g.
  preferred aligner, annotation file format, fasta file location). This script
  should be submitted as pbs job via ```qsub rsem_make_reference.sh``` .
  [STAR](https://github.com/alexdobin/STAR) is the recommended (and default)
  aligner.
- Variables that need personalization:
  - aligner: specify the aligner that should be used.
    accepted input is: bowtie, bowtie2, star.
    You need to pick the same aligner later for the rsem_pipe.sh script
  - annotation_file: specify here the path to the annotation file that should be
    used. The pipeline is currently designed to work with gtf files (--gtf flag)
    . However, other file formats are also possible. See the [STAR documentation]
    (http://deweylab.biostat.wisc.edu/rsem/rsem-prepare-reference.html) on that
    and change the script otherwise according to your needs. For the nod_v01
    annotation use the files in '/projects/rnaseq_nod/nod_v01_annotation'.
  - fasta_file: specify here the path to the fasta file (genome) that should be
    used to build the rsem reference. For Col-0 with mRNA spike ins, use the
    Col_mS.fa file located '/projects/rnaseq_nod/fasta/'
  - out_dir: specify here the folder where the rsem reference should be stored
    at. Defaults to: '/lustre/scratch/users/$USER/indices/rsem/$aligner/nod_v01'

## make_pbs_mapping_table.sh
- Bash script to create a mapping file for pbs array jobs.
- Should be run via the standard shell environment and needs an folder as
  command line argument. The script will list the subfolders and output a
  mapping of <line number> <dir> to stdout.
  Pipe the output to a file and specifiy this file in the rsem_pipe.sh script.
- Warning: only works on systems with gnu readlink installed. (Cluster & linux
  is fine, for the Mac you need to install readlink e.g. via Homebrew, no idea
  where Cygwin stands on that)
```
example: ./make_pbs_mapping_table.sh /Some/Super/Folders/ > pbs_mapping_file.txt
```

## rsem_pipe.sh
- Bash script that runs RSEM with your aligner of choice (can be specified
  in the script). Modify parameters as needed.
- Requires you to run rsem_make_reference.sh and make_pbs_mapping_table.sh before
- Should be submitted as pbs job via qsub
