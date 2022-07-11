This folder explains how we processed the sequencing reads. A general explanation is given in this file, and the code used is provided in additional files in this folder.

We started with the reads base-called and quality-filtered (Q > 7) by the ONT sequencing pipeline (high accuracy model from Guppy 4.2.3+f90bd04)


1 - Demultiplexing & barcode trimming: 

We demultiplexed and removed barcodes from the reads following: https://community.nanoporetech.com/docs/prepare/library_prep_protocols/Guppy-protocol/v/gpb_2003_v1_revae_14dec2018/barcoding-demultiplexing
The resulting reads were uploaded to the NCBI SRA


2 - Amplicon extraction: 

We modified the amplicon subcommand of seqkit 0.15.1 to identify all amplicons in each read (instead of only the largest amplicon in each read). Here, we provide our modified command (Additional Files/mod_amplicon.go). However, note that 1) this modified code was only meant for the use described here, and therefore it is likely to break other functionalities of the original amplicon command; and 2) the ability to identify all amplicons in each read may have been incorporated to seqkit in newer versions. Please check https://bioinf.shenwei.me/seqkit and https://github.com/shenwei356/seqkit





3 - Extracted amplicons: size & quality filtering
