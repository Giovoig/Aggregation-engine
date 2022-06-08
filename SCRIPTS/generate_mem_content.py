import sys
import snap
import random
import math
import os
import time
import partition_graph as part

if(len(sys.argv) < 5):
    print("Need arguments: file name, data width, feature size, PE number")
    exit()

filename = sys.argv[1]
data_width = int(sys.argv[2])
feat_size = int(sys.argv[3])
mesh_size = math.sqrt(int(sys.argv[4]))
pe_no = int(sys.argv[4])
run_name = str(int(mesh_size)) + "_" + str(int(mesh_size))

if(pe_no == 1):
	coord_bits = 1
else:
	coord_bits = math.ceil(math.log(mesh_size,2))

if(len(sys.argv) > 5 and sys.argv[5] == "-v"):
    verbose = 1
else:
    verbose = 0

if(verbose):
    print(str(mem_size) + " -> memory size\n")
    print(str(mesh_size) + " -> mesh size\n")
    print(str(coord_bits) + " -> coord bits\n")



print("Acquiring graph...")
graph = snap.LoadEdgeList(snap.TUNGraph, filename, 0, 1)
print("Graph acquired.")
print("Partitioning graph...")
(cut_no, subgraphs) = part.partition(filename, pe_no)
print("Graph partitioning done")

mem_size = math.ceil(graph.GetNodes()/pe_no)

max_size = 0
for i in range(len(subgraphs)):
	if(max_size < len(subgraphs[i])):
		max_size = len(subgraphs[i])

print("Max subgraph size is " + str(max_size))
addr_bits = math.ceil(math.log(max_size,2))

graph_dict = part.create_dict(subgraphs)
#print(graph_dict)

global_neigh = []
node_Ids = []

feat_file = open("features.txt", "w")
addr_file = open("addresses.txt", "w")

index = 0
x_coord = 0
y_coord = 0

#os.system("rm ./dmem_content/*.txt")
#file = open("./dmem_content/PE[0][0].txt")


id_list = []
addr_list = []
feature_list = []

feat_file.write("*0,0\n")
for NI in graph.Nodes():
    #generate random feature vector:
    feature_vector = "";
    for i in range(feat_size*data_width):
        temp = str(random.randint(0,1))
        feature_vector += temp
    feat_file.write(str(hex(int(feature_vector,2)))[2:] + "\n")
    feature_list.append(feature_vector)

    #generate address for the frature vector:
    if(index == mem_size):
        #print("x = " + str(x_coord))
        #print("y = " + str(y_coord))
        index = 0
        if(x_coord < mesh_size-1):
            x_coord = x_coord + 1
            feat_file.write("*" + str(x_coord) + "," + str(y_coord) + "\n")
        elif(y_coord < mesh_size-1):
            x_coord = 0
            y_coord = y_coord + 1
            feat_file.write("*" + str(x_coord) + "," + str(y_coord) + "\n")
        else:
            print("Not enough memory")
            addr_file.close()
            feat_file.close()
            exit()

    x_string = str(format(x_coord, "b").zfill(coord_bits))
    y_string = str(format(y_coord, "b").zfill(coord_bits))
    address = x_string + y_string + str(format(index,"b").zfill(addr_bits))
    addr_file.write(address + "\n")

    id_list.append(NI.GetId())
    addr_list.append(address)

    index = index + 1



os.system("rm " + run_name + "/imem_content/*.txt")
os.system("rm "  + run_name + "/dmem_content/*.txt")
os.system("rm " + run_name + "/imem_partitioned/*.txt")
os.system("rm " + run_name + "/dmem_partitioned/*.txt")
os.system("rm " + run_name + "/reference_partitioned.txt")
os.system("rm " + run_name + "/reference_values.txt")
inst_file = open(run_name + "/imem_content/PE_0_0.txt", "w")
f_file = open(run_name + "/dmem_content/PE_0_0.txt", "w")
ref_file = open(run_name + "/reference_values.txt", "w")
part_file = open(run_name + "/dmem_partitioned/PE_0_0.txt", "w")
ins_part_file = open(run_name + "/imem_partitioned/PE_0_0.txt", "w")
ref_part_file = open(run_name + "/reference_partitioned.txt", "w")
x_coord = 0
y_coord = 0
index = 0
aggr_idx = 0
sub_order = []
reference_list = []
node_counter = 0
start_time = time.time()
unpart_edge_cut = 0

