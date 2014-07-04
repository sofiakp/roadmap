import sys
import os
import os.path
import numpy as np
import numpy.random
from sklearn.cross_validation import ShuffleSplit
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import *
import re
from multiprocessing import Pool
import pickle

def get_random_bg(bg_size, cluster_sizes, filenames, outfile = None, 
                  motif_names = None, seed = 1):
    """Create random background for a cluster by sampling from the rest of the clusters.
    
    Args:
    - bg_size: Size of desired background.
    - cluster_sizes: Array of length n, with the sizes of all other clusters. 
    - filenames: Array of length n, with the paths to npz files with the feature matrices 
    of all other clusters. A random sample of size (roughly) bg_size will be created, by
    sampling randomly (without replacement) from all the files specified.
    - outfile: If not None, will save the sampled feature matrix, together with the motif names
    (feature names) there.
    
    Return value:
    The sampled feature matrix (if outfile is None) or None otherwise.
    """
    assert(len(cluster_sizes) == len(filenames))
    if len(cluster_sizes) == 0:
        return
    
    # Total number of background regions available
    tot_bg = sum(cluster_sizes)
    scores = None
    
    numpy.random.seed(seed)

    for i, other_file in enumerate(filenames):
        num_sel = round(bg_size * float(cluster_sizes[i]) / tot_bg)
        if num_sel > 0:
            data = np.load(other_file)
            scores_tmp = data['scores']
            data.close()
            scores_tmp = scores_tmp[numpy.random.permutation(cluster_sizes[i])[0:num_sel], :]
            if scores is None:
                scores = scores_tmp
            else:
                scores = np.concatenate((scores, scores_tmp), axis = 0)
    
    if scores.shape[0] > bg_size:
        scores = scores[numpy.random.permutation(scores.shape[0])[0:bg_size], :]
    
    if outfile is None:
        return scores
    else:
        np.savez_compressed(outfile, scores = scores, motif_names = motif_names)


def get_random_bg_star(args):
    get_random_bg(*args)
    

def get_random_bg_batch(filenames, bg_filenames, bg_dir, njobs = 1):
    """Greates random background for multiple clusters (in parallel).
    
    Args:
    - filenames: Files for which background will be created.
    - bg_filenames: Files from which backgrounds will be sampled. This should 
    be the full list of clusters. This can be different from the first argument
    if we only want to create backgrounds for a few of the clusters, while still
    using all the (other) clusters as background.
    - bg_dir: Directory where background files will be written.
    - njobs: Number of clusters to run in parallel.
    
    """
    
    nclusters = len(bg_filenames)
    cluster_sizes = []
    for fidx, filename in enumerate(bg_filenames):
        data = np.load(filename)
        if fidx == 0:
            motif_names = data['motif_names']
        cluster_sizes.append(data['scores'].shape[0])
        data.close()
    
    tasks = []
    for fidx, filename in enumerate(filenames):
        other_sizes = [cluster_sizes[j] for j in range(nclusters) if bg_filenames[j] != filename]
        other_filenames = [bg_filenames[j] for j in range(nclusters) if bg_filenames[j] != filename]
        outfile = os.path.join(bg_dir, re.sub('.npz$', '_bg.npz', os.path.basename(filename)))
        t = (cluster_sizes[fidx], other_sizes, other_filenames, outfile, motif_names)
        if njobs == 1:
            get_random_bg_star(t)
        else:
            tasks.append(t)
    
    if njobs > 1:
        pool = Pool(njobs)
        r2 = pool.imap(get_random_bg_star, tasks)
        pool.close()
        pool.join()


def classifier_cv(cv, model, X, y):
    res = np.zeros((len(cv), 4))
    
    for i, (train, test) in enumerate(cv):
        model.fit(X[train, :], y[train])
        pred = model.predict(X[test, :])
        res[i, :] = np.array([precision_score(y[test], pred), recall_score(y[test], pred),
                              accuracy_score(y[test], pred), f1_score(y[test], pred)])
    return np.mean(res, axis = 0)


def rf_classifier_cv(X, y, cv, depths, ntrees = 200, njobs = 1):
    res = np.zeros((len(depths), 4))
    for i, d in enumerate(depths):
        rf = RandomForestClassifier(random_state = 1, n_estimators = ntrees, criterion = 'entropy', 
                                    min_samples_leaf = 10, max_depth = d, n_jobs = njobs)
        res[i, :] = classifier_cv(cv, rf, X, y)
    return res


def read_model(filename):
    """Reads a learned model.

    Args:
    - filename: Name of file (pkl)
    
    Return value:
    A tuple (model, feature_names)
    """

    with open(filename, 'rb') as infile:
        model = pickle.load(infile)
        motif_names = pickle.load(infile)
    return (model, motif_names)
