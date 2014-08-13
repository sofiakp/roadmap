import xlrd
import re

from collections import defaultdict
data_dict = defaultdict(list)

data_list = []  

with open("core_15_enh_gene_c0.8_noCTCF_links.txt") as f:
     for line in f:
          enhId = line.split('\t')[0].strip()
          geneName= line.split('\t')[1].strip()
          details = (geneName)
          data_dict[enhId].append(details)

out=open("Computational_Data.bed", "w")
with open("core_15_mergedEnh_notOnProm_withDNase_names.bed") as f:
     for line in f:
         enh_name=line.split('\t')[3].strip()
         if enh_name in data_dict:
            for value in data_dict[enh_name]:
                out.write('{0}\t{1}\t{2}\t{3}\n'.format(line.split('\t')[0].strip(),line.split('\t')[1].strip(),line.split('\t')[2].strip(),value))




workbook = xlrd.open_workbook('mmc4.xls')
worksheets = workbook.sheet_names()

out=open("experimental_Data.bed","w")

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
		out.write('{0}\t{1}\t{2}\t{3}\n'.format(chr_name,start,end,gene_name))

