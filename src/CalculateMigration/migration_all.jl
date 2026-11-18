using ArchGDAL
using Distances
using DataFrames
using CSV
using Plots
using GeoMakie
using CairoMakie
export get_centroids, import_data
using GMT
filepath = "results/tracked_species.geojson"

const target_species = "Reef"

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
        if ismissing(data[i, "1945"]) || ismissing(data[i, "2019"])
        push!(distances, missing)
        else
        point1 = data[i, "1945"]
        point2 = data[i, "2019"]
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
        if ismissing(data[i, "1945"]) || ismissing(data[i, "2019"])
            push!(directions, missing)
        else
        point1 = data[i, "1945"]
        point2 = data[i, "2019"]
        delta_y = point2[2] - point1[2]
        delta_x = point2[1] - point1[1]
        angle = atan(delta_y, delta_x) * (180 / π) + 180
        push!(directions, angle)
        end
    end
    return directions
end

directions = calculate_directions(data)

result = DataFrame(Direction = directions, Distance = distances)
data = hcat(data, result)
rename!(data, Symbol("1945") => :vintage)
rename!(data, Symbol("2019") => :modern)
max_dist = maximum(distances)  

species = unique(data.Habitat)

function extract_species_data(data::DataFrame, species_name::AbstractString)
    result = filter(row -> row.Habitat == species_name, eachrow(data))
    result_df = DataFrame(result)
    return dropmissing(result_df[:, [:trackID, :vintage, :Direction, :Distance]])
end


extract_data = extract_species_data(data, target_species)


CSV.write("results/$(target_species)_migration_data.csv", DataFrame(trackID=extract_data.trackID, Direction=extract_data.Direction, Distance=extract_data.Distance))
        

function plot_polar(tag, directions, distances)
    f = Figure(resolution = (800, 800))
    ax = PolarAxis(f[1,1]; title = tag)
    CairoMakie.scatter!(ax, directions, distances; markersize = 20, color = :black, alpha = 1)
    return f
end

tag_species = target_species
polar_fig = plot_polar(tag_species, extract_data.Direction, extract_data.Distance)
save("results/$(tag_species)_migration_polar.png", polar_fig)