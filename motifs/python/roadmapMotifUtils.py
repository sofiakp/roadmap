import sys
import os
import os.path
import numpy as np
import re
from scipy.spatial.distance import pdist, cdist, squareform

def read_homer_motifs(motif_file, motif_len, motif_pref):
    """Reads a file with HOMER motifs and creates a matrix with the PWMs.
    
    Args:
    - motif_file: File with motifs of fixed length, motif_len
    - motif_len
    - motif_pref: Motifs will be named <motif_pref>_motif_<num>
    
    Return value:
    A tuple (mot_mat, names, pvals, log_odds)
    - mot_mat: A matrix num_motifs x (motif_len * 4) with the flattened PWMs.
    - rev_mot_mat: A matrix of reverse complements of PWMs.
    - names: motif names following the format described above.
    - pvals: motif pvalues, read from the HOMER file.
    - log_odds: log odds detection threshold, read from the HOMER file.
    """
    mot_mat = np.empty((0, motif_len * 4))
    rev_mot_mat = np.empty((0, motif_len * 4))
    names = []
    pvals = []
    log_odds = []
    mot = []
    count = 0
    
    with open(motif_file, 'r') as infile:
        for line in infile:
            if line.startswith('>'):
                # Either this is the first motif read or we have read motif_len
                # positions of a motif
                assert(len(names) == 0 or count == motif_len)
                names.append(motif_pref + '_len' + str(motif_len) + '_' + str(len(names) + 1))
                pvals.append(np.float(line.split()[5].split('P:')[1]))
                log_odds.append(np.float(line.split()[2]))
                count = 0
                mot = []
            else:
                mot.extend([float(s) for s in line.strip().split()])
                count += 1
                if count == motif_len:
                    # Done reading the motif
                    mot_mat = np.concatenate((mot_mat, np.reshape(np.array(mot), (1, len(mot)))), axis = 0)
                    rev_mot_mat = np.concatenate((rev_mot_mat, 
                                                  np.reshape(np.array(mot[::-1]), (1, len(mot)))), axis = 0)
                    
    return (mot_mat, rev_mot_mat, np.array(names), np.array(pvals), np.array(log_odds))


def read_cluster_motifs(homer_dir, motif_len, motif_pref):
    """Read HOMER motifs discovered in a set of clusters.
    Will look at motifs in all subdirectories of homer_dir. In particular,
    for every subdirectory homer_dir/<s>, it will read the motifs in the file
    homer_dir/<s>/homerMotifs.motifs<motif_len>.
    
    Args:
    - homer_dir
    - motif_len
    - motif_pref: prefix to add to motif names
    
    Return value:
    A tuple (mot, rev_mot, names, pvals).
    - mot: A matrix nmot x (motif_len * 4).
    - rev_mot: A matrix of reverse complements of PWMs.
    - names: A numpy array of motif names.
    - pvals: p-values of motif names (numpy array)
    - log_odds: log odds detection threshold (numpy array)
    """
    
    cluster_dirs = [os.path.join(homer_dir, c) for c in os.listdir(homer_dir)]

    mot = np.empty((0, motif_len * 4))
    rev_mot = np.empty((0, motif_len * 4))
    names = np.empty((0, ))
    pvals = np.empty((0, ))
    log_odds = np.empty((0, ))
    
    for c in cluster_dirs:
        motif_file = os.path.join(c, 'homerMotifs.motifs' + str(motif_len))
        if not os.path.isfile(motif_file):
            print >> sys.stderr, motif_file + ' missing. Skipping'
            continue
        out_pref = motif_pref + re.sub('_motifs', '', os.path.basename(c))
        (tmp_mot, tmp_rev_mot, tmp_names, tmp_pvals, tmp_log_odds) = read_homer_motifs(motif_file, motif_len, out_pref)
        mot = np.concatenate((mot, tmp_mot))
        rev_mot = np.concatenate((rev_mot, tmp_rev_mot))
        pvals = np.concatenate((pvals, tmp_pvals))
        log_odds = np.concatenate((log_odds, tmp_log_odds))
        names = np.concatenate((names, tmp_names))
    return (mot, rev_mot, names, pvals, log_odds)


