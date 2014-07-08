import sys
import argparse
import numpy as np
from roadmapMotifUtils import *
import re

def main():
    desc = 'Applies summarize_scores on a given score matrix'
    parser = argparse.ArgumentParser(description = desc)
    parser.add_argument('infile')
    parser.add_argument('idfile', help = 'File with region ids')
    parser.add_argument('outfile')
    args = parser.parse_args()
    
    data = np.load(args.infile)
    scores = data['scores']
    motif_names = data['motif_names']
    data.close()
    is_score = np.array([not re.search('_scores', m) is None for m in motif_names], np.bool)
    is_count = np.array([not s for s in is_score], np.bool)
    region_ids = []
    with open(args.idfile, 'r') as infile:
        for line in infile:
            if line.strip() == '.':
                region_ids.append(None)
            else:
                region_ids.append(line.strip())
            
    scores_tmp, new_names = summarize_scores(scores[:, is_score], region_ids, np.mean)
    counts_tmp, new_names_tmp = summarize_scores(scores[:, is_count], region_ids, np.sum)
    motif_names = np.array(motif_names)
    motif_names = list(np.concatenate((motif_names[is_score], motif_names[is_count])))
    scores = np.concatenate((scores_tmp, counts_tmp), axis = 1)

    np.savez_compressed(args.outfile, scores = scores, motif_names = motif_names)

if __name__ == '__main__':
    main()
