using GeoJSON
using GeoInterface
using Images
using Meshes
using CairoMakie
using MAT
# First to read the data
const PATH = "results/tracked_species.geojson"
data = GeoJSON.read(PATH)



# Third filter out repeated trackedIDs in 1945
function find_repeat_ID()
    list_trackID = [f.properties["trackID"] for f in data.features]
    repeated_IDs = String[]
    for ID in list_trackID
        if count(==(ID), list_trackID) > 1
            push!(repeated_IDs, ID)
        end
    end
    return unique(repeated_IDs)
end
repeated_tractedIDs = find_repeat_ID()
species_name = "Seagrass"

repeated_features = filter(f -> f.properties["trackID"] in repeated_tractedIDs, data.features) 
filtered_features = filter(f -> f.properties["Species"] == species_name, repeated_features)
vintage_final_features = filter(f -> f.properties["Year"] == 1945, filtered_features) |> GeoInterface.FeatureCollection
sorted_features = sort!(vintage_final_features.features, by = f -> f.properties["basalArea_genet"])

for f in sorted_features
    println("TrackID: ", f.properties["trackID"], ", Basal Area: ", f.properties["basalArea_genet"])
end


TargetID = "Seagrass_1945_15" # I take this as an exmaple
target_feature = filter(f -> f.properties["trackID"] == TargetID, vintage_final_features.features)

# obtain the points of the polygon and get the bounding box 
# feature collection: f -> feature -> geometry -> coordinates -> [1]
# feature : f -> geometry -> coordinates -> [1]
function calculate_coords(feature, trackedID)
    for f in feature
        geomtype = typeof(f.geometry)
        println(geomtype)
        if f.properties["trackID"] == trackedID && isa(f.geometry, GeoInterface.Polygon) == true
            if f.geometry.coordinates[1][1] == f.geometry.coordinates[1][end]
            return f.geometry.coordinates[1]
            else println("not closed polygon") && break
            end
        elseif f.properties["trackID"] == trackedID && isa(f.geometry, GeoInterface.MultiPolygon) == true
            polys = Vector{Float64}[]
            for polygon in f.geometry.coordinates
                append!(polys, polygon[1])
            end
            if polys[1] != polys[end]
                push!(polys, polys[1]) 
                return polys
            else
                return polys
            end
        else
            println("not going to the loop!!!!!! error!!!!")
        end
    end
end

coords = calculate_coords(target_feature, TargetID)

points = [Meshes.Point(c[1], c[2]) for c in coords]
bbox = Meshes.boundingbox(points)
min_x, min_y = Meshes.coordinates(bbox.min)
max_x, max_y = Meshes.coordinates(bbox.max)

# define point in polygon function
function point_in_polygon(x::Float64, y::Float64, polygon::Vector{Vector{Float64}})
    n = length(polygon)
    inside = false
    
    j = n
    for i in 1:n
        xi, yi = polygon[i][1], polygon[i][2]
        xj, yj = polygon[j][1], polygon[j][2]
        
        if ((yi > y) != (yj > y)) && (x < (xj - xi) * (y - yi) / (yj - yi) + xi)
            inside = !inside
        end
        j = i
    end
    
    return inside
end

# try rejction sampling
target_number = 500
function rejection_sampling(min_x, max_x, min_y, max_y, coords, target_number)
    sampled_points = Vector{Float64}[]
    while length(sampled_points) < target_number
        x_rand = rand() * (max_x - min_x) + min_x
        y_rand = rand() * (max_y - min_y) + min_y
        p = [x_rand, y_rand]
        if point_in_polygon(x_rand, y_rand, coords)
            push!(sampled_points, p)
        end
    end
    return sampled_points
end

PointCloud = rejection_sampling(min_x, max_x, min_y, max_y, coords, target_number)

# normalize the points to[-1,1] range
function normalize_points(points::Vector{Vector{Float64}})
    
    normalized_points = Vector{Float64}[]
    scaling_factor = maximum([max_x - min_x, max_y - min_y])
    for p in points
        norm_x = 2 * (p[1] - min_x) / scaling_factor - 1
        norm_y = 2 * (p[2] - min_y) / scaling_factor - 1
        push!(normalized_points, [norm_x, norm_y])
    end
    println("scaling factor is ", scaling_factor/1000, " km")

    return hcat(normalized_points...)' |> collect
end

PointCloud_normalized = normalize_points(PointCloud)

file = matopen("src/Stacker/parameters/$(TargetID).mat", "w")
write(file, "cloudPointXYCoords", PointCloud_normalized)
close(file)