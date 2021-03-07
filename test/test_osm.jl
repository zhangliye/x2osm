using EzXML
include("shp.jl")

function add_att(nd, name::String, value)
    link!(nd, AttributeNode(name, string(value)))
    return nothing
end
function create_bound(minlat, minlon, maxlat, maxlon)
    bounds = ElementNode("bounds")
    add_att(bounds, "minlat", minlat)
    add_att(bounds, "minlon", minlon)
    add_att(bounds, "maxlat", maxlat)
    add_att(bounds, "maxlon", maxlon)
    return bounds
end

""" create a node element

`tags` reserved for future use
"""
function add_node!(osm, id::String, lon, lat, tags=Dict{String, String}())
    node = ElementNode("node")
    add_att(node, "id", id)
    add_att(node, "lat", lat)
    add_att(node, "lon", lon)

    add_att(node, "user", "zly")
    add_att(node, "uid", "1")
    add_att(node, "visible", "true")
    add_att(node, "version", "1")
    # add_att(node, "changeset", "")
    # add_att(node, "timestamp", "")

    link!(osm, node)
end

function add_osm!(doc)
    osm = ElementNode("osm")
    add_att(osm, "version", 0.6)
    add_att(osm, "generator", "shp2osm 0.0.1")
    setroot!(doc, osm)
    return osm
end

""" create a way node with ids of node ids in `nodes`, and set the
"""
function add_way!(osm, id, nodes::Vector{String}, tags=Dict{String, String}() )
    way = ElementNode("way")
    add_att(way, "id", string(id))
    add_att(way, "visible", "true")
    add_att(way, "version", "1")
    for v in nodes
        nd = ElementNode("nd")
        add_att(nd, "ref", string(v))
        link!(way, nd)
    end

    for (k,v) in tags
        tag = ElementNode("tag")
        add_att(tag, string(k), string(v))
        link!(way, tag)
    end
    add_tag(way, "highway", "footway")
    add_tag(way, "oneway", "no")

    link!(osm, way)
end

function add_tag(nd, k, v)
    tag = ElementNode("tag")
    add_att(tag, "k", string(k) )
    add_att(tag, "v", string(v) )
    link!(nd, tag)
end


function create_osm()
    doc = XMLDocument()

    osm = add_osm!(doc)

    shp = "/Users/zhangliye/OneDrive/data_research/paper_data/paper2021-umgc-walking/output/map/v2_linked_network_sg_node.shp"
    pts = extract_node(osm, shp)

    # pts = [(1.3029753, 103.7146590)]
    # add_node!(osm, "4459074442", 1.3029753, 103.7146590)

    # push!(pts, (1.3030014, 103.7120292))
    # add_node!(osm, "4459074443", 1.3030014, 103.7120292)

    # push!(pts, (1.3046593, 103.7146716))
    # add_node!(osm, "4602852938", 1.3046593, 103.7146716)

    # add_way!(osm, "1", ["4459074443", "4459074442"])
    # add_way!(osm, "2", ["4459074442", "4602852938"])

    shp = "/Users/zhangliye/OneDrive/data_research/paper_data/paper2021-umgc-walking/output/map/v2_linked_network_sg_link.shp"
    extract_edge(osm, shp)

    #####
    lngs = [p[1] for p in pts]
    lats = [p[2] for p in pts]
    bounds = create_bound(minimum(lats), minimum(lngs), maximum(lats), maximum(lngs))
    link!(osm, bounds)

    # relation = ElementNode("relation")
    # link!(osm, relation)
    file = "/Users/zhangliye/Downloads/small3.osm"
    open(file, "w") do f
        prettyprint(f, doc) 
        println("Saved to $(file)")
    end

    # write("/Users/zhangliye/Downloads/small3.osm", doc)
end


create_osm()
