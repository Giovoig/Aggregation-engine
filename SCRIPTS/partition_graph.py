import networkx as nx
import sys
import nxmetis as mts

def partition(edge_f, partition_no):
    #graph creation
    G = nx.read_edgelist(edge_f)
    opt = mts.MetisOptions(contig=0, ccorder=1, compress=1)
    (edge_cuts, subgraphs) = mts.partition(G, partition_no, options=opt)
    return(edge_cuts, subgraphs)

def find_2d(target, lst_2d):
    pos = 0
    for i, lst in enumerate(lst_2d):
        for j, element in enumerate(lst):
            if int(element) == int(target):
                return(i, j, pos)
            pos = pos+1
    return(None, None, None)

def create_dict(lst):
    pos = 0
    ret_dic = {}
    for i, subg in enumerate(lst):
        for j, element in enumerate(subg):
            ret_dic[element] = (i, j, pos)
            pos = pos+1
    return ret_dic
