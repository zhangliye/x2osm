using GraphMLReader
using MetaGraphs
using GraphMLReader
using LightGraphs
using ArchGDAL
const AG = ArchGDAL
const g_multi_graph = "output/v2_compressed_network_sg.graphml"

const data_dir = "/Users/zhangliye/OneDrive/data_research/paper_data/paper2021-umgc-walking"

file_path = joinpath( data_dir, g_multi_graph )



    G = GraphMLReader.loadgraphml( file_path );

    # edge_fields(G)
    # node_fields(G)
    # gmlid2metaid
    # for n in vertices(G)
    #     @show props(G, n) 
    #     break
    # end 

    # for e in edges(G)
    #     @show props(G, e) 
    #     break
    # end 


#########################
## read network shp file 

shp = "/Users/zhangliye/OneDrive/data_research/paper_data/paper2021-umgc-walking/output/map/v2_linked_network_sg_link.shp"



######## read node 
## node `id` - Int
## type `type` - Int

