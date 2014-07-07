import sys
import argparse
import fileinput
import numpy as np
import numpy.random
from roadmapMotifUtils import *
from lightning.classification import CDClassifier
from sklearn.metrics import confusion_matrix, accuracy_score

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
    parser.add_argument('--train', type = float, default = 0.8,
                        help = 'Fraction of examples used for training. [%(default)s]')
    args = parser.parse_args()
    outfile = args.outfile
    alpha = args.alpha
    train_prc = args.train
    assert(alpha >= 0)
    assert(train_prc > 0 and train_prc < 1)
    
    files = []
    for filename in fileinput.input([]):
        files.append(filename.strip())
        
    (scores, rule_names) = merge_scores(files)
    
    y = np.repeat(np.arange(len(files)), scores.shape[0] / len(files))
    
    model = CDClassifier(penalty = 'l1/l2', loss = 'squared_hinge', multiclass = True, 
                             max_iter = 100, alpha = alpha, C = 1.0 / y.size, 
                             tol = 1e-3, random_state = 1, verbose = 2)
    
    numpy.random.seed(1)
    # You have to permute, because KFold always creates the folds sequentially.
    perm = numpy.random.permutation(len(y))
    y = y[perm]
    scores = scores[perm, :]
    
    ntrain = int(y.size * train_prc)
    ntest = (y.size - ntrain) / 2
    train_idx = np.arange(ntrain)
    val_idx = np.arange(ntrain, ntrain + ntest)
    test_idx = np.arange(ntrain + ntest, y.size)
    all_idx = [train_idx, val_idx, test_idx]
    
    model.fit(scores[train_idx, :], y[train_idx])
    acc = []
    confusion = []
    for idx in all_idx:
        pred = model.predict(scores[idx, :])
        acc.append(accuracy_score(y[idx], pred))
        confusion.append(confusion_matrix(y[idx], pred))
    
    with open(args.outfile, 'wb') as outfile:
        pickle.dump(model, outfile)
        pickle.dump(rule_names, outfile)
        pickle.dump(acc, outfile)
        pickle.dump(confusion, outfile)


if __name__ == '__main__':
    main()
