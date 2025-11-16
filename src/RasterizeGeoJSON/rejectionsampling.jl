using GeoJSON
using GeoInterface
using Images
using Meshes
using CairoMakie
using MAT

struct Inputdata
    JSONpath::String
    Target_number::Int
end

const PATH = "results/tracked_species.geojson"

const txtPATH = "results/scaling_factor.txt"

const TARGET_NUMBER = 500

const INPUT = Inputdata(PATH, TARGET_NUMBER)

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
    sorted_features = sort!(feature, by = f -> f.properties[:basalArea_genet])
    return length(sorted_features) > 5 ? sorted_features[1:5] : sorted_features
end

# obtain the points of the polygon and get the bounding box 
# feature collection: f -> feature -> geometry -> coordinates -> [1]
# feature : f -> geometry -> coordinates -> [1]
function calculate_coords(f)
        println(typeof(f))
        if isa(f.geometry, GeoJSON.Polygon) == true
            if f.geometry.coordinates[1][1] == f.geometry.coordinates[1][end]
            return f.geometry.coordinates[1]
            else println("not a closed polygon") && return nothing
            end
        elseif isa(f.geometry, GeoJSON.MultiPolygon) == true
            polys = Vector{Tuple{<:Real,<:Real}}()
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

function get_bbx(coords)
    xs = [c[1] for c in coords]
    ys = [c[2] for c in coords]
    min_x, max_x = extrema(xs)
    min_y, max_y = extrema(ys)
    return min_x, max_x, min_y, max_y
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

function normalize_points(points::Vector{Vector{Float64}}, min_x, max_x, min_y, max_y)
    
    normalized_points = Vector{Float64}[]
    scaling_factor = maximum([max_x - min_x, max_y - min_y])
    for p in points
        norm_x = 2 * (p[1] - min_x) / scaling_factor - 1
        norm_y = 2 * (p[2] - min_y) / scaling_factor - 1
        push!(normalized_points, [norm_x, norm_y])
    end
    println("scaling factor is ", scaling_factor/1000, " km")

    return hcat(normalized_points...)' |> collect, scaling_factor/1000
end


function process_feature(f, INPUT)
    coords = calculate_coords(f)
    minx, maxx, miny, maxy = get_bbx(coords)

    cloud = rejection_sampling(minx, maxx, miny, maxy, coords, INPUT.Target_number)
    norm_cloud, scaling = normalize_points(cloud, minx, maxx, miny, maxy)

    trackID = f.properties[:trackID]

    file = matopen("src/Stacker/parameters/$(trackID).mat", "w")
    write(file, "cloudPointXYCoords", norm_cloud)
    close(file)

    return trackID, scaling
end

function batch_process_output!(INPUT,txtpath)
    data = import_data(INPUT.JSONpath)
    scaling_factor = []
    for specie in Species
        features = select_patch(data, specie) |> sort_and_select
        for f in features
            trackID, scaling = process_feature(f, INPUT)
            push!(scaling_factor,(trackID, scaling))
        end
    end

    open(txtpath,"w") do io
    println(io, "TrackID\tScaling_Factor_km")

    for (trackID, scaling) in scaling_factor
        println(io, "$(trackID)\t$(scaling)")
    end

    end
end

Species = ["Seagrass", "Sand", "Macroalgae", "Microfilm", "Reef"]
batch_process_output!(INPUT,txtPATH)