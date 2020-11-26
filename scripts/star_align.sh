#!/bin/bash 

## can be used for both single and paired-end
## archived FASTQ is assumed

TAG=$1

## to make ref: STAR   --runMode genomeGenerate   --runThreadN 32   --genomeDir Db11.STAR   --genomeFastaFiles Db11.fa      --genomeSAindexNbases 8

REF=/pub37/alexp/data/rnaseq/Serratia_Db11/study_strains/Db11/Db11.STAR
RRNA=/pub37/alexp/data/rnaseq/Serratia_Db11/study_strains/Db11/Db11.rRNA.bed ## use whole operons here

mkdir -p ${TAG}_star
cd ${TAG}_star

STAR --genomeDir $REF --readFilesIn ../$TAG.fastq.gz --alignIntronMin 20 --alignIntronMax 19 --readFilesCommand zcat --runThreadN 16 --outFilterMultimapNmax 20 --outSAMtype BAM Unsorted &> /dev/null 
## only take the reads that don't overlap rRNA operons 
bedtools intersect -nonamecheck -v -a Aligned.out.bam -b $RRNA | samtools sort -@ 16 - > $TAG.bam
samtools index $TAG.bam
rm Aligned.out.bam
mv Log.final.out $TAG.star.log 
