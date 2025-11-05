using ArchGDAL
using Distances
using DataFrames
using CSV
using Plots
using GeoMakie
filepath = "results/tracked_species.geojson"

function import_data(file_path)
    data = ArchGDAL.read(file_path)
    Tabledata = DataFrame(ArchGDAL.getlayer(data, 0))
    geometry = Tabledata[:,1] #for some reason no name attached?
    tag = Tabledata.trackID
    time = Tabledata.Year
    habitat = Tabledata.Species
    return geometry, tag, time, habitat
end 

geometry, tag, time, habitat  = import_data(filepath)

function get_centroids(geometry)
    centroids = []
    for gem in geometry
        centroid = ArchGDAL.centroid(gem)
        x = ArchGDAL.getx(centroid, 0)
        y = ArchGDAL.gety(centroid, 0)
        push!(centroids, [x, y])
    end
    return centroids
end

centroids=get_centroids(geometry)

new_data = DataFrame(
    trackID = tag,
    Year = time,
    Habitat = habitat,
    centroids = centroids
)

data_int = unstack(new_data, :trackID, :Year,  :centroids)
habitat_map = unique(select(new_data, [:trackID, :Habitat]))
data = leftjoin(habitat_map, data_int, on=:trackID)

function calculate_distances(data)
    n = length(unique(data.trackID))
    distances = Union{Float64, Missing}[]
    for i in 1:n
        if ismissing(data[i, "1945.0"]) || ismissing(data[i, "2019.0"])
        push!(distances, missing)
        else
        point1 = data[i, "1945.0"]
        point2 = data[i, "2019.0"]
        dist = euclidean(point1, point2)
        push!(distances, dist)

        end

    end
    return distances
end

distances = calculate_distances(data)

function calculate_directions(data)
    n = length(unique(data.trackID))
    directions = Union{Float64, Missing}[]
    for i in 1:n
        if ismissing(data[i, "1945.0"]) || ismissing(data[i, "2019.0"])
            push!(directions, missing)
        else
        point1 = data[i, "1945.0"]
        point2 = data[i, "2019.0"]
        delta_y = point2[2] - point1[2]
        delta_x = point2[1] - point1[1]
        angle = atan(delta_y, delta_x) * (180 / π) + 180
        push!(directions, angle)
        end
    end
    return directions
end

directions = calculate_directions(data)

# open("results/seagrass_migration_data.txt", "w") do io
#     for (dir, dist) in zip(directions, distances)
#         println(io, "$dir $dist")
#     end
# end

result = DataFrame(Direction = directions, Distance = distances)
data = hcat(data, result)
max_dist = maximum(distances)  

species = unique(data.Habitat)

function extract_species_data(data::DataFrame, species_name::AbstractString)
    result = filter(row -> row.Habitat == species_name, eachrow(data))
    result_df = DataFrame(result)
    return dropmissing(result_df[:, [:Direction, :Distance]])
end

sand_data = extract_species_data(data, "Macroalgae")

open("results/Macroalgae_migration_data.txt", "w") do io
    for (dir, dist) in zip(sand_data.Direction, sand_data.Distance)
        
        println(io, "$dir $dist")
    end
end

fig = GMT.scatter(
    distances, 
    directions, 
    limits = (0,360,0,max_dist), 
    proj = :Polar,
    title = "Sand migration distances and directions (1945-2019)",
    show = false
)


function create_rose_data(directions, distances, nbins=18)
    bin_width = 360 / nbins
    bin_edges = 0:bin_width:360
    bin_centers = bin_edges[1:end-1] .+ bin_width/2
    
    bin_sums = zeros(nbins)
    for i in 1:length(directions)
        bin_idx = min(ceil(Int, directions[i] / bin_width), nbins)
        bin_idx = max(1, bin_idx)
        bin_sums[bin_idx] += distances[i]
    end
     
    return bin_centers, bin_sums
end

θ, r = create_rose_data(sand_data.Direction, sand_data.Distance, 18)
θ_rad = deg2rad.(θ)

θ_rad = vcat(θ_rad, θ_rad[1])
r = vcat(r, r[1])
Plots.plot(
    θ_rad, r,
    proj=:polar,
    seriestype=:path,
    fill=(0, 0.3, :orange),
    linewidth=2,
    linecolor=:orange,
    legend=false,
    size=(600, 600),
    title="Migration  Diagram",
    framestyle=:polar
)

savefig("results/Macroalgae_migration_rose_diagram.png")