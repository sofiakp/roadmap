import sys
import os
import os.path
import argparse
import numpy as np
from roadmapMotifUtils import *
import re

def main():
    desc = '''Reads multiple outputs of HOMER annotatePeaks.pl on the same peak file
and merges them. All files <indir>/<pref><name>_[scores|counts].txt and will be read. 
The list of motif names is read from a file. If the list is not provided, it will just 
read <indir>/<pref>_[scores|counts].txt (which makes sense if all the motifs are in the 
same file).'''
    parser = argparse.ArgumentParser(description = desc)
    parser.add_argument('indir', help = 'Directory with HOMER outputs')
    parser.add_argument('pref', help = 'Prefix of input files')
    parser.add_argument('outfile')
    parser.add_argument('--motifs', default = None, 
                        help = 'File with the list of motif names (with the prefix ">"). ' + 
                        'Could be a HOMER motif file, in which case names will be read from the headers.')
    parser.add_argument('--insufs', default = "_scores.txt,_counts.txt",
                        help = "List of suffixes. Default _scores.txt,_counts.txt")
    parser.add_argument('--nocounts', '-c', action = 'store_true', default = False,
                        help = 'Do not read count files')
    args = parser.parse_args()
    indir = args.indir
    pref = args.pref
    motif_file = args.motifs

    if motif_file is None:
        motif_names = ['']
    else:
        motif_names = []
        with open(motif_file, 'r') as infile:
            for line in infile:
                if line.startswith('>'):
                    motif_names.append(line.strip().split('\t')[0][1:])

    sufs = args.insufs.split(',')
    for sidx, s in enumerate(sufs):
        filenames = [os.path.join(indir, pref + m + s) for m in motif_names]        
        if any([not os.path.isfile(f) for f in filenames]):
            raise ValueError('Missing files for suf ' + s)

        (scores_tmp, motif_names_tmp) = merge_homer_annotate_output(filenames)
        assert(len(motif_names_tmp) == scores_tmp.shape[1])
        motif_names_tmp = [m + re.sub('.txt', '', s) for m in motif_names_tmp]            

        if sidx == 0:
            scores = scores_tmp
            out_motif_names = motif_names_tmp
        else:
            assert(scores.shape[0] == scores_tmp.shape[0])
            scores = np.concatenate((scores, scores_tmp), axis = 1)
            out_motif_names.extend(motif_names_tmp)

    np.savez_compressed(args.outfile, scores = scores, motif_names = out_motif_names)


if __name__ == '__main__':
    main()
