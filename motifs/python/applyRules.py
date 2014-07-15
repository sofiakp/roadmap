import sys
import numpy as np
import pickle
import argparse
import numpy.random
from motifCvUtils import *

def main():
    desc = '''Applies motif rules on a motif matrix.
    RULEFILE should contain dictionaries rules and thresh (as the output of extract_rf_rules).
    If the argument --sizes is specified it should point to a file with a dictionary of cluster
    sizes. In this case the median cluster size will be used to get a sample of the input feature
    matrix. 
    '''
    parser = argparse.ArgumentParser(description = desc)
    parser.add_argument('featfile', help = 'File with feature matrix with motif scores')
    parser.add_argument('rulefile', help = 'File with rules')
    parser.add_argument('outfile')
    parser.add_argument('--sizes', default = None, 
               help = 'File with cluster sizes.')
    parser.add_argument('--maxsize', type = int, default = None, 
               help = 'Get at most that many regions from a cluster')
    args = parser.parse_args()
    feat_file = args.featfile
    size_file = args.sizes
    rule_file = args.rulefile
    
    if not os.path.isfile(feat_file):
        raise IOError('Feature file does not exist: ' + feat_file)
    data = np.load(feat_file)
    scores = data['scores']
    data.close()
    
    if size_file is None:
        if args.maxsize is None:
            med_len = scores.shape[0]
        else:
            med_len = min(args.maxsize, scores.shape[0])
    else:
        if not os.path.isfile(size_file):
            raise IOError('Size file does not exist: ' + size_file)
        with open(size_file, 'rb') as f:
            cluster_sizes = pickle.load(f)
        med_len = int(np.median(cluster_sizes.values()))
    
    if not os.path.isfile(rule_file):
        raise IOError('Feature file does not exist: ' + rule_file)
    with open(rule_file, 'rb') as f:
        rules = pickle.load(f)
        thresh = pickle.load(f)
        rule_names = pickle.load(f)
    
    numpy.random.seed(1)
    ex_idx = sample_example_idx(scores.shape[0], med_len)
    
    bin_feat = apply_rules(scores[ex_idx, :], rules, thresh)
    assert(bin_feat.shape[0] == ex_idx.size)
    assert(bin_feat.shape[1] == len(rule_names))
    
    np.savez_compressed(args.outfile, scores = bin_feat, motif_names = rule_names)


if __name__ == '__main__':
    main()
