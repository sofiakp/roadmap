import sys
import argparse
import fileinput
import pickle
from motifCvUtils import *

def main():
    desc = '''Extracts rules from a list of models. 
The paths to pkl files with the models are read from stdin.
For each file read, it will select nodes involving features with importance greater
than a cutoff of importance as well as paths involving these nodes.
Rules will then be filtered based on similarity.
'''
    parser = argparse.ArgumentParser(description = desc)
    parser.add_argument('outfile')
    parser.add_argument('--imp', type = float, default = 0.01,
                        help = 'Cutoff for important rules (see extract_rf_rules). [%(default)s]')
    parser.add_argument('--similarity', type = float, default = 1.0,
                        help = 'Similarity cutoff for removing redundant rules [%(default)s]')
    parser.add_argument('--ntrees', type = int, default = None,
                        help = 'Only use the first NTREES from each RF (None or 0 to use all of them) [%(default)s]')
    parser.add_argument('--noneg', action = 'store_true', default = False,
                        help = 'Set negative rule thresholds to 0.')
    args = parser.parse_args()
    imp_cut = args.imp
    assert(imp_cut >= 0)
    similarity = args.similarity
    assert(similarity > 0)
    ntrees = args.ntrees
    if ntrees == 0:
        ntrees = None

    rules = {}
    thresh = {}
    
    # Get the rules from each file
    for fidx, filename in enumerate(fileinput.input([])):
        rf, motif_names_tmp = read_model(filename.strip())
        if fidx == 0:
            motif_names = motif_names_tmp
        else:
            assert(all(motif_names == motif_names_tmp))
        rules_tmp, thresh_tmp = extract_rf_rules(rf, imp_cut, ntrees = ntrees,
                                                 remove_neg = args.noneg)
        for i, r in rules_tmp.iteritems():
            if not i in rules:
                rules[i] = np.empty((0, i), dtype = np.int)
                thresh[i] = np.empty((0, i))
            rules[i] = np.concatenate((rules[i], r), axis = 0)
            thresh[i] = np.concatenate((thresh[i], thresh_tmp[i]), axis = 0)
    
    print >> sys.stderr, 'Rules before filtering', sum(r.shape[0] for r in rules.values())
    rules, thresh = remove_repetitive_rules(rules, thresh, similarity)
    print >> sys.stderr, 'Rules after filtering', sum(r.shape[0] for r in rules.values())
    
    rule_names = get_rule_names(rules, thresh, motif_names)
    
    with open(args.outfile, 'wb') as f:
        pickle.dump(rules, f)
        pickle.dump(thresh, f)
        pickle.dump(rule_names, f)


if __name__ == '__main__':
    main()
