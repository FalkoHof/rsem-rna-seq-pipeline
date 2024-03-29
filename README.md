# Nodine lab RSEM RNA-seq pipeline
This repository contains a collections of scripts to map RNA-seq data via your
aligner of choice and quantify the mapped reads via
[RSEM](https://github.com/deweylab/RSEM).

To get the scripts run in your folder of choice:
```shell
git clone https://gitlab.com/nodine-lab/rsem-rna-seq-pipeline.git
```
This pipeline contains a collection of three scripts that should be run in the
following order:
1. rsem_make_reference.sh -  a script to build an rsem index
2. make_pbs_mapping_table.sh - a script for creating a mapping table to tell
   rsem_pipe.sh which files/folders should be processed
3. rsem_pipe.sh - the pipeline script to align and quantify rna seq data.

The most recent updates are contained in the development branch. To make use of most recent version run after you have cloned the repository:
```shell
git fetch origin develop 
git checkout develop
```
This will make git fetch the contents of the development branch and switch to it.  

If you are lab member and want to hack around on the pipeline and create your
own customized pipelines either
[fork](https://help.github.com/articles/fork-a-repo/)
the repository (prefered for customization) or create a seperate [branch](https://git-scm.com/book/en/v2/Git-Branching-Branches-in-a-Nutshell)
(prefered for hacking on bug fixes etc.).
```shell
$ git branch some_fix
$ git checkout some_fix
```

## 1. rsem_make_reference.sh
- A bash script to create an RSEM reference for a certain aligner with a certain
  annotation and fasta file. Edit according to need and preferences (e.g.
  preferred aligner, annotation file format, fasta file location). This script
  should be submitted as pbs job via ```qsub rsem_make_reference.sh```.
  [STAR](https://github.com/alexdobin/STAR) is the recommended (and default)
  aligner.
- Variables that need personalization:
  - #PBS -o: This path needs to be changed. Add here a path to where the log
    file of the run should be stored.
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

## 2. make_pbs_mapping_table.sh
- Bash script to create a mapping file for pbs array jobs. Should be run via the
  standard shell environment (e.g. submit a small interactive job and run it
  there). Needs an folder as command line argument.
  The script will list the subfolders and output a mapping of
  <line number> <dir> <file_type> <seq_mode> <adaptor> to stdout. The default
  for adaptor is 'unknown', which will trigger trim_galore to run in auto
  detect adaptor type mode. If you want to explicitly specify an adapter you
  need to do so by hand. You can also type in DNA sequences in this field and
  use the / delimiter as in <adaptor1>/<adaptor2> to specifiy fw and rv adaptors
  in PE mode (see also example below).
- Pipe the output to a file and specify that file in the rsem_pipe.sh script.
  The idea here is that you don't manually need to type in sample names when you
  want to submit a batch job. Just input the super folder of all your samples
  as command line argument.

  ```
  example: ./make_pbs_mapping_table.sh /Some/Super/Folders/ > pbs_mapping_file.txt

  or if you have not set the excutable bit...

  example: sh make_pbs_mapping_table.sh /Some/Super/Folders/ > pbs_mapping_file.txt

  ```
- Afterwards I would recommend to briefly check if the paths in the
  'pbs_mapping_file.txt' are correct. I would also recommend to create this file
  in the same folder as all the pipeline scripts are created (this is the assumed
  default for rsem_pipe.sh).
  Warning: only works on systems with gnu readlink installed.
  (Cluster & linux is fine, for the Mac you need to install readlink e.g.
  via Homebrew, no idea where Cygwin stands on that)
- Alternatively the file can also be generated manually as e.g. shown below:

  ```shell
  1 /Some/Folder/RNA-seq/sample_a/ fq SE illumina
  2 /Some/Folder/RNA-seq/sample_b/ bam PE nextera
  3 /Some/Folder/RNA-seq/sample_c/ fq SE unknown
  4 /Some/Folder/RNA-seq/sample_d/ fq SE ACGTTGG
  5 /Some/Folder/RNA-seq/sample_e/ fq PE ACGTTGG/TAGGCCT

  ...
  ```

## 3. rsem_pipe.sh
#TODO: Needs to be updated
- Bash script that runs RSEM with your aligner of choice (can be specified
  in the script). Requires you to run rsem_make_reference.sh and
  make_pbs_mapping_table.sh before. Should be submitted as pbs job via
  ```qsub rsem_pipe.sh```.
- Variables that need personalization:
  - #PBS -o: This path needs to be changed. Add here a path to where the log
  file of the run should be stored. Use ^array_index^ if you are running a batch
  job and want get the number of the batch job array for the file name.
  - flow control: set these variables to either 0 or 1. 1 means run this part of
    the script 0 means don't run it.
       1. run_rsem: run rsem-calculate-expression to quantify the input (Default: 1).
       2. make_plot: run rsem-plot-model to ouput diagnostic pdf (Default: 1).
       3. clean: delete all temporary files (Default: 0).
  - aligner: specify the aligner that should be used.
    accepted input is: bowtie, bowtie2, star.
    Pick the same one you used to build your rsem reference via the
    rsem_make_reference.sh script.
  - rsem_ref_dir: specify the path of the rsem reference that was build via
    the rsem_make_reference.sh script.
  - pipe_dir: specify here the folder in which the pipeline scripts are located
  - base_dir: specify here a super folder in which the folders log_files and
    temp_dir will be created
  - log_files: folder where rsem stdout will be written to for logging purposes
  - pbs_mapping_file: specify here the location of the mapping file generated
    via make_pbs_mapping_table.sh (Default: $pipe_dir/pbs_mapping_file.txt)
  - temp_dir: temp folder path (Default: $base_dir/temp/)
