#!/bin/bash 

## one strain per one dir, otherwise things start to interfere pretty badly

PDIR=`readlink -f $1`
FA_NAME=`ls $PDIR/input/references/fasta_files/`
GFF_NAME=`ls $PDIR/input/references/annotations/`

FA=$PDIR/input/references/fasta_files/$FA_NAME
GFF=$PDIR/input/references/annotations/$GFF_NAME

TAG=${FA_NAME%%.fa}

TSS=$PDIR/output/TSSs/gffs/${TAG}_TSS.gff
TRANS=$PDIR/output/transcripts/gffs/${TAG}_transcript.gff
TERM=$PDIR/output/terminators/gffs/best_candidates/${TAG}_term.gff
PROC=$PDIR/output/processing_sites/gffs/${TAG}_processing.gff


WIG_FOLDER=$PDIR/input/wigs/tex_notex
cd $WIG_FOLDER

NT_P=`ls | grep -v dRNA | grep plus`
NT_M=`ls | grep -v dRNA | grep minus`
TX_P=`ls | grep dRNA | grep plus`
TX_M=`ls | grep dRNA | grep minus`

## assuming 1 biological replicate - see run_annogesic_reps.sh for multiple
TEX_LIBS="$WIG_FOLDER/$NT_M:notex:1:a:- $WIG_FOLDER/$TX_M:tex:1:a:- $WIG_FOLDER/$NT_P:notex:1:a:+ $WIG_FOLDER/$TX_P:tex:1:a:+"

echo "Finished preparing the run; following parameters were set:"
echo "FA: $FA"
echo "GFF: $GFF"
echo "TAG: $TAG"
echo "PDIR: $PDIR"

## no manual TSS curation - will filter later 

echo "TEX_LIBS: $TEX_LIBS"
echo; echo "----------------------------------------------------------"; echo 

cd $PDIR

singularity exec ~/annogesic.img annogesic tss_ps --fasta_files $FA --annotation_files $GFF --enrichment_factor 1.0 \
 --tex_notex_libs $TEX_LIBS --condition_names TSS --validate_gene --program TSS --replicate_tex all_1 --project_path $PDIR

echo "Step 1 done: finding TSS with all default params but enrichment factor 1.0" 
echo; echo "----------------------------------------------------------"; echo 

singularity exec ~/annogesic.img annogesic tss_ps --fasta_files $FA --annotation_files $GFF --enrichment_factor 1.0 \
 --tex_notex_libs $TEX_LIBS --condition_names TSS --validate_gene --program PS --replicate_tex all_1 --project_path $PDIR

echo "Step 1b done: finding PS with all default params but enrichment factor 1.0" 
echo; echo "----------------------------------------------------------"; echo 

singularity exec ~/annogesic.img annogesic transcript --annotation_files $GFF --tex_notex_libs $TEX_LIBS \
 --replicate_tex all_1 --compare_feature_genome CDS --tss_files $TSS --project_path $PDIR &> $PDIR/$TAG.transcript.log 
echo "Step 2 done: finding transcripts" 
echo; echo "----------------------------------------------------------"; echo 

singularity exec ~/annogesic.img annogesic terminator --fasta_files $FA --annotation_files $GFF \
 --transcript_files $TRANS --tex_notex_libs $TEX_LIBS --replicate_tex all_1 --project_path $PDIR &> $PDIR/$TAG.terminator.log 
echo "Step 3 done: finding terminators" 
echo; echo "----------------------------------------------------------"; echo 

singularity exec ~/annogesic.img annogesic utr --annotation_files $GFF --tss_files $TSS \
 --transcript_files $TRANS --terminator_files $TERM --project_path $PDIR &> $PDIR/$TAG.utr.log 
echo "Step 4 done: finding UTR" 
echo; echo "----------------------------------------------------------"; echo 

singularity exec ~/annogesic.img annogesic operon --annotation_files $GFF --tss_files $TSS \
 --transcript_files $TRANS --terminator_files $TERM --project_path $PDIR &> $PDIR/$TAG.operon.log 
echo "Step 5 done: finding operons" 
echo; echo "----------------------------------------------------------"; echo 

singularity exec ~/annogesic.img annogesic promoter --tss_files $TSS --fasta_files $FA --motif_width 45 2-10 --project_path $PDIR &> $PDIR/$TAG.promoter.log 
echo "Step 6 done: finding promoters" 
echo; echo "----------------------------------------------------------"; echo 

NR=/home/apredeus/data/annogesic/databases/nr
BSRD=/home/apredeus/data/annogesic/databases/sRNA_database_BSRD
PROM=/home/apredeus/data/annogesic/Bacillus/output/promoters/168/MEME/promoter_motifs_168_allgenome_all_types_45_nt/meme.csv

singularity exec ~/annogesic.img annogesic srna --filter_info tss blast_srna sec_str blast_nr --annotation_files $GFF \
  --tss_files $TSS --processing_site_files $PROC --transcript_files $TRANS --fasta_files $FA --terminator_files $TERM \
  --promoter_tables $PROM --promoter_names MOTIF_1 --mountain_plot --utr_derived_srna --compute_sec_structures --srna_format \
  --nr_format --nr_database_path $NR --srna_database_path $BSRD --tex_notex_libs $TEX_LIBS --replicate_tex all_1 --project_path $PDIR