for NI in graph.Nodes():
#for NI in nodes:
    #generate address for the feature vector and open right instruction file:
    if(index == mem_size):
        index = 0
        if(x_coord < mesh_size-1):
            x_coord = x_coord + 1
            #print("x = " + str(x_coord))

            inst_file.close()
            f_file.close()
            inst_file = open(run_name + "/imem_content/PE_" + str(x_coord) + "_" + str(y_coord) + ".txt", "w")
            f_file = open(run_name + "/dmem_content/PE_" + str(x_coord) + "_" + str(y_coord) + ".txt", "w")
        elif(y_coord < mesh_size-1):
            x_coord = 0
            y_coord = y_coord + 1
            #print("y = " + str(y_coord))
            #stop instruction
            inst_file.write("111")
            for l in range(addr_bits + 2*coord_bits):
                inst_file.write("0")
            inst_file.write(" //STOP\n")
            inst_file.close()
            f_file.close()
            inst_file = open(run_name + "/imem_content/PE_" + str(x_coord) + "_" + str(y_coord) + ".txt", "w")
            f_file = open(run_name + "/dmem_content/PE_" + str(x_coord) + "_" + str(y_coord) + ".txt", "w")


    x_string = str(format(x_coord, "b").zfill(coord_bits))
    y_string = str(format(y_coord, "b").zfill(coord_bits))
    address = x_string + y_string + str(format(index,"b").zfill(addr_bits))

    #output the features to the file
    feat_index = int(index + mem_size*x_coord + mesh_size*mem_size*y_coord)
    f_file.write(str(feature_list[feat_index]) + "\n")

    #load node to PE
    inst_file.write("010" + address + " //load node\n")

    #write node into correct partitioned files:
    part_file.close()
    ins_part_file.close()
    (sub_no, el_no, position) = graph_dict[str(NI.GetId())]
    part_x = int(sub_no % mesh_size)
    part_y = math.floor(sub_no/mesh_size)

    sub_order.append(position) #order the nodes are loaded to the PEs (needed to generate reference values)

    #DEBUG
    #print(str(NI.GetId()) + " -> pos: " + str(position))
    #print("pos = " + str(position))
    #print(sub_order)
    #print("sub: " + str(sub_no) + "\tn: " + str(el_no))
    #print("x: " + str(part_x) + "\ty: " + str(part_y))

    part_file = open(run_name + "/dmem_partitioned/PE_" + str(part_x) + "_" + str(part_y) + ".txt", "a")
    ins_part_file = open(run_name + "/imem_partitioned/PE_" + str(part_x) + "_" + str(part_y) + ".txt", "a")
    part_file.write(str(feature_list[feat_index] + "\n"))
    x_string = str(format(part_x, "b").zfill(coord_bits))
    y_string = str(format(part_y, "b").zfill(coord_bits))
    addr_part_base = x_string + y_string + str(format(el_no,"b").zfill(addr_bits))
    ins_part_file.write("010" + addr_part_base + " //load node\n")

    index = index + 1

    #create a list with each feature as elements
    base_node = []
    for i in range(0, feat_size*data_width, data_width):
        base_node.append(int(feature_list[feat_index][i:i+data_width],2))

    #generate reference values
    if(verbose):
        print("Now aggregating: ")
        print(str(feature_list[aggr_idx]) + " ")
        print(str(base_node) + "\n")

    #accumulate with 0
    inst_file.write("100")
    for l in range(addr_bits + 2*coord_bits):
        inst_file.write("0")
    inst_file.write(" //accumulate 0\n")

    ins_part_file.write("100")
    for l in range(addr_bits + 2*coord_bits):
        ins_part_file.write("0")
    ins_part_file.write(" //accumulate 0\n")


    aggregated = base_node
    for Id in NI.GetOutEdges():
        id_index = id_list.index(Id) #for unpartitioned

        (sub_no, el_no, neigh_pos) = graph_dict[str(Id)]
        part_x = int(sub_no % mesh_size)
        part_y = math.floor(sub_no/mesh_size)
        x_string_part = str(format(part_x, "b").zfill(coord_bits))
        y_string_part = str(format(part_y, "b").zfill(coord_bits))
        addr_part = x_string_part + y_string_part + str(format(el_no,"b").zfill(addr_bits))

        ins_part_file.write("010" + addr_part + " //load node (neighbour)\n")

        neigh_address = addr_list[id_index]
        inst_file.write("010" + neigh_address + " //load node (neighbour)\n") #load neighbour to PE

        #create the neighbour list with each feature as elements
        neigh_node = []
        for i in range(0, feat_size*data_width, data_width):
            neigh_node.append(int(feature_list[id_index][i:i+data_width],2))

        if(verbose):
            print(str(feature_list[id_index]) + " ")
            print(str(neigh_node) + "\n")

        #accumulate internal
        inst_file.write("110")
        for l in range(addr_bits + 2*coord_bits):
            inst_file.write("0")
        inst_file.write(" //accumulate internal\n")

        ins_part_file.write("110")
        for l in range(addr_bits + 2*coord_bits):
            ins_part_file.write("0")
        ins_part_file.write(" //accumulate internal\n")

        #update reference values
        #print("aggregating f.v.:" + str(aggregated) + " + " + str(int(feature_list[id_index],2)) + " = ")
        for i in range(feat_size):
            aggregated[i] = aggregated[i] + neigh_node[i]

        #DEBUG
        #if(NI.GetId() == 0):
        #    st = ""
        #    print(Id)
        #    print(neigh_node)
        #    for i in range(feat_size):
        #        st = str(bin(aggregated[i]))[2:]
        #        print(hex(aggregated[i]))
        #        if len(st) < data_width:
        #            st = st + st.zfill(data_width)
        #        else:
        #            st = st + st[-data_width:]
            #print(Id)
            #print(hex(int(st,2)))

        #print(str(feature_list[id_index]) + "\n")

    #print aggregation results to reference file
    node_counter = node_counter + 1
    if(node_counter%500 == 0):
        end_time = time.time()
        elapsed = end_time-start_time
        start_time = time.time()
        print("[" + str(int(mesh_size)) + "x" + str(int(mesh_size)) + "]: " + str(node_counter) + " nodes processed... (last 500 nodes in " + str(int(elapsed)) + " s)")

    ref_string = ""
    result_string = ""
    for i in range(feat_size):
        result_string = str(bin(aggregated[i]))[2:]
        if len(result_string) < data_width:
            ref_string = ref_string + result_string.zfill(data_width)
        else:
            ref_string = ref_string + result_string[-data_width:]

    ref_file.write(ref_string + "\n")
    reference_list.append(ref_string)

    if(verbose):
        print("Result: " + ref_string + " ")

    inst_file.write("001" + address + " //store result\n") #store
    ins_part_file.write("001" + addr_part_base + " //store result\n") #store


    aggr_idx = aggr_idx + 1

