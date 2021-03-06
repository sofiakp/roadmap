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
from math import ceil

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
        num_sel = int(ceil(bg_size * float(cluster_sizes[i]) / tot_bg))
        if num_sel > 0:
            data = np.load(other_file)
            scores_tmp = data['scores']
            data.close()
            scores_tmp = scores_tmp[numpy.random.permutation(cluster_sizes[i])[0:num_sel], :]
            print >> sys.stderr, other_file, scores_tmp.shape
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
        res_tmp = np.array([precision_score(y[test], pred), recall_score(y[test], pred),
                            accuracy_score(y[test], pred), 0.0])
        # F1 is ill defined when both precision and recall are 0, so we'll set it to 0.
        if res_tmp[0] > 0 or res_tmp[1] > 0:
            res_tmp[3] = f1_score(y[test], pred)
        res[i, :] = res_tmp
    return np.mean(res, axis = 0)


def rf_classifier_cv(X, y, cv, depths, ntrees = 200, njobs = 1, min_leaf = 10):
    res = np.zeros((len(depths), 4))
    for i, d in enumerate(depths):
        rf = RandomForestClassifier(random_state = 1, n_estimators = ntrees, criterion = 'entropy', 
                                    min_samples_leaf = min_leaf, max_depth = d, n_jobs = njobs)
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


def important_nodes(features, imp, imp_cut):
    """Returns indicators of which notes use important features.
    
    Args:
    - features: Numpy array of length N with indices of features.
    - imp: Numpy array with feature importances.
    - imp_cut: Cutoff of importance.
    
    Return value:
    A boolean numpy array of length N, with indicators of which 
    nodes are interior and use features with importance passing the cutoff.
    """
    is_interior = features >= 0
    is_imp = np.zeros(features.shape)
    is_imp[is_interior] = imp[features[is_interior]] >= imp_cut
    return np.logical_and(is_interior, is_imp)


def simplify_and_rules(rules, thresh):
    """Simplifies rules of the form (X>x)AND(X>y) to (X>max(x,y)).
    """

    for i in rules.keys():
        if i == 1:
            continue
        # Get the rules where all the features are equal to the first
        rep = np.tile(np.reshape(rules[i][:, 0], (rules[i].shape[0], 1)), (1, i))
        bad_rules = np.all(rules[i] == rep, axis = 1)
        if bad_rules.size == 0:
            continue
        rules[1] = np.concatenate((rules[1], 
                                   np.reshape(rules[i][bad_rules, 0], (np.sum(bad_rules), 1))))
        thresh[1] = np.concatenate((thresh[1], 
                                    np.reshape(np.max(thresh[i][bad_rules, :], axis = 1), (np.sum(bad_rules), 1))))
        rules[i] = rules[i][np.logical_not(bad_rules), :]
        thresh[i] = thresh[i][np.logical_not(bad_rules), :]
    return (rules, thresh)


def order_rules(rules, thresh):
    """Rearranges the features within each rule in increasing index order.
    This makes identifying repetitive rules easier."""

    for i in rules.keys():
        if i == 1:
            continue
        for j in range(rules[i].shape[0]):
            sidx = np.argsort(rules[i][j, :])
            rules[i][j, :] = rules[i][j, sidx]
            thresh[i][j, :] = thresh[i][j, sidx]
    return (rules, thresh)


def extract_rf_rules(rf, imp_cut = 0, ntrees = None, remove_neg = False):
    """Gets rules from a random forest.
    
    Args:
    - rf: RandomForestClassifier object
    - imp_cut: Only consider nodes with features with importance 
    greater than that cutoff.
    - ntrees: Only consider the first ntrees trees of the forest.
    If this is None or 0, all trees will be considered.
    - remove_neg: Set negative thresholds to 0.

    Return value:
    A tuple of dictionaries (rules, thresh).
    rules[i] will be an array of size N x i containing feature indices of nodes 
    in paths of length i (where N is the number of such paths that are formed 
    of nodes containing features passing the cutoff of importance).
    thresh[i] will be a similar array of the corresponding thresholds.
    NOTE!!!: The current implementation only returns paths of lenght 1 and 2.
    """
    
    if ntrees is None or ntrees == 0:
        ntrees = rf.n_estimators
    else:
        ntrees = min(ntrees, rf.n_estimators)

    imp = rf.feature_importances_
    #imp_cut = np.percentile(imp, imp_prc)
    
    rules = {}
    thresh = {}
    for i in range(1, 3):
        rules[i] = np.empty((0, i), dtype = np.int)
        thresh[i] = np.empty((0, i))
    
    # Loop through decision trees of the forest.
    # First, get the nodes that contain important features. To get paths of 
    # length 2, we only need to consider paths starting at one of the important
    # nodes. Further, we only consider the right children, since we only
    # care about what happens when the motif score is greater than some threshold.
    # (The rules have the form feature <= threshold and the left child corresponds 
    # to the yes answer. This is not obvious at all, unless you print out the trees
    # and look at the tree.c code of the library...
    # Note: this scheme can be extended to longer paths. At each iteration
    # we will be appending to the right of paths of smaller length.
    for tidx in range(ntrees):
        member = rf.estimators_[tidx]
        # Similar to the "rules" dictionary, but has just indices of nodes.
        rule_ind = {}
        for i in range(1, 3):
            rule_ind[i] = np.empty((0, i), dtype = np.int)
        t = member.tree_
        nnodes = len(t.feature)
        features = t.feature
        
        is_imp = important_nodes(features, imp, imp_cut)
        # Get the indices of all the nodes that contain important features.
        rule_ind[1] = np.argwhere(is_imp)
        if rule_ind[1].size == 0:
            continue

        # Get the indices of the nodes selected in the previous step.
        # The reshaping is just so I don't get a stupid deprecation warning.
        children = t.children_right[rule_ind[1].flatten()]
        tmp_feat = -np.ones(children.shape, dtype = np.int)
        # Get the features associated with the children and select those children
        # that are contain important features.
        tmp_feat[children >= 0] = features[children[children >= 0]]
        is_imp = important_nodes(tmp_feat, imp, imp_cut)
        parents = rule_ind[1][is_imp].flatten()
        rule_ind[2] = np.reshape(np.concatenate((parents, children[is_imp])), (2, sum(is_imp))).T
        for i in range(1, 3):
            if rule_ind[i].size == 0:
                continue
            rules[i] = np.concatenate((rules[i], features[rule_ind[i]]), axis = 0)
            thresh[i] = np.concatenate((thresh[i], t.threshold[rule_ind[i]]), axis = 0)
    
    if remove_neg:
        for i in range(1, 3):
            thresh[i] = np.maximum(thresh[i], 0)
    rules, thresh = simplify_and_rules(rules, thresh)
    rules, thresh = order_rules(rules, thresh)
    return (rules, thresh)


