# Annogesic scripts

This repository mainly describes running [ANNOgesic](https://annogesic.readthedocs.io/en/latest/tutorial.html) for TSS annotation in bacterial genomes using dRNA-seq. In addition to TSS annotation, one can also do *great many things* with `ANNOgesic` - and there'll be few scripts describing this as well. 

First of all, you need a machine with [Singularity](https://singularity.lbl.gov/) installed. You can't install it without the root access; if you don't have it on your cluster, ask your admin- or run this on a local workstation, because most `ANNOgesic` jobs don't require too much compute power (TSS calling definitely does not). 

After this, follow `ANNOgesic` tutorial to understand the logic of the annotation process. To start, you'll need your genome assembly and annotation (see in **example_files** for the exact format of GFF), as well as strand-separated, non-normalized *wig* files from dRNA-seq and matching control RNA-seq experiments. 

## Wig file preparation 

Importantly, `ANNOgesic` requires a properly formatted *wig* file, and not the kind that can be generated from *bigWig* or *bedGraph*. To generate it, first align the reads to your genome using `STAR` (see `star_align.sh` script in **scripts**), and sort the obtained *bam* file. After this, generate strand-specific wig files using `make_proper_wig.pl`: 

```bash 
./make_proper_wig.pl sample1.bam + > sample1.plus.wig
./make_proper_wig.pl sample1.bam - > sample1.minus.wig
```

After this, just copy the wig files into the appropriate sub-directory of the `ANNOgesic`-generated directory structure. 

## Suggested workflow 

Overall processing is done as follows: 

* Run TSS prediction with default settings; 
* Curate a selection (~ 200kb) of predicted TSS: remove bad predictions, and *add missing good TSS sites*; 
* Learn new parameters of TSS prediction using the curated selection;
* Re-run the TSS prediction using the optimized parameters;  
* Do all the remaining downstream analysis `ANNOgesic` lets you do.

## Simplified forkflow 

The suggested workflow above missed a lot of TSS discoverable by "eye test", so I came up with much less labor intensive method that generates decent results: 

* Run TSS prediction with relaxed settings; 
* Filter the obtained TSS table using the expression values and primary/non-primary annotation.

Ideally, you would also examine RNA-seq tracks (e.g. in JBrowse) together with "relaxed" and "filtered" TSS track, and select TSS to your liking. But this is a *mind-numbing work* and takes a lot of time and patience. 

## Visualization

Predicted TSS files in *gff* format are easily visualized in JBrowse. 
