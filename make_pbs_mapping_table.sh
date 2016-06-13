#!/bin/bash
input_dir=$1 #uses folder supplied by command line args
x=1
for d in $(readlink -m $input_dir/*/) ;
do
  printf "%d %s\n" $x $d
  ((x++))
done
