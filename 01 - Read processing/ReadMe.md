This folder explains how we processed the sequencing reads. A general explanation is given in this file, and the code used is provided in additional files in this folder.

We started with the reads base-called and quality-filtered (Q > 7) by the ONT sequencing pipeline (high accuracy model from Guppy 4.2.3+f90bd04)

1 - Demultiplexing & barcode trimming: We demultiplexed and removed barcodes from the reads following: https://community.nanoporetech.com/docs/prepare/library_prep_protocols/Guppy-protocol/v/gpb_2003_v1_revae_14dec2018/barcoding-demultiplexing

The resulting reads were uploaded to the NCBI SRA
