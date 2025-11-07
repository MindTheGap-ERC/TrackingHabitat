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


TargetID = "Seagrass_1945_116" # I take this as an exmaple
target_feature = filter(f -> f.properties["trackID"] == TargetID, vintage_final_features.features)

# obtain the points of the polygon and get the bounding box 
# feature collection: f -> feature -> geometry -> coordinates -> [1]
# feature : f -> geometry -> coordinates -> [1]
function calculate_coords(feature, trackedID)
    for f in feature
        geomtype = typeof(f.geometry)
        println(geomtype)
        if f.properties["trackID"] == trackedID && isa(f.geometry, GeoInterface.Polygon) == true
            return f.geometry.coordinates[1]
        elseif f.properties["trackID"] == trackedID && isa(f.geometry, GeoInterface.MultiPolygon) == true
            polys = Vector{Float64}[]
            for polygon in f.geometry.coordinates
                append!(polys, polygon[1])
                
            end
            return polys
        else
            println("error")
        end
    end
end

coords = calculate_coords(target_feature, TargetID)

points = [Meshes.Point(c[1], c[2]) for c in coords]
bbox = Meshes.boundingbox(points)
min_x, min_y = Meshes.coordinates(bbox.min)
max_x, max_y = Meshes.coordinates(bbox.max)
pixel_size = 100.0

#ray casting to tell whether the point is inside the polygon
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

function rasterize_feature(coords::Vector{Vector{Float64}}, pixel_size::Float64, bbox)
    min_x, min_y = Meshes.coordinates(bbox.min)
    max_x, max_y = Meshes.coordinates(bbox.max)
    
    width = ceil(Int, (max_x - min_x) / pixel_size)
    height = ceil(Int, (max_y - min_y) / pixel_size)
    
    matrix = falses(height, width)
    
    for row in 1:height
        for col in 1:width
            x = min_x + (col - 0.5) * pixel_size
            y = max_y - (row - 0.5) * pixel_size
            
            matrix[row, col] = point_in_polygon(x, y, coords)
        end
    end
    
    return matrix, (min_x, min_y, max_x, max_y)
end

# Rasterize
matrix, bboxarray = rasterize_feature(coords, pixel_size, bbox)

#visualize the rasterized matrix
fig0 = Figure(resolution = (800, 600))
ax0 = CairoMakie.Axis(fig0[1, 1])
heatmap!(ax0, matrix)
fig0

# normalize the matrix to -1 and 1
function normalize_matrix(matrix)
    Pointcloud = Vector{Float64}[]
    scaling = maximum(size(matrix))
    for i in 1:size(matrix, 1)
        for j in 1:size(matrix, 2)
            if matrix[i, j] == true
                x_coord_norm = (i ./scaling) * 2 - 1 * size(matrix,1)/scaling
                y_coord_norm = (j ./scaling) * 2 - 1 * size(matrix,2)/scaling
                push!(Pointcloud, [x_coord_norm, y_coord_norm])
            end
        end
    end
    return hcat(Pointcloud...)', scaling * 10 /1000 #return in km
end


Pointcloud, scaling = normalize_matrix(matrix)
file = matopen("src/Stacker/parameters/$(TargetID).mat", "w")
write(file, "cloudPointXYCoords", collect(Pointcloud))
close(file)

fig = Figure(resolution = (800, 600))
ax = CairoMakie.Axis(fig[1, 1])
scatter!(ax, Pointcloud[:, 1], Pointcloud[:, 2], markersize = 1, color = :blue)
fig