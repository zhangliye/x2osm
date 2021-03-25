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


""" extract `id` as node id; extract `type` as node type
add `osm` segment from SHP file `shp`
"""
function extract_node(osm, shp, id_name="id", type_name="type")
    dataset = ArchGDAL.read( shp )
    layer = ArchGDAL.getlayer(dataset, 0)
    t = AG.layerdefn(layer)
    # fds = Dict{String, AG.GDAL.OGRFieldType}()
    fds = Dict{String, Int}()
    for i in 0 : (AG.nfield(t)-1)
        fd = AG.getfielddefn(t, i)
        # fds[AG.getname(fd)] = AG.gettype(fd)
        fds[AG.getname(fd)] = i
    end

    @assert haskey(fds, id_name) "the shp file should have `id` field, Int"
    @assert haskey(fds, type_name) "the shp file should have `type` field, Int"

    idx_id = fds[id_name]
    idx_type = fds[type_name]
    n = 0 
    pts = Vector{Tuple{Float64, Float64}}()
    for i in 0: (AG.nfeature(layer) - 1)
        AG.getfeature(layer, i) do f
            pt = AG.getgeom(f,0)
            # @show typeof(pt)
            lng, lat = GeoInterface.coordinates(pt)
            push!(pts, (lng, lat))
            # @show lng, lat
            id = AG.getfield(f, idx_id)  #int
            type = AG.getfield(f, idx_type) #int
            # id_source = AG.getfield(f, 2)
            # name = AG.getfield(f, 3)
            if id!=0 
                add_node!(osm, string(id), lng, lat)
            end

            n += 1
            n%10000==0 && println("read points: $n")
        end
    end
    return pts
end
# @show AG.nfeature(layer), n

function extract_edge(osm, shp, from_id_name="from_id", to_id_name="to_id")
    dataset = ArchGDAL.read( shp )
    layer = ArchGDAL.getlayer(dataset, 0)

    # @show AG.nfeature(layer)
    # @show AG.nfield(layer)
    # @show AG.layerdefn(layer)

    # AG.getgeomdefn(AG.layerdefn(layer),0)
    # AG.ngeom(AG.layerdefn(layer))

    t = AG.layerdefn(layer)
    # fds = Dict{String, AG.GDAL.OGRFieldType}()
    fds = Dict{String, Int}()
    for i in 0 : (AG.nfield(t)-1)
        fd = AG.getfielddefn(t, i)
        # fds[AG.getname(fd)] = AG.gettype(fd)
        fds[AG.getname(fd)] = i
    end
    @assert haskey(fds, from_id_name) "the shp file should have $(from_id_name) field, Int"
    @assert haskey(fds, to_id_name) "the shp file should have $(to_id_name) field, Int"

    # typeof(AG.GDAL.OFTInteger)
    n = 0
    idx_from_id = fds[from_id_name]
    idx_to_id = fds[to_id_name]
    for i in 0: (AG.nfeature(layer) - 1)
        AG.getfeature(layer, i) do f
            lk = AG.getgeom(f,0)
            # @show lk 
            # @show GeoInterface.coordinates(lk)

            from_id = AG.getfield(f, idx_from_id)
            to_id = AG.getfield(f, idx_to_id)
            # name = AG.getfield(f, 2)
            # type = AG.getfield(f, 3)
            # bike_lane = AG.getfield(f, 4)

            if from_id!=0 && to_id!=0
                add_way!(osm, string(i+1), [string(from_id), string(to_id)])
            end
            n += 1
            n%10000==0 && println("$n")
        end
    end
    # @show AG.nfeature(layer), n
end

function create_osm(node_shp_file, link_shp_file, out_osm_file)
    doc = XMLDocument()

    osm = add_osm!(doc)
    
    pts = extract_node(osm, node_shp_file)
    extract_edge(osm, link_shp_file)

    #####
    lngs = [p[1] for p in pts]
    lats = [p[2] for p in pts]
    bounds = create_bound(minimum(lats), minimum(lngs), maximum(lats), maximum(lngs))
    link!(osm, bounds)

    # relation = ElementNode("relation")
    # link!(osm, relation)
    
    open(out_osm_file, "w") do f
        prettyprint(f, doc) 
        println("Saved to $(out_osm_file)")
    end

    # write("/Users/zhangliye/Downloads/small3.osm", doc)
end