#!/bin/bash 

## this is intended to automate the run as much as possible 
## one strain per one dir, otherwise things start to interfere pretty badly

PDIR=`readlink -f $1`
FA_NAME=`ls $PDIR/input/references/fasta_files/`
GFF_NAME=`ls $PDIR/input/references/annotations/`
MANUL_NAME=`ls $PDIR/input/manual_TSSs/`

FA=$PDIR/input/references/fasta_files/$FA_NAME
GFF=$PDIR/input/references/annotations/$GFF_NAME
MANUL=$PDIR/input/manual_TSSs/$MANUL_NAME  ## da angry cat

TAG=${FA_NAME%%.fa}

TSS=$PDIR/output/TSSs/gffs/${TAG}_TSS.gff
TRANS=$PDIR/output/transcripts/gffs/${TAG}_transcript.gff
TERM=$PDIR/output/terminators/gffs/best_candidates/${TAG}_term.gff
PROC=$PDIR/output/processing_sites/gffs/${TAG}_processing.gff
PROM=$PDIR/output/promoters/$TAG/MEME/promoter_motifs_${TAG}_allgenome_all_types_45_nt/meme.csv


WIG_FOLDER=$PDIR/input/wigs/tex_notex
cd $WIG_FOLDER

NT_P=`ls | grep -v dRNA | grep plus`
NT_M=`ls | grep -v dRNA | grep minus`
TX_P=`ls | grep dRNA | grep plus`
TX_M=`ls | grep dRNA | grep minus`

TEX_LIBS="$WIG_FOLDER/$NT_M:notex:1:a:- $WIG_FOLDER/$TX_M:tex:1:a:- $WIG_FOLDER/$NT_P:notex:1:a:+ $WIG_FOLDER/$TX_P:tex:1:a:+"

echo "Finished preparing the run; following parameters were set:"
echo "FA: $FA"
echo "GFF: $GFF"
echo "TAG: $TAG"
echo "MANUL: $MANUL"
echo "PDIR: $PDIR"
#first we run it like this, and get some sort of default TSS set 

#singularity exec ~/annogesic.img annogesic tss_ps --fasta_files $FA --annotation_files $GFF \
# --tex_notex_libs $TEX_LIBS --condition_names test --validate_gene --program TSS --replicate_tex all_1 --project_path $PDIR

## then we take first 300 kb of the default, and select only ones we like, and then run again

LIMITS=`sort -k5,5n $MANUL | tail -n1 | cut -f 1,5 | tr '\t' ':'`
echo "LIMITS: $LIMITS"
echo "TEX_LIBS: $TEX_LIBS"
echo; echo "----------------------------------------------------------"; echo 

cd $PDIR

singularity exec ~/annogesic.img annogesic optimize_tss_ps --fasta_files $FA --annotation_files $GFF --tex_notex_libs $TEX_LIBS \
 --condition_names TSS --steps 25 --manual_files $MANUL --curated_sequence_length $LIMITS --replicate_tex all_1 --project_path $PDIR &> $PDIR/$TAG.tss_param.log 

echo "DEBUG: $PDIR"

## after this we run TSS prediction with 7 optimized parameters
## we have to obtain these - yes, it is that annoying 

P1=`cat $PDIR/$TAG.tss_param.log | grep "Best Parameters" | tail -n1 | perl -ne 'm/height=(.*?)\s/; print "$1\n"'`
P2=`cat $PDIR/$TAG.tss_param.log | grep "Best Parameters" | tail -n1 | perl -ne 'm/height_reduction=(.*?)\s/; print "$1\n"'`
P3=`cat $PDIR/$TAG.tss_param.log | grep "Best Parameters" | tail -n1 | perl -ne 'm/factor=(.*?)\s/; print "$1\n"'`
P4=`cat $PDIR/$TAG.tss_param.log | grep "Best Parameters" | tail -n1 | perl -ne 'm/factor_reduction=(.*?)\s/; print "$1\n"'`
P5=`cat $PDIR/$TAG.tss_param.log | grep "Best Parameters" | tail -n1 | perl -ne 'm/base_height=(.*?)\s/; print "$1\n"'`
P6=`cat $PDIR/$TAG.tss_param.log | grep "Best Parameters" | tail -n1 | perl -ne 'm/enrichment_factor=(.*?)\s/; print "$1\n"'`
P7=`cat $PDIR/$TAG.tss_param.log | grep "Best Parameters" | tail -n1 | perl -ne 'm/processing_factor=(.*?)$/; print "$1\n"'`

