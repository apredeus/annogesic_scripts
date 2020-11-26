#!/bin/bash 

## If you have more than 1 replicon in your reference ANNOgesic will generate multiple folders

WDIR=$1 ## Annogesic project dir 

TSVS=`ls $WDIR/output/TSSs/MasterTables/*/MasterTable.tsv`

for i in $TSVS
do
  ## header
  CHR=`echo $i | perl -ne 'm/MasterTable_(.*?)\//; print "$1\n"'`
  if [[ $CHR == *chr ]] 
  then
    grep "^SuperPos" $i | awk '{print "Chromosome\t"$0}' 
  fi 
done 

for i in $TSVS
do
  CHR=`echo $i | perl -ne 'm/MasterTable_(.*?)\//; print "$1\n"'`
  >&2 echo "Processing replicon $CHR.." 
  grep -v "^SuperPos" $i | awk -v v=$CHR '{print v"\t"$0}' | sed "s/gene_//g" 
done
