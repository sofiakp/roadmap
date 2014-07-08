import sys
import os
import os.path
import numpy as np
import numpy.random
import argparse
import fileinput 
from sklearn.cross_validation import KFold
from sklearn.ensemble import RandomForestClassifier
from roadmapMotifUtils import *
from motifCvUtils import *
import pickle

def main():
    desc = '''Runs Random Forest CV or learning.
The path(s) to the feature matrices should be given as a comma separated list
using the infiles argument. The matched background files should be given as
the second argument (again, comma separated if more than one).
If more than one path is given, then these are assumed to be different sets of features
for the same regions, so they will be concatenated.'''
    parser = argparse.ArgumentParser(description = desc,
                                     formatter_class = argparse.RawTextHelpFormatter)
    parser.add_argument('infiles')
    parser.add_argument('bgfiles')
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
    
    for filename in args.infiles.split(','):
        files.append(filename.strip())

    for filename in args.bgfiles.split(','):
        bg_files.append(filename.strip())
    
    assert(len(files) == len(bg_files))
        
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
        numpy.random.seed(1)

        # You have to permute, because KFold always creates the folds sequentially.
        perm = numpy.random.permutation(len(y))
        y = y[perm]
        scores = scores[perm, :]
        
        cv = KFold(len(y), n_folds = 10)
        res = rf_classifier_cv(scores, y, cv, depths, njobs = njobs, ntrees = ntrees)
        np.savez_compressed(outfile, res = res, depths = depths)
        

if __name__ == '__main__':
    main()