def remove_redundant_mot(mot, rev_mot, max_d):
    """Reads a list of PWMs and removes redundant ones based on correlation.
    
    Args:
    - mot
    - rev_mot
    - max_d: Maximum distance for motifs to be considered redundant.
    
    Return value:
    A boolean numpy array is_good, that indicates whether each motif should 
    be kept or not.
    """
    
    nmot = mot.shape[0]
    assert(rev_mot.shape[0] == nmot)
    assert(rev_mot.shape[1] == mot.shape[1])
    
    is_good = np.ones((nmot, ), dtype = np.bool)
    
    for i in range(nmot - 1):
        if not is_good[i]:
            continue
        # Get all the indices that are higher than i and have not been removed already.
        others = np.argwhere(np.logical_and(is_good, np.arange(0, nmot) > i)).flatten()
        d = cdist(np.reshape(mot[i, :], (1, mot.shape[1])), mot[others, :], metric = 'correlation').flatten()
        rev_d = cdist(np.reshape(mot[i, :], (1, mot.shape[1])), rev_mot[others, :], metric = 'correlation').flatten()
        # Get minimum distance so maximum correlation.
        d = np.minimum(d, rev_d)
        # PWMs that are similar to the i-th one and have worse pvalue, then they will
        # get marked as redundant
        bad = others[np.logical_and(d < max_d, pvals[i] < pvals[others])]
        is_good[bad] = False
        if np.any(np.logical_and(d < max_d, pvals[i] > pvals[others])):
            is_good[i] = False
    return is_good


def merge_mot_files(file_list):
    """Merges motifs from multiple npz files.
    
    Each file should contain the following:
    mot, rev_mot, names, pvals, log_odds.
    These are as in the output of read_homer_motifs.
    If file_list contains a single file, then the contents of that 
    file will be returned. Otherwise, the contents of all the files
    in the list will be concatenated. In this case, all files should
    contain motifs of the same lenght.
    
    Return value:
    A tuple (mot, rev_mot, names, pvals, log_odds) as in the output of read_homer_motifs.
    """
    
    for fidx, filename in enumerate(file_list):
        data = np.load(filename)
        m, rev_m = data['mot'], data['rev_mot']
        p, n, lo = data['pvals'], data['names'], data['log_odds']
        data.close()
        
        if fidx == 0:
            mot = m
            rev_mot = rev_m
            names = n
            pvals = p
            log_odds = lo
            mot_len = np.int(mot.shape[1] / 4)
        else:
            assert(m.shape[1] == mot_len * 4)    
            mot = np.concatenate((mot, m))
            rev_mot = np.concatenate((rev_mot, rev_m))
            pvals = np.concatenate((pvals, p))
            log_odds = np.concatenate((log_odds, lo))
            names = np.concatenate((names, n))
    
    nmot = names.size
    assert(mot.shape[0] == nmot)
    assert(rev_mot.shape[0] == nmot)
    assert(pvals.size == nmot)
    assert(log_odds.size == nmot)
    return (mot, rev_mot, names, pvals, log_odds)


def write_homer_motifs(outfile, mot, names, log_odds):
    """Writes PWMs from a "flattened" matrix in HOMER format.
    
    The header lines will be
    >name   name   log_odds
    
    If outfile is a directory, then each motif will be written in a separate 
    file in that directory, named <name>_motif.txt where <name> is the name
    of the motif.
    mot and log_odds are as described in read_homer_motifs.
    """
    
    nmot = names.size
    assert(mot.shape[0] == nmot)
    assert(log_odds.size == nmot)
    mot_len = np.int(mot.shape[1] / 4)
    
    if os.path.isdir(outfile):
        for i, name in enumerate(names):
            with open(os.path.join(outfile, name + '_motif.txt'), 'w') as f:
                f.write('>{}\t{}\t{:.6f}\n'.format(name, name, log_odds[i]))
                for m in range(mot_len):
                    start = m * 4
                    end = (m + 1) * 4
                    f.write('\t'.join([str(n) for n in mot[i, start:end]]) + '\n') 
    else:
        with open(outfile, 'w') as f:
            for i, name in enumerate(names):
                f.write('>{}\t{}\t{:.6f}\n'.format(name, name, log_odds[i]))
                for m in range(mot_len):
                    start = m * 4
                    end = (m + 1) * 4
                    f.write('\t'.join([str(n) for n in mot[i, start:end]]) + '\n')
                

