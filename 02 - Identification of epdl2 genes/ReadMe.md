This folder explains how we identified epdl2 genes. This file serves as a general guideline. It has sections sorted by execution order, and we provide the code used in each section in independent files. The naming convention for these code files is that they begin with the same number as the section they belong to.

We started with the amplicons extracted from the sequencing reads. These are the output from Folder 1 - Read processing, Section 3: Extracted amplicons: size & quality filtering.


1 – Amplicon clustering

The script sb_cdhit.sb runs cdhit on the amplicons from every barcode, with all values of c in range 0.84-0.91. In every run, it will sort the amplicons in clusters. Then, for each set of resulting clusters, the code counts how many clusters are supported (i.e. clusters than contain >10% of the amplicons) and cuantifies how many amplicons belong to said clusters. These values are used in the c value selection criteria of our pipeline. Then, this code saves all the amplicon sequences of each supported cluster to a fasta file. These fasta files are later used as inputs by Medaka in the next section. Finally, this code invokes R code to plot, for each barcode and for all c values, the distribution of the number of clusters found and the percentage of amplicons they contain. These plots are only used as a visual summary of the outcome. The R code is provided in Additional Files/plot_cluster_distrib.R. See the explanatory annotations in sb_cdhit.sb for further details.


2 - Consensus sequence per cluster

