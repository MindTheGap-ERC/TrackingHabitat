module PlottingCores
using MAT
using CairoMakie
using CSV, DataFrames
using Downloads
using ZipFile
#download from zenodo

const OUTPATH = "./data/FaciesMosaic.mat"

const URL = "https://zenodo.org/records/20306840/files/Supplement.zip?download=1"
const TARGET_MAT = "Supplement/S7_STACKER_input_and_result/Results/FaciesMosaic.mat"
const OUTPATH = "src/Stacker/modelResults/FaciesMosaic.mat"
const THRESHOLD = 0.001   # this number means no observational window applied. We also use 0.01, 0.05 and 0.1 for sensitivity test.
function download_and_extract_mat(url::String, target_mat::String, output_path::String)
    temp_zip = "temp_data.zip"
    
    println("Downloading from Zenodo...")
    Downloads.download(url, temp_zip)

is_zip = open(temp_zip, "r") do io
        if eof(io) return false end
        header = read(io, 2) # Read the first 2 bytes
        return header == [0x50, 0x4b] 
    end

    if !is_zip
        content = read(temp_zip, String)
        rm(temp_zip)
        println("First 100 chars of downloaded file: ", first(content, 100))
        error("Downloaded file is NOT a zip. Check your Zenodo URL.")
    end

    zarchive = ZipFile.Reader(temp_zip)
    found = false
    try
        for f in zarchive.files
            if f.name == target_mat
                println("Found $target_mat. Extracting...")
                open(output_path, "w") do io
                    write(io, read(f))
                end
                found = true
                break
            end
        end
    finally
        close(zarchive)
        rm(temp_zip)
    end

    if found
        return matread(output_path)
    else
        error("File $target_mat not found inside the zip.")
    end
end

download_and_extract_mat(URL, TARGET_MAT, OUTPATH)

data = matread("src/Stacker/modelResults/FaciesMosaic.mat")
variables = keys(data)
stratadata = data["strata"]
params = data["params"]
const Y_POS = 40
#extract data
facies = stratadata["facies"]
layers = stratadata["layers"]

# how much facies we have?
facies_code = unique(facies)

# remap facies
new_facies_map = Dict(0.0=>100, 1.0=>101, 2.0=>102, 3.0=>103, 4.0=>103, 5.0=>105)
reproj_facies = map(x -> get(new_facies_map, x, x), facies)
unique(reproj_facies)

# faciesMosaicElementTrajectoryY is 25*10000: rows are each patch, columns are time steps
# faciesMosaicElementYInc is 25*1: rows are each patch, columns are y increment per time step

# core locations
core_coords = [(25, 40), (50, 40), (75, 40)] # STACKER plots 1, 25, 50, 75, 99 for x.

# define functions for core
function get_facies_color(facies_code)
    facies_colors = Dict(100=>:black, 101=>:yellow, 102=>:blue, 103=>:green, 105=>:red)
    return get(facies_colors, facies_code, :gray)
end

function get_facies_alpha(facies_code)
    facies_alphas = Dict(100=>1.0, 101=>1.0, 102=>1.0, 103=>1.0, 105=>1.0)
    return get(facies_alphas, facies_code, 1.0)
end

function draw_sub_core!(ax, layers::Array{Float64}, facies::Array{Int64}, core_idx, core_coords, threshold)
    core_x, core_y = core_coords[core_idx]
    core_layers = layers[core_x, core_y, :]
    core_facies = facies[core_x, core_y, :]
    subcore!(ax, core_layers, core_facies, 0, 1, threshold)

end

function draw_sub_core!(ax, layers::Vector{<:Vector}, facies::Vector{<:Vector}, core_idx, core_coords)
    core_layers = layers[core_idx]
    core_facies = facies[core_idx]
    println("calling realcorefunction")
    subcore!(ax, core_layers, core_facies, 0, 1)
end

function dominant_facies_in_window(core_layers, core_facies, win_bottom, win_top)
    thickness_map = Dict{Int64, Float64}()

    for idx in 2:length(core_layers)
        layer_bot = core_layers[idx - 1]
        layer_top = core_layers[idx]

        overlap_bot = max(layer_bot, win_bottom)
        overlap_top = min(layer_top, win_top)

        if overlap_top > overlap_bot
            facies = core_facies[idx]
            thickness_map[facies] = get(thickness_map, facies, 0.0) + (overlap_top - overlap_bot)
        end
    end

    isempty(thickness_map) && return core_facies[2] 
    return argmax(thickness_map)
end

function subcore!(ax, core_layers, core_facies, x_left, x_right, threshold)
    core_layers_norm = core_layers .- core_layers[1]

    rects  = Vector{Rect2f}(undef, length(core_layers_norm) - 1)
    colors = Vector{Symbol}(undef, length(core_layers_norm) - 1)

    half_w = threshold / 2.0
    total  = core_layers_norm[end]        
    for idx in eachindex(core_layers_norm)[2:end]
        bottom = core_layers_norm[idx - 1]
        top    = core_layers_norm[idx]

        mid        = (bottom + top) / 2.0
        win_bottom = max(0.0,  mid - half_w)
        win_top    = min(total, mid + half_w)

        dominant = dominant_facies_in_window(core_layers_norm, core_facies, win_bottom, win_top)

        rects[idx - 1]  = Rect2f(x_left, bottom, x_right - x_left, top - bottom)
        colors[idx - 1] = get_facies_color(dominant)
    end

    poly!(ax, rects, color = colors)
