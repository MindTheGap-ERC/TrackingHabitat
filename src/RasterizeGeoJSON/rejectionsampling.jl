using GeoJSON
using GeoInterface
using Images
using Meshes
using CairoMakie
using MAT
using CSV
using Statistics
using DataFrames    

struct Inputdata
    JSONpath::String
    Target_number::Int
    Rotate_angle::Int64
end

const PATH = "results/tracked_species.geojson"

const csvPATH = "results/scaling_factor.csv"

const TARGET_NUMBER = 8000

const ANGLE = 115

const INPUT = Inputdata(PATH, TARGET_NUMBER,ANGLE)

# filter out repeated trackedIDs in 1945
function find_repeat_ID(data)
    list_trackID = [f.properties[:trackID] for f in data.features]
    repeated_IDs = String[]
    for ID in list_trackID
        if count(==(ID), list_trackID) > 1
            push!(repeated_IDs, ID)
        end
    end
    return unique(repeated_IDs)
end

function import_data(file_path)
    data = GeoJSON.read(file_path)
    return data
end 

function select_patch(data,Species_name::String)
    repeated_trackedIDs = find_repeat_ID(data)
    species_name = Species_name

    vintage_final_features = data.features |>
    x -> filter(f -> f.properties[:trackID] in repeated_trackedIDs, x) |>
    x -> filter(f -> f.properties[:Species] == species_name, x) |>
    x -> filter(f -> f.properties[:Year] == 1945, x) 

    return vintage_final_features
end

function sort_and_select(feature)
    sorted_features = sort!(feature, by = f -> f.properties[:basalArea_genet], rev=true)
    return length(sorted_features) > 5 ? sorted_features[1:5] : sorted_features
end

# obtain the points of the polygon and get the bounding box 
# feature collection: f -> feature -> geometry -> coordinates -> [1]
# feature : f -> geometry -> coordinates -> [1]
function calculate_coords(f)
    coords = Vector{Tuple{Float64, Float64}}()
    
    if isa(f.geometry, GeoJSON.Polygon)
        # Get outer ring (first coordinate array)
        ring = f.geometry.coordinates[1]
        if ring[1] != ring[end]
            println("Warning: Polygon not closed, closing it")
            push!(ring, ring[1])
        end
        return ring
        
    elseif isa(f.geometry, GeoJSON.MultiPolygon)
        for polygon in f.geometry.coordinates

            for ring in polygon 
                append!(coords, ring)
            end
        end
        
        unique!(coords)
        if !isempty(coords) && coords[1] != coords[end]
            push!(coords, coords[1])
        end
        return coords
    else
        error("Unsupported geometry type: $(typeof(f.geometry))")
    end
end

function get_bbx(coords)
    xs = [c[1] for c in coords]
    ys = [c[2] for c in coords]
    min_x, max_x = extrema(xs)
    min_y, max_y = extrema(ys)
    return min_x, max_x, min_y, max_y
end

function get_bbx_from_samples(sampled_points::Vector{Vector{Float64}})
    xs = [p[1] for p in sampled_points]
    ys = [p[2] for p in sampled_points]
    return extrema(xs)..., extrema(ys)...
end

function point_in_polygon(x, y, polygon)
    inside = false
    n = length(polygon)
    j = n

    for i in 1:n
        xi, yi = polygon[i]
        xj, yj = polygon[j]

        if ((yi > y) != (yj > y)) &&
            x < (xj - xi) * (y - yi) / (yj - yi + eps()) + xi
            inside = !inside
        end
        j = i
    end

    return inside
end

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

function rotate_points(points, angle_degrees)
    
    angle_rad = -deg2rad(angle_degrees)
    R = [cos(angle_rad) -sin(angle_rad);
         sin(angle_rad)  cos(angle_rad)]

    rotated = (R * points')' |> collect
    
    # Recenter after rotation to ensure [0,0] center
    mean_x = mean(rotated[:, 1])
    mean_y = mean(rotated[:, 2])
    rotated[:, 1] .-= mean_x
    rotated[:, 2] .-= mean_y
    
    return rotated
end

function normalize_points(points::Vector{Vector{Float64}})
    
    normalized_points = Vector{Float64}[]
    
    xs = [p[1] for p in points]
    ys = [p[2] for p in points]
    min_x, max_x = extrema(xs)
    min_y, max_y = extrema(ys)
    
    width = max_x - min_x
    height = max_y - min_y
    scaling_factor = maximum([width, height])
    
    center_x = (min_x + max_x) / 2
    center_y = (min_y + max_y) / 2
    
    for p in points
        norm_x = (p[1] - center_x) / (scaling_factor / 2)
        norm_y = (p[2] - center_y) / (scaling_factor / 2)
        push!(normalized_points, [norm_x, norm_y])
    end

    return hcat(normalized_points...)' |> collect, scaling_factor/2000
end



function process_feature(f, INPUT)
    coords = calculate_coords(f)
    minx, maxx, miny, maxy = get_bbx(coords)

    cloud = rejection_sampling(minx, maxx, miny, maxy, coords, INPUT.Target_number)
    
    norm_cloud, scaling = normalize_points(cloud)
    
    rotate_cloud = rotate_points(norm_cloud, INPUT.Rotate_angle)
    
    trackID = f.properties[:trackID]

    file = matopen("src/Stacker/parameters/$(trackID).mat", "w")
    write(file, "cloudPointXYCoords", rotate_cloud)
    close(file)

    return trackID, scaling
end

function batch_process_output!(INPUT,path,Species)
    data = import_data(INPUT.JSONpath)
    scaling_factor = []
    for s in Species
        features = select_patch(data, s) |> sort_and_select
        for f in features
            trackID, scaling = process_feature(f, INPUT)
            push!(scaling_factor,(trackID, scaling))
        end
    end

    CSV.write(path, DataFrame(scaling_factor))
end

Species = ["Seagrass", "Sand", "Macroalgae", "Microfilm", "Reef"]
S1 = ["Seagrass"]
batch_process_output!(INPUT,csvPATH,Species)
