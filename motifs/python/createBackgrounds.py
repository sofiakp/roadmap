import sys
import os
import os.path
import numpy as np
from motifCvUtils import *
import argparse
import pickle

def main():
    desc = '''Creates random backgrounds for a given feature matrix.
The feature matrix is read from <scandir>/<infile>. You should have a file
containing a dictionary from filenames to sizes. The background will be 
formed from all files <scandir>/<filename> EXCEPT <infile> (where <filename>
is a key of the dictionary).

If the specified sizefile does not exist, or if the --sizes option is specified,
the sizefile will be created from all files
<scandir>/*_scores.npz.'''

    parser = argparse.ArgumentParser(description = desc)
    parser.add_argument('scandir')
    parser.add_argument('sizefile')
    parser.add_argument('--infile', '-i', default = None)
    parser.add_argument('--outfile', '-o', default = None)
    parser.add_argument('--sizes', default = False, action = 'store_true',
                        help = 'Just create the sizes file')
    parser.add_argument('--seed', type = int, default = 1)
    args = parser.parse_args()

    scan_dir = args.scandir
    size_file = args.sizefile
    get_sizes = args.sizes

    if not os.path.isfile(size_file) or get_sizes:
        bg_files = [os.path.join(scan_dir, f) for f in os.listdir(scan_dir) 
                    if f.endswith('_scores.npz')]
        
        cluster_sizes = {}
        for fidx, filename in enumerate(bg_files):
            data = np.load(filename)
            cluster_sizes[os.path.basename(filename)] = data['scores'].shape[0]
            data.close()

        with open(size_file, 'wb') as f:
            pickle.dump(cluster_sizes, f)
        if get_sizes:
            return

    infile = args.infile
    outfile = args.outfile
    
    assert(os.path.isfile(size_file))
    with open(size_file, 'rb') as f:
        cluster_sizes = pickle.load(f)

    data = np.load(os.path.join(scan_dir, infile))
    motif_names = data['motif_names']
    data.close()

    bg_files = [os.path.join(scan_dir, f) for f in sorted(cluster_sizes.keys()) if f != infile]
    bg_cluster_sizes = [cluster_sizes[os.path.basename(f)] for f in bg_files]
    get_random_bg(cluster_sizes[infile], bg_cluster_sizes, bg_files, 
                  outfile = outfile, motif_names = motif_names, seed = args.seed)


if __name__ == '__main__':
    main()
