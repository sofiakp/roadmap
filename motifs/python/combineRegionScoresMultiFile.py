import sys
import fileinput
import argparse
import numpy as np
from roadmapMotifUtils import *
import re

def score_dict_to_mat(score_dict):
    nregions = len(score_dict)
    region_names = sorted(score_dict.keys())
    for i, name in enumerate(region_names):
        scores_tmp = score_dict[name]
        if i == 0:
            scores = np.zeros((nregions, scores_tmp.size))
        scores[i, :] = scores_tmp
    return (scores, region_names)

def main():
    desc = '''Summarizes the scores of a set of score matrices. 
The filenames of the score matrices are read from stdin. Each of them
should contain, in addition to the matrix scores and the motif names,
an array region_names. 

A file mapping region names to broader regions is also given as input.
Regions in the input files that overlap each of the broader regions will
have their scores combined. By default, the summary function is maximum
for scores and sum for counts.

Regions in the input feature matrix whose name does not appear in the 
region name mapping will be ignored.

See also summarize_scores_iter in roadmapMotifUtils.'''
    parser = argparse.ArgumentParser(description = desc)
    parser.add_argument('mapfile', help = 'File mapping region names to broader regions')
    parser.add_argument('outfile')
    parser.add_argument('--cmax', action = 'store_true', default = False,
                        help = 'Use maximum to aggregate the counts, instead of add')
    args = parser.parse_args()

    region_map = {}
    with open(args.mapfile, 'r') as mapfile:
        for line in mapfile:
            fields = line.strip().split()
            if not fields[0] in region_map:
                region_map[fields[0]] = []
            # Multi-mapping
            region_map[fields[0]].append(fields[1])

    new_scores = None
    new_counts = None
    
    if args.cmax:
        cfun = np.maximum
    else:
        cfun = np.add

    for fidx, filename in enumerate(fileinput.input([])):
        data = np.load(filename.strip())
        scores = data['scores']
        if fidx > 0:
            assert(list(motif_names) == list(data['motif_names']))
        else: 
            motif_names = data['motif_names']

        region_names = data['region_names']
        data.close()
        is_score = np.array([not re.search('_scores', m) is None for m in motif_names], np.bool)
        is_count = np.logical_not(is_score)

        new_scores = summarize_scores_iter(np.float32(scores[:, is_score]), region_names, 
                                      region_map, new_scores, np.maximum)
        print >> sys.stderr, 'Read', len(new_scores), 'regions'
        new_counts = summarize_scores_iter(np.float32(scores[:, is_count]), region_names, 
                                      region_map, new_counts, cfun)

    motif_names = np.array(motif_names)
    motif_names = list(np.concatenate((motif_names[is_score], motif_names[is_count])))
    score_mat, region_names = score_dict_to_mat(new_scores)
    count_mat, region_names_tmp = score_dict_to_mat(new_counts)
    assert(list(region_names) == list(region_names_tmp))

    scores = np.concatenate((score_mat, count_mat), axis = 1)

    np.savez_compressed(args.outfile, scores = scores, motif_names = motif_names,
                        region_names = region_names)

if __name__ == '__main__':
    main()
