using GeoInterface
using ArchGDAL
const AG = ArchGDAL

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