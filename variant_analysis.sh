#!/bin/sh

# Checking annovar_refGene.txt to see what kind of transcript IDs are in it (NM_, NR_, etc)
awk '$i=substr($i,1,3)' annovar_refGene.txt | sort | uniq -c

# Find all variants with more than 1 alternate allele
grep -v "^#" SeattleSeqAnnotation138.NA12878_Y_removed.vcf.359966521039.txt | awk '{print $5}' | awk '$0 ~ /,/ {print $0}' | less -S

# Look at Transcript ID column (2nd column) of variant table to make sure there are only transcript IDs in this column
grep -v "^Position" ../SeattleSeq/seattleseq_variants.txt | awk '{print substr($2,0,4)}' | sort | uniq -c | less -S

# Get all lines from variant table that have messed up transcript ID columns
grep -v "^Position" vat_indel_variants.txt | awk '$2 !~ /^E/ {print $0}' | less -S

# Check column 1 of VCF (chr) and see which chromosomes are in file and how many lines there are for each chr
grep -v "^#" NA12878_indelmapper.annotated.vcf | awk '{print $1}' | sort | uniq -c | less -S

# Remove all lines that are on chr Y (This does not remove header lines from new file)
awk -F"\t" '!($1=="chrY")' NA12878_indelmapper.annotated.vcf > new_indelmapper.vcf

# Create BED files of GVF files
awk -v OFS='\t' '{print $1,$4,$5}' NA12878_indelmapper.annotated.gvf > indels.bed

# Prints out all 3 columns from annovar file and last column of seattleseq file
# Line is printed only if first column (Position) is in both files
# This assumes files are sorted. If not, then run
# join -o 1.1,1.2,1.3,2.3 <(sort -k2 file1) <(sort -k2 file2)
join -o 1.1,1.2,1.3,2.3 annovar_test.txt seattleseq_test.txt

# Comparing more than 2 files ONLY by position
join -t $'\t' -o 1.1,1.2,1.3,2.2,2.3 annovar_test.txt seattleseq_test.txt | join -t $'\t' -o 1.1,1.2,1.3,1.4,1.5,2.2,2.3 - snpeff_test.txt | join -t $'\t' -o 1.1,1.2,1.3,1.4,1.5,1.6,1.7,2.2,2.3 - vep_variants.txt

# Look at the different types of transcripts IDs
perl all_IDs.pl vep_variants.txt | sort | uniq -c | less -S

# Print out all lines of a specific chromosome from variant table
grep -v "^Position" vep.txt | awk '$1 ~ /^19/ {print $0}' > vep_chr19.txt

# Print out all unique terms from ANNOVAR variant table before the terms 
# have been mapped. It is different because ANNOVAR terms have whitespaces.
grep -v "^Position" annovar_variants.txt | cut -f 3- | sort | uniq -c | less

# Reformat files to input them into database
awk '$2="ANNOVAR"' annovar_chr19.txt > reformatted_annovar_chr19.txt
cat reformatted_annovar_chr19.txt reformatted_seattleseq_chr19.txt reformatted_snpeff_chr19.txt reformatted_vaast_chr19.txt reformatted_vep_chr19.txt > chr19_all_reformatted.txt

# Sort ANNOVAR table_annovar.annovar_multianno.txt file
(head -n 1 NA12878_table_annovar.annovar_multianno.txt && tail -n +2 NA12878_table_annovar.annovar_multianno.txt | sort -k 1,1n -k 2,2n -k 3,3n) > sorted_NA12878_table_annovar.annovar_multianno.txt

# Remove lines in inconsistent_lines.txt from main file
sort inconsistent_lines.txt sorted_NA12878_table_annovar.annovar_multianno.txt | uniq -u

# Merge variant tables with join which will only print positions that are 
# annotated by all tools
perl ../../annotation_analysis_scripts/combine_tables.pl > chr19_variants_matched_positions_all_tools.txt

# Remove period and trailing numbers from ensembl IDs
awk '{sub(/\.[0-9]/,""); print}'

# Add 4th column to variant table files that includes the name of the tool
awk -F, '{$(NF+1)="Seattleseq";}1' OFS='\t' seattleseq.txt > out

# Split up chr, start, end into separate columns
perl split_position.pl out > reformatted_seattleseq.txt

# Get count of number of unique variants from GVF file
grep -v "^#" NA12878_Y_removed.gvf | awk -v OFS='\t' '{print $1,$4,$5}' | sort | uniq -c | sort -rn | less -SN

# Get count of number of unique variant from VCF file
grep -v "^#" NA12878-NGv3-LAB1360-A.snp-indel_merged.final.Y_chr_removed.vcf | awk -v OFS='\t' '{print $1,$2}' | sort | uniq -c | sort -rn | less -SN

# Look at the differences between the unique variant positions in the 
# VCF and GVF files
diff -u unique_vcf.txt unique_gvf.txt | awk '$1~/-/ || /+/ {print $0}' > differences_between_vcf_gvf.txt

# Count the total number of unique positions called by at least 1 tool
# This number is slightly different than adding up all of the unique 
# positions from each tool because some variants may not be annotated by
# all tools or the position will be off by 1 or more bases.
grep -v "^chr" number_of_tools_annotate_each_position.txt | awk -v OFS='\t' '{print $1,$2,$3}' | sort | uniq -c | sort -rn | wc -l

# Breakdown of number of positions called by 1,2,3,4,5 or all 6 tools
grep -v "^chr" number_of_tools_annotate_each_position.txt | awk '{print $4}' | sort | uniq -c | sort -rn
