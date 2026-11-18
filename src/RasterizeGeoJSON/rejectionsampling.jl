using GeoJSON
using MAT
using CSV
using DataFrames
using Statistics
using Random

struct Inputdata
    JSONpath::String
    Target_number::Int
    Rotate_angle::Int64
end

const PATH = "results/tracked_species.geojson"

const csvPATH = "results/scaling_factor.csv"            # original shape (with holes)
const outerCsvPATH = "results/scaling_factor_outer.csv" # holes filled
const bboxCsvPATH = "results/scaling_factor_bbox.csv"   # bounding box filled
const PARAMETERS_DIR = normpath(joinpath(@__DIR__, "..", "Stacker", "parameters"))

const TARGET_NUMBER = 8000
const ANGLE = 115
const SEED = 1945

const INPUT = Inputdata(PATH, TARGET_NUMBER, ANGLE)


const MODE_SUFFIX = Dict(:original => "", :filled => "_out", :bbox => "_bbox")

const Ring = Vector{NTuple{2,Float64}}


function find_repeat_ID(data)
    counts = Dict{Any,Int}()
    for f in data.features
        id = f.properties[:trackID]
        counts[id] = get(counts, id, 0) + 1
    end
    return Set(id for (id, c) in counts if c > 1)
end

import_data(file_path) = GeoJSON.read(file_path)

function select_patch(data, repeated_IDs, species_name::String)
    return filter(f -> f.properties[:trackID] in repeated_IDs &&
                       f.properties[:Species] == species_name &&
                       f.properties[:Year] == 1945,
                  collect(data.features))
end

function sort_and_select(features)
    sorted = sort(features, by = f -> f.properties[:basalArea_genet], rev = true)
    return first(sorted, 5)
end


to_ring(r)::Ring = [(Float64(p[1]), Float64(p[2])) for p in r]

# Vector of polygons; each polygon is a Vector of rings (outer first, then holes).
# With `outer_only = true` the holes are dropped, i.e. filled.
function get_polygons(f; outer_only::Bool = false)
    g = f.geometry
    polys = g isa GeoJSON.Polygon      ? [g.coordinates] :
            g isa GeoJSON.MultiPolygon ? g.coordinates :
            error("Unsupported geometry type: $(typeof(g))")
    return [Ring[to_ring(r) for r in (outer_only ? p[1:1] : p)] for p in polys]
end

function polygons_bbox(polys)
    minx, maxx = extrema(p[1] for P in polys for r in P for p in r)
    miny, maxy = extrema(p[2] for P in polys for r in P for p in r)
    return minx, maxx, miny, maxy
end

#### Even-odd rule over all rings of one polygon: points inside a hole cross the
# boundary an even number of times and are therefore rejected.
function inside_polygon(x, y, rings::Vector{Ring})
    c = false
    for ring in rings
        j = length(ring)
        @inbounds for i in eachindex(ring)
            xi, yi = ring[i]
            xj, yj = ring[j]
            # the condition guarantees yi != yj, so the division is safe
            if ((yi > y) != (yj > y)) && x < (xj - xi) * (y - yi) / (yj - yi) + xi
                c = !c
            end
            j = i
        end
    end
    return c
end

#### Uniform rejection sampling in the joint bounding box; a point is accepted if
# it lies in any of the polygons. Density is thus uniform across all parts.
function sample_polygons(rng, polys, bbox, n)
    minx, maxx, miny, maxy = bbox
    # per-part bounding boxes: cheap pre-check before the full ring test
    part_bbox = [polygons_bbox([P]) for P in polys]
    in_part(x, y, i) = begin
        a, b, c, d = part_bbox[i]
        a <= x <= b && c <= y <= d && inside_polygon(x, y, polys[i])
    end
    out = Matrix{Float64}(undef, n, 2)
    k = 0
    while k < n
        x = minx + rand(rng) * (maxx - minx)
        y = miny + rand(rng) * (maxy - miny)
        if any(i -> in_part(x, y, i), eachindex(polys))
            k += 1
            out[k, 1] = x
            out[k, 2] = y
        end
    end
    return out
end

function sample_bbox(rng, bbox, n)
    minx, maxx, miny, maxy = bbox
    return hcat(minx .+ rand(rng, n) .* (maxx - minx),
                miny .+ rand(rng, n) .* (maxy - miny))
end


# Normalise to [-1, 1] using the polygon bounding box 
function normalize_points(points::Matrix{Float64}, bbox)
    minx, maxx, miny, maxy = bbox
    half = max(maxx - minx, maxy - miny) / 2
    cx = (minx + maxx) / 2
    cy = (miny + maxy) / 2
    normalized = hcat((points[:, 1] .- cx) ./ half, (points[:, 2] .- cy) ./ half)
    return normalized, half / 1000
end

function rotate_points(points::Matrix{Float64}, angle_degrees)
    a = -deg2rad(angle_degrees)
    R = [cos(a) -sin(a);
         sin(a)  cos(a)]
    rotated = points * R'
    rotated .-= mean(rotated, dims = 1)
    return rotated
end


function process_feature(rng, f, INPUT, mode::Symbol)
    polys = get_polygons(f; outer_only = mode != :original)
    bbox = polygons_bbox(polys)

    cloud = mode == :bbox ? sample_bbox(rng, bbox, INPUT.Target_number) :
                            sample_polygons(rng, polys, bbox, INPUT.Target_number)

    norm_cloud, scaling = normalize_points(cloud, bbox)
    rotate_cloud = rotate_points(norm_cloud, INPUT.Rotate_angle)

    output_id = string(f.properties[:trackID]) * MODE_SUFFIX[mode]
    matopen(joinpath(PARAMETERS_DIR, "$(output_id).mat"), "w") do file
        write(file, "cloudPointXYCoords", rotate_cloud)
    end
    return output_id, scaling
end

function batch_process_output!(INPUT, outputs, Species; seed = SEED)
    data = import_data(INPUT.JSONpath)
    repeated_IDs = find_repeat_ID(data)
    selected = [f for s in Species for f in sort_and_select(select_patch(data, repeated_IDs, s))]

    for (mode, path) in outputs
        rng = Xoshiro(seed)
        scaling_factor = Tuple{String,Float64}[]
        for f in selected
            @time "$(f.properties[:trackID]) $mode" push!(scaling_factor, process_feature(rng, f, INPUT, mode))
        end
        CSV.write(path, DataFrame(scaling_factor))
    end
end

Species = ["Seagrass", "Sand", "Macroalgae", "Microfilm", "Reef"]

# Set `REJECTIONSAMPLING_NO_RUN = true` before `include`-ing this file to load
# the functions only (used by test_rejectionsampling.jl).
if !(isdefined(@__MODULE__, :REJECTIONSAMPLING_NO_RUN) && REJECTIONSAMPLING_NO_RUN)
    batch_process_output!(INPUT,
        [:original => csvPATH, :filled => outerCsvPATH, :bbox => bboxCsvPATH],
        Species)
end
