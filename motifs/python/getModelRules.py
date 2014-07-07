import sys
import argparse
import fileinput
import pickle
from motifCvUtils import *

def main():
    desc = '''Extracts rules from a list of models. 
The paths to pkl files with the models are read from stdin.
For each file read, it will select nodes involving features with importance greater
than the prc-th percentile of importance as well as paths involving these nodes.
Rules will then be filtered based on similarity.
'''
    parser = argparse.ArgumentParser(description = desc)
    parser.add_argument('outfile')
    parser.add_argument('--prc', type = float, default = 95,
                        help = 'Cutoff for important rules. Should be in [0, 100] [%(default)s]')
    parser.add_argument('--similarity', type = float, default = 1.0,
                        help = 'Similarity cutoff for removing redundant rules [%(default)s]')
    args = parser.parse_args()
    prc = args.prc
    assert(prc >= 0 and prc <= 100)
    similarity = args.similarity
    assert(similarity > 0)

    rules = {}
    thresh = {}
    
    for fidx, filename in enumerate(fileinput.input([])):
        rf, motif_names_tmp = read_model(filename.strip())
        if fidx == 0:
            motif_names = motif_names_tmp
        else:
            assert(all(motif_names == motif_names_tmp))
        rules_tmp, thresh_tmp = extract_rf_rules(rf, prc)
        for i, r in rules_tmp.iteritems():
            if not i in rules:
                rules[i] = np.empty((0, i), dtype = np.int)
                thresh[i] = np.empty((0, i))
            rules[i] = np.concatenate((rules[i], r))
            thresh[i] = np.concatenate((thresh[i], thresh_tmp[i]))
    
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
