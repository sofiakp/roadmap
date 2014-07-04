import sys
import os
import os.path
import numpy as np
import argparse
import fileinput 
from sklearn.cross_validation import KFold
from sklearn.ensemble import RandomForestClassifier
from roadmapMotifUtils import *
from motifCvUtils import *
import pickle

def main():
    desc = '''
    Runs Random Forest CV or learning.
    The path(s) to the feature matrices are read from STDIN. If more than
    one path is given, then these are assumed to be different sets of features
    for the same regions, so they will be concatenated.
    
    For each path given in the input, it will try to read the corresponding 
    background (negative set) from
    <indir>/random_bg/<filename>_bg.npz,
    where indir is the directory of the input file, and <filename> is the basename
    of the input file.
    '''
    parser = argparse.ArgumentParser(description = desc,
                                     formatter_class = argparse.RawTextHelpFormatter)
    parser.add_argument('outfile')
    parser.add_argument('--depths', default = '2,3,4',
                        help = 'Comma separated list of tree depths to cross validate')
    parser.add_argument('--njobs', type = int, default = 1, 
                        help = 'Number of processors to use for random forest learning')
    parser.add_argument('--ntrees', type = int, default = 200,
                        help = 'Number of trees in the random forest')
    parser.add_argument('--nocv', action = 'store_true', default = False,
                        help = 'Just learn the model on all the data')
    args = parser.parse_args()
    outfile = args.outfile
    depths = [int(s) for s in args.depths.split(',')]
    njobs = args.njobs
    ntrees = args.ntrees
    
    files = []
    bg_files = []
    
    for filename in fileinput.input([]):
        files.append(filename.strip())
        base_dir = os.path.dirname(files[-1])
        basename = re.sub('.npz$', '_bg.npz', os.path.basename(files[-1]))
        bg_files.append(os.path.join(base_dir, 'random_bg', basename))
        
    (scores, motif_names) = merge_scores(files)
    (scores_bg, motif_names_bg) = merge_scores(bg_files)
    assert(scores.shape[1] == scores_bg.shape[1])
    assert(list(motif_names) == list(motif_names_bg))
    
    y = np.concatenate((np.ones((scores.shape[0],)), np.zeros((scores_bg.shape[0],))))
    scores = np.concatenate((scores, scores_bg), axis = 0)

    if args.nocv:
        assert(len(depths) == 1)
        rf = RandomForestClassifier(random_state = 1, n_estimators = ntrees, 
                                    criterion = 'entropy', min_samples_leaf = 10, 
                                    max_depth = depths[0], n_jobs = njobs)
        rf.fit(scores, y)
        with open(outfile, 'wb') as outfile:
            pickle.dump(rf, outfile)
            pickle.dump(motif_names, outfile)
    else:
        perm = permutation(len(y))
        y = y[perm]
        scores = scores[perm, :]
        
        cv = KFold(len(y), n_folds = 10)
        res = rf_classifier_cv(scores, y, cv, depths, njobs = njobs, ntrees = ntrees)
        np.savez_compressed(outfile, res = res, depths = depths)
        

if __name__ == '__main__':
    main()