#for i in sub_order:
#    ref_part_file.write(reference_list[i] + "\n")


sorted_zipped = sorted(zip(sub_order, reference_list)) #reorder ref.values
for tup in sorted_zipped:
    ref_part_file.write(tup[1] + "\n") #write to ref_part file only the ref. value


inst_file.close()
for x in range(int(mesh_size)):
    for y in range(int(mesh_size)):
        inst_file = open(run_name + "/imem_content/PE_" + str(x) + "_" + str(y) + ".txt", "a")
        ins_part_file = open(run_name + "/imem_partitioned/PE_" + str(x) + "_" + str(y) + ".txt", "a")
        #stop instruction
        inst_file.write("111")
        ins_part_file.write("111")
        for l in range(addr_bits + 2*coord_bits):
            inst_file.write("0")
            ins_part_file.write("0")
        inst_file.write(" //STOP\n")
        ins_part_file.write(" //STOP\n")

max_lines = 0
for x in range(int(mesh_size)):
    for y in range(int(mesh_size)):
        inst_file.close()
        ins_part_file.close()
        num_lines_normal = sum(1 for line in open(run_name + "/imem_content/PE_" + str(x) + "_" + str(y) + ".txt"))
        num_lines_part = sum(1 for line in open(run_name + "/imem_partitioned/PE_" + str(x) + "_" + str(y) + ".txt"))
        if(num_lines_normal > max_lines):
            max_lines = num_lines_normal
        if(num_lines_part > max_lines):
            max_lines = num_lines_part

edges = 0
unpart_edge_cut = 0
for EI in graph.Edges():
    N1 = EI.GetSrcNId()
    N2 = EI.GetDstNId()
    edges = edges+1
    if(math.floor(N1/mem_size) != math.floor(N2/mem_size)):
        unpart_edge_cut = unpart_edge_cut + 1

print("DONE: " + str(len(id_list)) + " nodes")
dim_file=open(run_name + "/dimensions.txt", "w")
dim_file.write("Total edge-cut for the UNPARTITIONED graph is\t" + str(unpart_edge_cut) + "\n")
dim_file.write("Total edge-cut for the PARTITIONED graph is\t" + str(cut_no) + "\n")
dim_file.write(str(len(id_list)) + " nodes\n")
dim_file.write(str(edges) + " edges\n")
dim_file.write("Instruction memory height must be at least " + str(max_lines) + "\n")
dim_file.write("DMEM must be " + str(max_size) + "\n")
for i in range(len(subgraphs)):
	dim_file.write("Subgraph " + str(i) + " has size " + str(len(subgraphs[i])) + "\n")
print("Instruction memory height must be at least " + str(max_lines))

#DEBUG
#print(subgraphs)
#print(sub_order)
#print(sorted(zip(sub_order, list(range(17)))))
#print(sorted(zip(sub_order, reference_list)))
#(n, elno, test_pos) = part.find_2d(944,subgraphs)
#print("n = " + str(n) + "    el# = " + str(elno))


dim_file.close()
ins_part_file.close()
ref_part_file.close()
part_file.close()
ref_file.close()
inst_file.close()
addr_file.close()
feat_file.close()