echo "Step 1 done: optimizing TSS prediction parameters"
echo "Following best parameters were obtained:" 
echo "h: $P1 hr: $P2 f: $P3 fr: $P4 bh: $P5 ef: $P6 pf: $P7" 
echo; echo "----------------------------------------------------------"; echo 

singularity exec ~/annogesic.img annogesic tss_ps --fasta_files $FA --annotation_files $GFF --tex_notex_libs $TEX_LIBS \
 --condition_names TSS --height $P1 --height_reduction $P2 --factor $P3 --factor_reduction $P4 --base_height $P5 \
 --enrichment_factor $P6 --processing_factor $P7 --validate_gene \
 --program TSS --replicate_tex all_1 --curated_sequence_length $LIMITS --manual_files $MANUL --project_path $PDIR &> $PDIR/$TAG.tss_manual.log 
echo "Step 2 done: finding TSS with optimized parameters" 
echo; echo "----------------------------------------------------------"; echo 


singularity exec ~/annogesic.img annogesic transcript --annotation_files $GFF --tex_notex_libs $TEX_LIBS \
 --replicate_tex all_1 --compare_feature_genome CDS --tss_files $TSS --project_path $PDIR &> $PDIR/$TAG.transcript.log 
echo "Step 3 done: finding transcripts" 
echo; echo "----------------------------------------------------------"; echo 

singularity exec ~/annogesic.img annogesic terminator --fasta_files $FA --annotation_files $GFF \
 --transcript_files $TRANS --tex_notex_libs $TEX_LIBS --replicate_tex all_1 --project_path $PDIR &> $PDIR/$TAG.terminator.log 
echo "Step 4 done: finding terminators" 
echo; echo "----------------------------------------------------------"; echo 

singularity exec ~/annogesic.img annogesic utr --annotation_files $GFF --tss_files $TSS \
 --transcript_files $TRANS --terminator_files $TERM --project_path $PDIR &> $PDIR/$TAG.utr.log 
echo "Step 5 done: finding UTR" 
echo; echo "----------------------------------------------------------"; echo 

singularity exec ~/annogesic.img annogesic operon --annotation_files $GFF --tss_files $TSS \
 --transcript_files $TRANS --terminator_files $TERM --project_path $PDIR &> $PDIR/$TAG.operon.log 
echo "Step 6 done: finding operons" 
echo; echo "----------------------------------------------------------"; echo 

singularity exec ~/annogesic.img annogesic promoter --tss_files $TSS --fasta_files $FA \ 
 --motif_width 45 2-10 --project_path $PDIR &> $PDIR/$TAG.promoter.log 
echo "Step 7 done: finding promoters" 
echo; echo "----------------------------------------------------------"; echo 

# singularity exec ~/annogesic.img annogesic srna --filter_info tss blast_srna sec_str blast_nr --annotation_files $GFF \
# --tss_files $TSS --processing_site_files $PROC --transcript_files $TRANS --fasta_files $FA --terminator_files $TERM \
# --promoter_tables $PROM --promoter_names MOTIF_1 --mountain_plot --utr_derived_srna --compute_sec_structures --srna_format \
# --nr_format --nr_database_path $NR --srna_database_path $BSRD --tex_notex_libs $TEX_LIBS --replicate_tex all_1 --project_path $PDIR


