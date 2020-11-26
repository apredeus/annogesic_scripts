#!/bin/bash 

## $TSV is an output of parse_master_tables.sh 

TSV=$1

## keep ALL primary TSS, and only strongly expressed other kinds 

grep -v GeneLength $TSV | awk '$20==1 || $9>100 || ($9>50 && $10>4 && $11>4)' | cut -f 1-3 | sort -k1,1 -k2,2n | uniq | awk '{print $1"\tANNOgesic\tTSS\t"$2"\t"$2"\t.\t"$3}'
