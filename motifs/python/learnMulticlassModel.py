import sys
import argparse
import fileinput
import numpy as np
import numpy.random
import scipy.sparse as sp
import pickle
from roadmapMotifUtils import *
from lightning.classification import CDClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import confusion_matrix, accuracy_score
from sklearn.cross_validation import StratifiedKFold, StratifiedShuffleSplit
from math import ceil

def main():
    desc = '''
Learns a multi-class classification model that discriminates across clusters.

The path(s) to the feature matrices are read from STDIN. Each path should contain
be an npz file containing the feature matrix for a different cluster. Each cluster
will be considered as a separate class. A multi-class classification model will
be trained on a fraction of the data (controlled by the --train parameter). The 
rest of the data will be split on a test and a validation set of equal sizes.'''
    parser = argparse.ArgumentParser(description = desc)
    parser.add_argument('outfile')
    parser.add_argument('--alpha', type = float, default = 0.01,
                        help = 'Coefficient of the penalty term.')
    parser.add_argument('--tol', type = float, default = 0.01,
                        help = 'Tolerance for the termination criterion.')
    parser.add_argument('--train', type = float, default = 0.8,
                        help = 'Fraction of examples used for training. [%(default)s]')
    parser.add_argument('--maxfreq', type = float, default = 0.3,
                        help = 'Maximum frequency for a feature to be considered. [%(default)s]')
    parser.add_argument('--log', action = 'store_true', default = False,
                        help = 'Use logistic regression')
    args = parser.parse_args()
    outfile = args.outfile
    alpha = args.alpha
    assert(alpha >= 0)
    train_prc = args.train
    assert(train_prc > 0 and train_prc < 1)
    max_freq = args.maxfreq
    assert(max_freq >= 0 and max_freq <= 1)
        
    files = []
    for filename in fileinput.input([]):
        files.append(filename.strip())
        
    (scores, rule_names) = merge_scores(files, vertical = True)
    
    y = np.repeat(np.arange(len(files)), scores.shape[0] / len(files))

    if args.log:
        model = LogisticRegression(penalty = 'l1', C = alpha, 
                                   tol = args.tol, random_state = 1)
    else:
        model = CDClassifier(penalty = 'l1/l2', loss = 'squared_hinge', multiclass = True, 
                             max_iter = 100, alpha = alpha, C = 1.0 / y.size, 
                             shrinking = False, # weird behavior if this is set to True
                             tol = args.tol, random_state = 1, verbose = 2)

    numpy.random.seed(1)
    perm = numpy.random.permutation(len(y))
    y = y[perm]
    scores = scores[perm, :]

    hits = np.sum(scores, axis = 0) / float(scores.shape[0])
    print >> sys.stderr, 'Max frequency', np.max(hits)
    print >> sys.stderr, 'Num features with freq >', max_freq, np.sum(hits > max_freq)

    sel_feat = np.argwhere(hits <= max_freq).flatten()
    rule_names = list(np.array(rule_names)[sel_feat])
    scores = scores[:, sel_feat]
    print >> sys.stderr, 'Scores shape', scores.shape

    # Get balanced training, test, and validation sets.
    cv = StratifiedShuffleSplit(y, 1, 1.0 - train_prc, indices = True)
    for train, test in cv:
        train_idx = train
        test_tmp = test
    # Now split the test set (which is balanced by design) into two balanced parts.
    cv = StratifiedShuffleSplit(y[test_tmp], 1, 0.5, indices = True)
    for train, test in cv: 
        test_idx = test_tmp[train]
        val_idx = test_tmp[test]
    
    assert(len(set(train_idx).intersection(set(test_idx))) == 0)
    assert(len(set(val_idx).intersection(set(test_idx))) == 0)
    assert(len(set(train_idx).intersection(set(val_idx))) == 0)
    print >> sys.stderr, 'Will use', len(train_idx), 'examples for training,', \
        len(test_idx), ' for testing, and', len(val_idx), 'for validation'
    all_idx = [train_idx, val_idx, test_idx]
    #assert(np.sum([len(i) for i in all_idx]) == y.size)

    model.fit(sp.csr_matrix(scores[train_idx, :], dtype = np.float), y[train_idx])
    acc = []
    confusion = []
    for idx in all_idx:
        pred = model.predict(sp.csr_matrix(scores[idx, :], dtype = np.float))
        acc.append(accuracy_score(y[idx], pred))
        confusion.append(confusion_matrix(y[idx], pred))
    
    with open(args.outfile, 'wb') as outfile:
        pickle.dump(model.coef_, outfile)
        pickle.dump(rule_names, outfile)
        pickle.dump(acc, outfile)
        pickle.dump(confusion, outfile)


if __name__ == '__main__':
    main()
