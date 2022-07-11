#!/bin/bash -login

# 1) define variables to use
#variables with values set by user
primer_pair_name=$1
primer_file=$2
size_threshold=$3
input_fastq=$4
barcode=$5

#other variables
dummy=${input_fastq%.fastq}
dummy2=${dummy##*/}
bed_file=${barcode}/${dummy2}.bed
bed_file_mod=${bed_file}_mod
output=${barcode}/${dummy2}_oriented_amplicon.fastq
out_small_amplicons=${barcode}/${barcode}__reads_max_amplicon_too_small.txt
out_discard=${barcode}/${barcode}__discarded_reads.txt
logfile=${barcode}/${barcode}.log
rm -f $output $out_small_amplicons $logfile $out_discard

# headers for the logfile and discard file, for debugging purposes 
echo -en 'read_id''\t''read_length''\t''No_amplicons''\t''longest_amplicon''\t''selected_amplicon''\t''strand''\t''bases_to_trim_from_start_(headcrop)''\t''last_base_to_keep''\t''bases_to_trim_from_end_(tailcrop)''\n' > $logfile
echo -en 'read_id''\t''discard_reason''\t''amplicon_size''\n' > $out_discard

# 2) activate conda environment for Nanofilt
source ~/MyPrograms/anaconda3/etc/profile.d/conda.sh
conda activate nanopack

# 3) map primers with seqkit, create a bed file. use all expansions of degenerate primers. 
seqkit amplicon $input_fastq --bed -m 2 -p $primer_file -t dna -w 0 -o $bed_file 

# 4) once the bed file is ready: replace specific primer names with the name of the primer pair (column 4), drop column 5 (normally a value of quality, always 0 here), drop column 7 (with the DNA sequence of the amplicon), add a column with the size of the amplicon, and drop duplicated entries (these are exactly the same amplicon, but originally detected with expansions of the degenerate primers)
awk -F '\t' -v i=$primer_pair_name 'BEGIN{OFS="\t";} {size = $3 - $2 ;} {print $1, $2, $3, i, $6, size}' $bed_file | sort -u -o $bed_file_mod

# 5) make a list of the read IDs that have at least one amplicon:
read_IDs=$(cut -f1 $bed_file_mod | sort -u)

# 6) Now one must consider the amplicons for each read ID. Find and extract the desired amplicon

## take the read IDs from the read_IDs variable, one at a time
for id in $read_IDs
do

#reset variables from previous loop
unset read_length tot_ampl max strand h r t
#reset best_amp to none. I want this word on the log file for amplicons<threshold
best_amp=none

# the read length is necessary to determine the trimming coordinates. To get the read length one must go back to the original read. In the following command, seqkit finds the fastq read for the chosen read ID, awk chooses the DNA sequence of the fastq read, tr removes the newline character (which is otherwise counted by wc), and wc -m counts the characters in the DNA sequence
	read_length=$(seqkit grep -p $id $input_fastq | awk 'NR==2' | tr -d '\n' | wc -m)

# The following command will:
	# find the lines with the target read ID from the modified bed file and gather the amplicon sizes (column 6)
	# sort these sizes, descending
	# store the highest value as a variable called max
	max=$(awk -v id=$id '$1 == id { print $6 }' $bed_file_mod | sort -nr | head -n1)

	#if max < 0 this read is no good, log and skip it. This can happen when the F primer binds downstream of the R primer
	if [ $max -le 0 ]
	then
		echo -en $id'\t'"negative_amplicons"'\t'$max'\n' >> $out_discard
		continue 
	fi

	#the following is similiar to the previous line. It logs how many amplicons were found for the read at hand, for debugging purposes
	tot_ampl=$(awk -v id=$id '$1 == id { print $0 }' $bed_file_mod | wc -l)

# compare max to $size_threshold (if the longest amplicon is < $size_threshold, I want to be able to inspect it later):
	if [ $max -lt $size_threshold ]
	then

		# get the strand the amplicon is on
		strand=$(awk -v id=$id -v amp=$max '($1 == id && $6 == amp) { print $5 }' $bed_file_mod)

		#if there are +2 amplicons with size=max then the code reads from more than one row and throws an error. Log and discard these reads, they are chimeric reads anyway. 
		if [ ${#strand} != 1 ]
		then
			echo -en $id'\t'"amplicon_size_is_not_unique"'\t'$max'\n' >> $out_discard
			continue 
		fi

		# and get the trimming coordinates for this read:
		h=$(awk -v id=$id -v amp=$max '($1 == id && $6 == amp) { print $2 }' $bed_file_mod)
		r=$(awk -v id=$id -v amp=$max '($1 == id && $6 == amp) { print $3 }' $bed_file_mod)
		# Nanofilt needs the tailcrop trimming coordinate in reference to the end of the read
		t=$(expr $read_length - $r)


		## trim the fastq read at the chosen coordinates h, t (= extract chosen amplicon)

		# if the amplicon is in the - strand, the read must be reverse-complemented before amplicon extraction
		if [ $strand == '-' ]
		then

			# this code: 1) finds the fastq read, 2) RCs it, 3) trims where indicated, and 4) appends the fastq amplicon to the output file
			seqkit grep -p $id $input_fastq | seqkit seq -t dna -w 0 -r -p -v | NanoFilt_Mau --headcrop $h --tailcrop $t >> ${output}

		# if the read is in the + strand, do the same as above, without the RC. 
		elif [ $strand == '+' ]
		then

			seqkit grep -p $id $input_fastq | NanoFilt_Mau --headcrop $h --tailcrop $t >> ${output}

		fi

		# add the read ID to a file so I can inpect later
		echo $id >> $out_small_amplicons


# if the longest amplicon is > $size_threshold, then I want to keep the smallest amplicon larger than the threshold:
	elif [ $max -ge $size_threshold ]
	then

		# In the modified bed file, find the line with the smallest amplicon larger than the threshold:
		best_amp=$(awk -v id=$id -v threshold=$size_threshold '($1 == id && $6 >= threshold) { print $6 }' $bed_file_mod | sort -n | head -n1)
		

		## proceed to extract the desired amplicon, very similar to above

		# get the strand the amplicon is on
		strand=$(awk -v id=$id -v amp=$best_amp '($1 == id && $6 == amp) { print $5 }' $bed_file_mod)

		#if there are +2 amplicons with size=best_amp then the code reads from more than one row and throws an error. Log and discard these reads, they are chimeric reads anyway. 
		if [ ${#strand} != 1 ]
		then
			echo -en $id'\t'"amplicon_size_is_not_unique"'\t'$best_amp'\n' >> $out_discard
			continue 
		fi

		# and get the trimming coordinates for this read:
		h=$(awk -v id=$id -v amp=$best_amp '($1 == id && $6 == amp) { print $2 }' $bed_file_mod)
		r=$(awk -v id=$id -v amp=$best_amp '($1 == id && $6 == amp) { print $3 }' $bed_file_mod)
		# Nanofilt needs the tailcrop trimming coordinate in reference to the end of the read
		t=$(expr $read_length - $r)


		## trim the fastq read at the chosen coordinates h, t (= extract chosen amplicon)

		# if the amplicon is in the - strand, the read must be reverse-complemented before amplicon extraction
		if [ $strand == '-' ]
		then

			# this code: 1) finds the fastq read, 2) RCs it, 3) trims where indicated, and 4) appends the fastq amplicon to the output file
			seqkit grep -p $id $input_fastq | seqkit seq -t dna -w 0 -r -p -v | NanoFilt_Mau --headcrop $h --tailcrop $t >> ${output}

		# if the read is in the + strand, do the same as above, without the RC. 
		elif [ $strand == '+' ]
		then

			seqkit grep -p $id $input_fastq | NanoFilt_Mau --headcrop $h --tailcrop $t >> ${output}

		fi

	fi

# log varibles used. This will be useful for debugging
echo -en $id'\t'$read_length'\t'$tot_ampl'\t'$max'\t'$best_amp'\t'$strand'\t'$h'\t'$r'\t'$t'\n' >> $logfile

done

# 7) deactivate conda environment
conda deactivate 


# _________________________ #

### A few notes about the bed files:

	# column 2 of bed file always refers to Forward primer. It indicates the nucleotide position where the F primer begins. But this position begins at 0. So for example a value of 7 in column 2 means that the F primer's binding site begins in the 7th base if counting from 0, which is to say the 8th base if counting from 1. The first 7 bases need to be discarded (counting from 1)

	# column 3 of bed file always refers to Reverse primer. It indicates the nucleotide position inmediately after where the R primer ends. But these positions begin at 0. So for example a value of 2254 in column 3 means that the R primer's binding site ends in the 2253th base if counting from 0, which is to say the 2254th base if counting from 1. The bases that need to be discarded are those inmediately after position 2254, if counting from 1.  

	# If the PCR product is on + strand, and the bed file reads column 2 = 506, column 3 = 2254, interpret this as: The F primer begins binding at base 506+1=507 (discard 506 positions, starting counting from 1). The R primer ends binding at base 2254 (discard 2255 and onwards, starting counting from 1).

	# If the PCR product is on - strand, the coordinates in the bed file refer to the RC sequence. The easiest thing to do is to first RC the sequence, and then use the coordinates to extract the amplicon, in the same way as when the amplicon is on the + strand.
