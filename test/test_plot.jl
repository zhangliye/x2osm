using OpenStreetMapX
out_osm_file = "/Users/zhangliye/Downloads/small3.osm"
m = OpenStreetMapX.get_map_data( out_osm_file );
import Random
Random.seed!(0);
pointA = point_to_nodes(generate_point_in_bounds(m), m)
pointB = point_to_nodes(generate_point_in_bounds(m), m)

generate_point_in_bounds(m)

sr = OpenStreetMapX.shortest_route(m, pointA, pointB)[1]

typeof(m)


m.nodes
m.bounds
m.roadways
m.intersections

m.g 
m.v 

m
