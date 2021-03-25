module x2osm

using GeoInterface
using ArchGDAL
using EzXML
const AG = ArchGDAL

export create_osm

include("shp2osm.jl")

end # module
