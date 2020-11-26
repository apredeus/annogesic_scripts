#!/bin/bash 

## example run of TSS prediction with multiple replicates of dRNA-seq and pool. 

PDIR=`readlink -f $1`
FA_NAME=`ls $PDIR/input/references/fasta_files/`
GFF_NAME=`ls $PDIR/input/references/annotations/`

FA=$PDIR/input/references/fasta_files/$FA_NAME
GFF=$PDIR/input/references/annotations/$GFF_NAME

TAG=${FA_NAME%%.fa}

TSS=$PDIR/output/TSSs/gffs/${TAG}_TSS.gff
WIG_FOLDER=$PDIR/input/wigs/tex_notex
cd $WIG_FOLDER

TEX_LIBS="$WIG_FOLDER/New_pool_rep1.minus.wig:notex:1:a:- $WIG_FOLDER/New_pool_rep2.minus.wig:notex:1:b:- $WIG_FOLDER/New_pool_rep3.minus.wig:notex:1:c:- \
$WIG_FOLDER/New_pool_rep1.plus.wig:notex:1:a:+ $WIG_FOLDER/New_pool_rep2.plus.wig:notex:1:b:+ $WIG_FOLDER/New_pool_rep3.plus.wig:notex:1:c:+ \
$WIG_FOLDER/New_dRNAseq_rep1.minus.wig:tex:1:a:- $WIG_FOLDER/New_dRNAseq_rep2.minus.wig:tex:1:b:- $WIG_FOLDER/New_dRNAseq_rep3.minus.wig:tex:1:c:- \
$WIG_FOLDER/New_dRNAseq_rep1.plus.wig:tex:1:a:+ $WIG_FOLDER/New_dRNAseq_rep2.plus.wig:tex:1:b:+ $WIG_FOLDER/New_dRNAseq_rep3.plus.wig:tex:1:c:+"

echo "Finished preparing the run; following parameters were set:"
echo "FA: $FA"
echo "GFF: $GFF"
echo "TAG: $TAG"
echo "PDIR: $PDIR"

### predict TSS with relaxed parameters

singularity exec ~/annogesic.img annogesic tss_ps --fasta_files $FA --annotation_files $GFF --tex_notex_libs $TEX_LIBS \
 --enrichment_factor 1.0 --condition_names TSS --validate_gene --program TSS --replicate_tex all_1 --project_path $PDIR 
