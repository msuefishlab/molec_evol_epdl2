This folder explains how we processed the sequencing reads. This file serves as a general guideline. It has sections sorted by execution order, and we provide the code used in each section in independent files. The naming convention for these code files is that they begin with the same number as the section they belong to.  


We started with the reads base-called and quality-filtered (Q > 7) by the ONT sequencing pipeline (high accuracy model from Guppy 4.2.3+f90bd04) <br/><br/>


1 - Demultiplexing & barcode trimming: 

We demultiplexed and removed barcodes from the reads following: https://community.nanoporetech.com/docs/prepare/library_prep_protocols/Guppy-protocol/v/gpb_2003_v1_revae_14dec2018/barcoding-demultiplexing
The resulting reads were uploaded to the NCBI SRA


2 - Amplicon extraction: 

We used the code in this section to extract the smallest amplicon greater than 1000 bp from each read

We modified the amplicon subcommand of seqkit 0.15.1 to identify all amplicons in each read (instead of only the largest amplicon in each read). Here, we provide our modified command (Additional Files/mod_amplicon.go). However, note that 1) this modified code was only meant for the use described here, and therefore it is likely to break other functionalities of the original amplicon command; and 2) the ability to identify all amplicons in each read may have been incorporated to seqkit in newer versions. Please check https://bioinf.shenwei.me/seqkit and https://github.com/shenwei356/seqkit

The files sb_extract_amplicons_bar01_14.sb and sb_extract_amplicons_bar15_24.sb contain the instructions submitted to Slurm for barcodes 1-14 & 15-24, respectively. Other than specifying computing resources, this code sets the conditions for each barcode's amplicon extraction, by assigning barcode-specific variables that specify its input reads and primer information. Information needed to set the barcode-specific variables is detailed in the files called pr_*.tsv and guide.table.tsv, all located in the folder Additional Files. Once these variables are assigned, they are passed to the script  extract_amplicons.sh.

extract_amplicons.sh has the actual code we wrote to select the smallest amplicon greater than 1000 bp from each read. Each step is preceded by explanatory annotations.


3 - Extracted amplicons: size & quality filtering