end

function subcore!(ax, core_layers, core_facies,x_left,x_right)
    core_layers_norm = core_layers .- core_layers[1] 
    rects = Vector{Rect2f}(undef, length(core_layers_norm) - 1)
    colors = Vector{Symbol}(undef, length(core_layers_norm) - 1)    
    for idx in eachindex(core_layers_norm)[2:end]
        top = core_layers_norm[idx]
        bottom = core_layers_norm[idx-1]
        rects[idx-1]  = Rect2f(x_left, bottom, x_right - x_left, top - bottom)
        colors[idx-1] = get_facies_color(core_facies[idx])        
    end
    poly!(ax, rects, color = colors)
end

function draw_multiple_cores(layers, facies, core_coords, threshold)
    n_cores = length(core_coords)
    fig = Figure(resolution = (210 * n_cores, 600))
    for i in eachindex(core_coords)
        if i == 1
            ax = Axis(fig[1, i]; xlabel = "", ylabel = "Depth (m)", yreversed = false, xticks = ([], []))
        else
            ax = Axis(fig[1, i]; xlabel = "", ylabel = "", yreversed = false, xticks = ([], []))
        end
        draw_sub_core!(ax, layers, facies, i, core_coords, threshold)
        
    end

    facies_codes = [101, 103, 105]
    facies_labels = ["ooidal grainstone", "ooidal packstone", "packstone"]
    legend_elements = [PolyElement(color = get_facies_color(code)) for code in facies_codes]
    Legend(fig[1, length(core_coords) + 1], legend_elements, facies_labels)

    return fig
end

function plot_cross_section(layers, facies, y_position, threshold)
    n_positions = size(layers, 1)
    fig = Figure(resolution = (20 * n_positions, 600))
    ax = Axis(fig[1, 1]; xlabel = "Position", ylabel = "Depth (m)", yreversed = false)
    layers_slice = layers[:, y_position, :]  
    facies_slice = facies[:, y_position, :]
    for pos in 1:n_positions
        pos_layers = layers_slice[pos, :]
        pos_facies = facies_slice[pos, :]
        x_left  = pos - 1
        x_right = pos
        subcore!(ax, pos_layers, pos_facies, x_left, x_right, threshold)
    end

    facies_codes  = [101, 102, 103, 105]
    facies_labels = ["ooidal grainstone", "skeletal grainstone", "ooidal packstone", "packstone"]
    legend_elements = [PolyElement(color = get_facies_color(code)) for code in facies_codes]
    Legend(fig[1, 2], legend_elements, facies_labels)

    return fig
end

cross_fig = plot_cross_section(layers, reproj_facies, Y_POS, THRESHOLD)
save("fig/STACKER_cross_section.png", cross_fig)

const TIMESLICES = 1:10:100 |> collect
append!(TIMESLICES, 100)

function plot_timeslice(facies_3d, layers_3d, timeslice_indices)
    n_slices = length(timeslice_indices)
    fig = Figure(resolution = (300 * n_slices, 300))
    
    for (plot_idx, ts_idx) in enumerate(timeslice_indices)
        ax = Axis(fig[1, plot_idx]; xlabel = "X Position", ylabel = "Y Position", title = "Time step $ts_idx")
        facies_slice = facies_3d[:, :, ts_idx]
        heatmap!(ax, facies_slice, colormap = [:white,:yellow, :blue, :green, :grey, :red])
    end
    
    # facies_codes  = [101, 103, 105]
    # facies_labels = ["ooidal grainstone", "ooidal packstone", "packstone"]
    # legend_elements = [PolyElement(color = get_facies_color(code)) for code in facies_codes]
    # Legend(fig[1, n_slices + 1], legend_elements, facies_labels)
    return fig
end


timeslice_fig = plot_timeslice(facies, layers, TIMESLICES)
save("fig/STACKER_timeslice.png", timeslice_fig)

#calculate proportions of what faciesin each core

function calculate_proportion_facies(core_layers, core_facies)
    total_thickness = core_layers[end] - core_layers[1]
    facies_codes = unique(core_facies)
    proportions = Dict{Int64, Float64}()
    for code in facies_codes
        thickness = 0.0
        for idx in eachindex(core_facies)[2:end]
            if core_facies[idx] == code
                top = core_layers[idx]
                bottom = core_layers[idx-1]
                thickness += (top - bottom)
            end
        end
        proportions[code] = thickness / total_thickness
    end
    return proportions
end

function calculate_all_cores_proportions(layers, facies, core_coords)

    all_codes = Int[]
    all_props = Vector{Dict{Int64,Float64}}()
    for (core_x, core_y) in core_coords
        core_layers = layers[core_x, core_y, :]
        core_facies = facies[core_x, core_y, :]
        props = calculate_proportion_facies(core_layers, core_facies)
        push!(all_props, props)

    end


    CSV.write("results/STACKER_cores_proportions.csv", DataFrame(all_props))
end


fig = draw_multiple_cores(layers, reproj_facies, core_coords, THRESHOLD) 
save("fig/STACKER_cores.png", fig)

calculate_all_cores_proportions(layers, reproj_facies, core_coords)
end
