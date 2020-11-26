# Annogesic scripts

This repository mainly describes running [ANNOgesic](https://annogesic.readthedocs.io/en/latest/tutorial.html) for TSS annotation in bacterial genomes using dRNA-seq. In addition to TSS annotation, one can also do *great many things* with `ANNOgesic` - and there'll be few scripts describing this as well. 

First of all, you need a machine with [Singularity](https://singularity.lbl.gov/) installed. You can't install it without the root access; if you don't have it on your cluster, ask your admin - or run this on a local workstation, because most `ANNOgesic` jobs don't require too much compute power (TSS calling definitely does not). 

After this, follow `ANNOgesic` tutorial to understand the logic of the annotation process. To start, you'll need your genome assembly and annotation (see in **example_files** for the exact format of GFF), as well as strand-separated, non-normalized *wig* files from dRNA-seq and matching control RNA-seq experiments. 

In this repository, I assume you do not use `ANNOgesic` alignment or annotation transfer tool. I've used `STAR` for alignment and pre-formatted NCBI *gff* annotations. 

## Wig file preparation 

Importantly, `ANNOgesic` requires a properly formatted *wig* file, and not the kind that can be generated from *bigWig* or *bedGraph*. To generate it, first align the reads to your genome using `STAR` (see `star_align.sh` script in **scripts**), and sort the obtained *bam* file. After this, generate strand-specific wig files using `make_proper_wig.pl`: 

```bash 
./make_proper_wig.pl sample1.bam + > sample1.plus.wig
./make_proper_wig.pl sample1.bam - > sample1.minus.wig
```

After this, just copy the *wig* files into the appropriate sub-directory of the `ANNOgesic`-generated directory structure. 

## Original TSS calling workflow 

ANNOgesic/TSSpredator manual suggests the following processing sequence: 

* Run TSS prediction with default settings; 
* Curate a selection (~ 200kb) of predicted TSS: remove bad predictions, and *add missing good TSS sites*; 
* Learn new parameters of TSS prediction using the curated selection;
* Re-run the TSS prediction using the optimized parameters;  
* Do all the remaining downstream analysis `ANNOgesic` lets you do.

## Simplified workflow 

The suggested workflow above still missed a lot of TSS discoverable by "eye test", so I came up with much less labor-intensive method that generates decent results: 

* Run TSS prediction with relaxed settings ("--enrichment_factor 1.0"); 
* Filter the obtained TSS table using the expression values and primary/non-primary annotation. For this, first run the script generating the combined master table (here, **Db11** is the name of `ANNOgesic`-generated folder with the input and output): 

```bash 
./parse_master_tables.sh Db11 > Db11.master.tsv
```

After this, filter the obtained master table, and use the obtained file to filter the *gff* file: 

```bash
./filter_master_table.sh Db11.master.tsv > Db11.filt_master.tsv
grep -wF -f Db11.filt_master.tsv Db11_TSS.gff > Db11_TSS.filt.gff
```

The `filter_master_table.sh` script is retaining the following TSS sites: 1) anything annotated as "primary"; 2) anything with > 100 reads mapped to the first nucleotide; 3) anything with > 50 reads mapped to the first nucleotide, and with *stepFactor* and *enrichmentFactor* of over 4.0. All these can be adjusted according to your needs.

Ideally, you would also examine RNA-seq tracks (e.g. in JBrowse) together with "relaxed" and "filtered" TSS track, and select TSS to your liking. But this is *mind-numbing work* and takes a lot of time and patience. 

## Visualization

Predicted TSS files in *gff* format are easily visualized in JBrowse.

## Full annotation

An example of complete annotation (prediction of transcription start sites, processing sites, transcripts, terminators, UTRs, operons, promoters, and sRNAs) is given in `run_annogesic_all.sh`. You'll need a couple of additional databases, including *nt* blast database. 
