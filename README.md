# Nodine lab RSEM RNA-seq pipeline
This repository contains a collections of scripts to map RNA-seq data via
[STAR](https://github.com/alexdobin/STAR) and quantify the mapped reads via
[RSEM](https://github.com/deweylab/RSEM).

## rsem_make_reference.sh
- Bash script to create an RSEM reference for a certain aligner with a certain
  annotation and fasta file.
- Edit according to need and preferences (e.g. preferred aligner, annotation
  file format, fasta file location)
- Should be submitted as pbs job via qsub

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
