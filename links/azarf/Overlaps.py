import xlrd
import re

workbook = xlrd.open_workbook('mmc4.xls')
worksheets = workbook.sheet_names()

file=open("experimental_Data.bed","a")


# reading data from .xls file
for worksheet_name in worksheets:
        
	worksheet = workbook.sheet_by_name(worksheet_name)
	num_rows = worksheet.nrows-1 
	num_cols = worksheet.ncols-1
	curr_row =1
	while curr_row < num_rows:
		curr_row += 1
		chr_name= worksheet.cell_value(curr_row,2)
        	start=worksheet.cell_value(curr_row,3)
        	end=worksheet.cell_value(curr_row,4)
        	info=worksheet.cell_value(curr_row,12)
        	gene_name= info.split(';',2)[1]
		file.write('{0} {1} {2} {3}\n'.format(chr_name,start,end,gene_name))
        	
#reading data from .bed files
f1=open("core_15_enh_gene_c0.8_noCTCF_links.bed","r")
file=open("computational_Data.bed","a")

for line1 in f1:
    word1=line1.split('\t')[0]
    f2=open("core_15_mergedEnh_notOnProm_withDNase_names.bed", "r")
    for line2 in f2:
        word2=line2.split('\t')[3]
        word2=word2.strip()
        if word1==word2:
           file.write('{0} {1} {2} {3}'.format(line2.split('\t')[0],line2.split('\t')[1],line2.split('\t')[2],line1.split('\t')[1]))
