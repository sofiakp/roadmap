import networkx as nx
import os
import os.path
import numpy as np
import re
import pandas as pd
import pandas.rpy.common as com
import rpy2.robjects.lib.ggplot2 as ggplot2
import rpy2.robjects as ro
from motifCvUtils import *
import numpy.random as rd
from interutils import *

def plot_thresh_distr(motif_names, thresh, out_dir, width = 350):
    """Creates boxplots of the thresholds used with each feature."""

    df = pd.DataFrame({'motif':motif_names, 'thresh':thresh})
    df = df[df['thresh'] > 1]

    df.to_csv(os.path.join(out_dir, 'count_thresh.txt'), sep = '\t', index = False)
    fsize = 10
    r_df = com.convert_to_r_dataframe(df)
    gp = ggplot2.ggplot(r_df) + ggplot2.aes_string(x = 'factor(motif)', y = 'thresh') + \
            ggplot2.geom_boxplot() + ggplot2.scale_y_continuous('Threshold counts', limits = ro.IntVector([0, 70])) + \
            ggplot2.scale_x_discrete('') + ggplot2.theme_bw() + ggplot2.coord_flip() + \
            ggplot2.theme(**{'axis.text.x':ggplot2.element_text(size = fsize),
                             'axis.text.y':ggplot2.element_text(size = fsize, hjust = 1),
                             'strip.text.x':ggplot2.element_text(size = fsize + 1)})
    for ext in ['.pdf', '.png']:
        ro.r.ggsave(filename = os.path.join(out_dir, 'count_thresh_bar' + ext),
                    plot = gp, width = width, height = 300, unit = 'mm')

def get_rule_inter_enrich(rules, tf_names, inter):
    """Gets the enrichment of pairwise rules in known interactions.
    
    Args:
    - rules: rules[1] has indices of features participating in rules
    and rules[2] has indices of features in parent-child node pairs.
    See extract_rf_rules.
    - tf_names: Name of TF associated with each of the features.
    - inter: Dictionary of interactions. See interutils.read_inter.
    
    Return value:
    A tuple (types, enrich) see interutils.get_inter_enrich.
    """
    
    pairs = []
    rand_pairs = []
    for i, r in enumerate(rules[2]):
        pairs.append((tf_names[r[0]], tf_names[r[1]]))
    
    #for p in range(100):
    #    perm = rd.permutation(rules[2].shape[0])
    #    for i, r in enumerate(rules[2]):
    #        rand_pairs.append((tf_names[r[0]], tf_names[rules[2][perm[i], 1]]))
    rd.seed(1)
    for i in range(rules[2].shape[0] * 100):
        p1 = rd.randint(rules[1].shape[0])
        p2 = rd.randint(rules[1].shape[0])
        rand_pairs.append((tf_names[rules[1][p1, 0]], tf_names[rules[1][p2, 0]]))
    types, enrich = get_inter_enrich(inter, pairs, rand_pairs)
    return (types, enrich)


def get_rule_graph(rules, tf_names, prom_scores, enh_scores):
    """Creates a graph of pairwise rules. The edges are weighted by the 
    number of times in which such a pairwise rule appears (the same pair
    of motifs might appear multiple times in rules with different thresholds).

    Args:
    - rules: Usual format of extract_rf_rules.
    - tf_names: Names of TFs associated with each of the motifs/features.
    - prom_scores/enh_scores: Binary matrices genes x rules with rule 
    occurrence in promoters and enhancers. Used to add a ratio attribute 
    to nodes and edges:
    (# occurrences in promoters)/(# occurrences in enhancers)

    Return value:
    A networkx graph object G.
    """

    # How many genes have the rule in their promoters?
    prom_with_rule = np.sum(prom_scores > 0, axis = 0)
    # Normalize by average
    prom_with_rule = prom_with_rule / float(np.mean(prom_with_rule))
    
    enh_with_rule = np.sum(enh_scores > 0, axis = 0)
    enh_with_rule = enh_with_rule / float(np.mean(enh_with_rule))
    
    edges = {}
    nodes = {}
    edge_weights = {}
    for i, r in enumerate(rules[2]):
        n1 = tf_names[r[0]]
        n2 = tf_names[r[1]]
        if not (n1, n2) in edges:
            # Number of promoters and enhancers with the rule
            edges[(n1, n2)] = (1, 1)
            edge_weights[(n1,n2)] = 0 # Number of rules involving this pair
        nodes[n1] = (1, 1)
        nodes[n2] = (1, 1)
        edge_weights[(n1,n2)] += 1
        edges[(n1, n2)] = (edges[(n1, n2)][0] + prom_with_rule[i + rules[1].shape[0]],
                           edges[(n1, n2)][1] + enh_with_rule[i + rules[1].shape[0]])
    
    for i, r in enumerate(rules[1]):
        n = tf_names[r[0]]
        if n in nodes:
            nodes[n] = (nodes[n][0] + prom_with_rule[i], nodes[n][1] + enh_with_rule[i])
    
    G = nx.Graph()
    for n, w in nodes.iteritems():
        G.add_node(n, {'id':n, 'ratio':float(w[0])/float(w[1])})
    
    for e, w in edges.iteritems():
        G.add_edge(e[0], e[1], {'id':'-'.join([e[0], e[1]]),
                                'ratio':float(w[0])/float(w[1]), 'weight':edge_weights[e]})
    return G