def read_homer_annotate_output(homer_file):
    """Reads a txt file with the output of HOMER annotatePeaks.
    
    Assumptions:
    - The motif names do not contain spaces.
    - The peak names are just peak indices. 
    
    Return value:
    A tuple (scores, motif_names).
    """
    
    line_idx = []
    with open(homer_file, 'r') as infile:
        for idx, line in enumerate(infile):
            if idx == 0:
                # The motif name should not contain spaces...
                motif_names = [s.split()[0] for s in line.strip().split('\t')[9:]]
            elif line.startswith('PeakID'):
                tmp = [s.split()[0] for s in line.strip().split('\t')[9:]]
                assert(all(m[0] == m[1] for m in zip(motif_names, tmp)))
            else:
                fields = line.strip().split('\t')
                line_idx_tmp = int(fields[0])
                scores_tmp = np.array([float(f) for f in fields[9:]])
                assert(scores_tmp.size == len(motif_names))
                scores_tmp = np.reshape(scores_tmp, (1, scores_tmp.size))
                if len(line_idx) == 0:
                    # First non-header line
                    scores = scores_tmp
                else:
                    scores = np.concatenate((scores, scores_tmp), axis = 0)
                line_idx.append(line_idx_tmp)

    # HOMER rearranges the peaks. The first column of the output is the peak name
    # so assuming that the peak name was just the peak index, this column
    # can be used to get the peaks back in sorted order.
    line_idx = np.array(line_idx)
    sidx = np.argsort(line_idx)
    scores_new = scores[sidx, :]
    region_names = line_idx[sidx]
    
    return (scores_new, motif_names, region_names)


def merge_homer_annotate_output(filenames):
    """Merges the results of multiple runs of HOMER's annotatePeaks on the same BED/peakfile
    
    All input files must have the same number of rows. Motif scores read from different files 
    will be concatenated.
    
    Return value:
    A tuple (scores, motif_names). scores has as many columns as the total number of motifs
    in all the input files.
    """
    
    for fidx, homer_file in enumerate(filenames):
        print >> sys.stderr, 'Reading', homer_file
        scores_tmp, motif_names_tmp, region_names_tmp = read_homer_annotate_output(homer_file)
        if fidx == 0:
            scores = scores_tmp
            motif_names = motif_names_tmp
            region_names = region_names_tmp
        else:
            scores = np.concatenate((scores, scores_tmp), axis = 1)
            motif_names.extend(motif_names_tmp)
            assert(list(region_names) == list(region_names_tmp))
    return (scores, motif_names, region_names)


def hocomoco_to_homer(hoco_file, out_dir):
    """Reads a HOCOMOCO motif file and outputs the motifs in HOMER format.
    
    The input should be in the V_PPM format (plain text format, probability matrices, 
    columns as letters (ACGT)). It will write one file per motif,
    <out_dir>/<motif_name>_motif.txt.
    """
    
    names = []
    matrices = {}
    with open(hoco_file, 'r') as infile:
        for line in infile:
            if len(line.strip()) == 0:
                continue
            if line.startswith('>'):
                names.append(line.strip().split()[1])
                last_name = names[-1]
                matrices[last_name] = []
            else:
                # Create a list of lists for each PWM. This can be easily 
                matrices[last_name].append([float(f) for f in line.strip().split()])
    for nidx, name in enumerate(names):
        with open(os.path.join(out_dir, name + '_motif.txt'), 'w') as outfile:
            mat = np.array(matrices[name])
            # Compute a log-score threshold as 60% of the maximum achieavable 
            # threshold. 
            max_score = np.sum(np.log(np.max(mat, axis = 1)/0.25))
            outfile.write('>{}\t{}\t{:.6f}\n'.format(name, name, max_score * 0.6))
            np.savetxt(outfile, mat, fmt = '%.6f', delimiter = '\t')


