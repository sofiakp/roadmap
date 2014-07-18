import os
import os.path
import numpy as np
import argparse
import fileinput

def get_corr_clusters(filename, corr_cut = 0.6):
    corr_clusters = []
    with open(filename, 'r') as infile:
        for idx, line in enumerate(infile):
            fields = line.strip().split()
            if idx == 0:
                col_names = np.array([s.strip('\"') for s in fields])
            else:
                row_name = fields[0].strip('\"')
                corr_vals = np.array([float(f) for f in fields[1:]])
                corr_clusters.extend([(row_name, c) for c in col_names[corr_vals > corr_cut]])
    return corr_clusters


def reverse_clusters(region1, region2):
    if region1 == 'enhancers':
        return False
    if region2 == 'enhancers':
        return True
    # Both regions are either promoters or dyadic
    return region1 == 'promoters'


def get_corr_clusters_from_files(corr_files, corr_cut = 0.6):
    '''
    Args:
    - corr_files: List of correlation matrices.
    - corr_cut: If float, it will be a cutoff for considering a pair of clusters 
    to be correlated. To use a different cutoff per file, provide an iterable
    with the same length as corr_files.
    
    Return value:
    A list of tuples with correlated cluster names.
    '''
    
    if type(corr_cut) == float:
        corr_cut = [corr_cut for i in range(len(corr_files))]
    else:
        assert(len(corr_cut) == len(corr_files))
        
    corr_clusters = []
    
    for fidx, corr_file in enumerate(corr_files):
        region1 = os.path.basename(corr_file).split('_')[0]
        region2 = os.path.basename(corr_file).split('_')[1]
        new_tuples = get_corr_clusters(corr_file, corr_cut[fidx])
        # Reorder the two types of clusters, so the enhancer related ones always come first
        if reverse_clusters(region1, region2):
            new_tuples = [(t[1], t[0]) for t in new_tuples]
            region1, region2 = region2, region1
        corr_clusters.extend([(os.path.join(region1, t[0]), os.path.join(region2, t[1])) for t in new_tuples])
    corr_clusters = list(set(corr_clusters))
    return corr_clusters


def main():
    desc = '''Gets pairs of correlated clusters from a set of correlation matrices.
    Each input file should be a correlation matrix between two sets of clusters, A and B
    (say enhancer clusters vs promoter clusters). The filename should be 
    something like enhancers_promoters_corr.txt. 
    
    Each file should have a header row with clusters names for set B.
    The first column should contain cluster names for set A. 
    The output will be a list of pairs of clusters prefixed by their type, eg:
    enhancers/cluster_1<tab>promoters/cluster_1
    '''
    parser = argparse.ArgumentParser(description = desc)
    parser.add_argument('outfile')
    parser.add_argument('--corr', '-c', default = '0.6',
                        help = 'Comma separated list of correlation cutoffs')
    args = parser.parse_args()
    
    filenames = []
    cuts = [float(s) for s in args.corr.split(',')]
    for line in fileinput.input([]):
        filenames.append(line.strip())
    if len(cuts) == 1:
        cuts = [cuts[0] for i in range(len(filenames))]

    corr_clusters = get_corr_clusters_from_files(filenames, cuts)
    
    with open(args.outfile, 'w') as outfile:
        outfile.write('\n'.join(['\t'.join(t) for t in corr_clusters]) + '\n')
    
if __name__ == '__main__':
    main()