def remove_repetitive_rules(rules, thresh, thresh_cut = 0.01):
    """Remove similar rules from a set of rules.
    
    Two rules are similar if they involve the same set of features and 
    all their thresholds are up to thresh_cut from each other.
    
    Does NOT check for changes in the order of the features in the rule.
    
    Return value:
    A tuple (rules, thresh) with repetitive rules removed.
    """
    
    new_rules = {}
    new_thresh = {}
    
    # Iterate through rule lengths
    for i, r in rules.iteritems():
        t = thresh[i]
        # Dictionary from rules (feature indices) to a numpy arrays N x i.
        # where N is the total number of different thresholds associated 
        # with the rule.
        rdict = {}
        # Iterate through rules of length i.
        for j in range(r.shape[0]):
            rtup = tuple(r[j, :]) # Tuples are hashable.
            new_t = np.reshape(t[j, :], (1, i))
            if rtup in rdict:
                diff = np.abs(rdict[rtup] - new_t) #/ np.minimum(np.abs(rdict[rtup]), np.abs(new_t)) 
                if not np.any(np.all(diff < thresh_cut, axis = 1)):
                    rdict[rtup] = np.concatenate((rdict[rtup], new_t), axis = 0)
            else:
                rdict[rtup] = new_t
    
        new_rules[i] = np.empty((0, i), dtype = np.int)
        new_thresh[i] = np.empty((0, i))
        for rtup, rthresh in rdict.iteritems():
            new_rules[i] = np.concatenate((new_rules[i], np.repeat(np.array(rtup, ndmin = 2), 
                                                                   rthresh.shape[0], axis = 0)))
            new_thresh[i] = np.concatenate((new_thresh[i], rthresh))
            assert(new_rules[i].shape[0] == new_thresh[i].shape[0])
    return (new_rules, new_thresh)


def get_rule_names(rules, thresh, motif_names):
    """Generates names for a set of complex rules.
    
    Args: 
    - rules, thresh: Dictionaries with features and thresholds, 
    as returned by extract_rf_rules.
    - motif_names: Feature names.
    
    Return value:
    A list of rule names.
    """
    
    out_names = []
    for i, r in rules.iteritems():
        for j in range(r.shape[0]):
            parts = ['{}>{:.3f}'.format(n, t) for (n, t) in zip(motif_names[r[j, :]], thresh[i][j, :])]
            if i > 1:
                parts = ['(' + p + ')' for p in parts]
            out_names.append('AND'.join(parts))
    return out_names


def apply_rules(scores, rules, thresh):
    """Applies a set of rules to a set of examples.
    
    Args:
    - scores: A feature matrix.
    - rules, thresh: Dictionaries with features and thresholds, 
    as returned by extract_rf_rules.
    
    Return value:
    A boolean matrix NxM where N is the number of examples (rows of scores)
    and M is the total number of rules of any length.
    """
    
    tot_rules = sum(r.shape[0] for r in rules.values())
    bin_scores = np.zeros((scores.shape[0], 0), dtype = np.bool)
    for i, r in rules.iteritems():
        for j in range(r.shape[0]):
            # For each example, the rule is true if all the features pass
            # the corresponding thresholds.
            b = np.all(scores[:, r[j, :]] > np.tile(thresh[i][j, :], (scores.shape[0], 1)), axis = 1)
            bin_scores = np.concatenate((bin_scores, np.reshape(b, (scores.shape[0], 1))), axis = 1)
        # The above could be done by taking advantage of broadcasting, but 
        # I want to make sure I'm taking care of edge cases.
        #bin_scores = np.concatenate((bin_scores, np.all(scores[:, r] > thresh[i], axis = 2)), axis = 1)
    assert(bin_scores.shape[1] == tot_rules)
    return bin_scores


def sample_example_idx(nex, sample_size):
    """Gets a random sample of size sample_size from [0, nex - 1].
    If sample_size > nex, then it samples with replacement.

    Return value:
    A numpy array (sample_size,) with indices of selected samples
    from [0, nex - 1].
    """

    if nex >= sample_size:
        return numpy.random.permutation(nex)[0:sample_size]
    else:
        return numpy.random.random_integers(0, nex - 1, (sample_size,))