def merge_scores(filenames, vertical = True):
    """Merges feature matrices with motif scores.
    
    Args: 
    - filenames: Paths to npz files containing feature matrices.
    - vertical: Concatenate matrices vertically (i.e. add regions).
    Otherwise, it will concatenate horizontally (i.e. add motifs).
    
    Return value: 
    A tuple (scores, motif_names).
    """
    
    for fidx, filename in enumerate(filenames):
        if not os.path.isfile(filename):
            raise IOError('File ' + filename + ' does not exist.')
        data = np.load(filename)
        scores_tmp, motif_names_tmp = data['scores'], data['motif_names']
        assert(len(motif_names_tmp) == scores_tmp.shape[1])
        
        if fidx == 0:
            scores = scores_tmp
            motif_names = motif_names_tmp
        else:
            if vertical:
                assert(scores.shape[1] == scores_tmp.shape[1])
                assert(all(motif_names == motif_names_tmp))
                scores = np.concatenate((scores, scores_tmp), axis = 0)
            else:
                assert(scores.shape[0] == scores_tmp.shape[0])
                motif_names.extend(motif_names_tmp)
                scores = np.concatenate((scores, scores_tmp), axis = 1)
    return (scores, motif_names)


def summarize_scores(scores, region_id, fun = np.mean):
    """Returns a summary of a score matrix, by merging regions with the same id.
    
    Args:
    - scores: A matrix N x M.
    - region_id: A list of length N. Rows of "scores" with the same id will be combined.
    If region_id[i] is None, then the i-th row of scores will be completeley ignored.
    - fun: function to apply to combine rows with the same id (eg. np.mean will average
    the rows).
    
    Return value:
    A tuple (new_scores, names). new_scores is K x M where K is the number of
    unique (and not-None) elements of region_id. names is a list of length K
    with the ids corresponding to each row of new_scores.
    """
    
    assert(len(region_id) == scores.shape[0])
    region_to_idx = {}
    for i, r in enumerate(region_id):
        if not r is None:
            if not r in region_to_idx:
                region_to_idx[r] = []
            region_to_idx[r].append(i)
        
    new_scores = np.zeros((len(region_to_idx), scores.shape[1]))
    new_names = sorted(region_to_idx.keys())
    for i, name in enumerate(new_names):
        idx = region_to_idx[name]
        new_scores[i, :] = fun(scores[idx, :], axis = 0)
        
    return (new_scores, new_names)


def summarize_scores_iter(scores, region_names, region_map, new_scores = None, fun = np.add):
    """Similar to summarize_scores, but can be called iteratively.
    This means that functions that can't be applied one element at a time
    (like mean) won't work properly with this function. 

    Args:
    - scores
    - region_names: A list of names for each row of scores.
    - region_map: A dictionary, mapping names in region_names to broader regions.
    This can be a multi-mapping, so region_map[i] is a list of all the broader
    regions to which i maps.
    - new_scores: If this is not None, then the results will be 
    appended into this dictionary.
    - fun: Unlike summarize scores, this should be a function that can be applied
    element-wise, eg. numpy.add or numpy.maximum.

    Return value:
    A dictionary from region names to their scores.
    """
    
    if new_scores is None:
        new_scores = {}
    nregions = len(region_names)

    assert(scores.shape[0] == nregions)
    for i in range(nregions):
        if str(region_names[i]) in region_map:
            new_names = region_map[str(region_names[i])]
            for n in new_names:
                if n in new_scores:
                    new_scores[n] = fun(scores[i, :], new_scores[n])
                else:
                    new_scores[n] = scores[i, :]
    return new_scores
