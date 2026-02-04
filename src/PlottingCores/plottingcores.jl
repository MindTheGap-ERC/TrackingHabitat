module PlottingCores
using MAT
using CairoMakie

data = matread("src/Stacker/modelResults/FaciesMosaic.mat")
variables = keys(data)
stratadata = data["strata"]
params = data["params"]

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
core_coords = [(25, 50), (50, 50), (75, 50)] # STACKER plots 1, 25, 50, 75, 99 for x.

# define functions for core
function get_facies_color(facies_code)
    facies_colors = Dict(100=>:black, 101=>:yellow, 102=>:blue, 103=>:green, 105=>:red)
    return get(facies_colors, facies_code, :gray)
end

function get_facies_alpha(facies_code)
    facies_alphas = Dict(100=>1.0, 101=>1.0, 102=>1.0, 103=>1.0, 105=>1.0)
    return get(facies_alphas, facies_code, 1.0)
end

function draw_sub_core!(ax, layers::Array{Float64}, facies::Array{Int64}, core_idx, core_coords)
    core_x, core_y = core_coords[core_idx]
    core_layers = layers[core_x, core_y, :]
    core_facies = facies[core_x, core_y, :]
    subcore!(ax, core_layers, core_facies)

end

function draw_sub_core!(ax, layers::Vector{<:Vector}, facies::Vector{<:Vector}, core_idx, core_coords)
    core_layers = layers[core_idx]
    core_facies = facies[core_idx]
    println("calling realcorefunction")
    subcore!(ax, core_layers, core_facies)
end

function subcore!(ax, core_layers, core_facies)
    core_layers_norm = core_layers .- core_layers[1] 
    for idx in eachindex(core_layers_norm)[2:end]
        top = core_layers_norm[idx]
        bottom = core_layers_norm[idx-1]
        
        hspan!(ax, bottom, top; color = get_facies_color(core_facies[idx]), alpha = get_facies_alpha(core_facies[idx]))

    end
end

function draw_multiple_cores(layers, facies, core_coords)
    n_cores = length(core_coords)
    fig = Figure(resolution = (200 * n_cores, 600))
    for i in eachindex(core_coords)
        if i == 1
            ax = Axis(fig[1, i]; xlabel = "", ylabel = "Depth (m)", yreversed = false, xticks = ([], []))
        else
            ax = Axis(fig[1, i]; xlabel = "", ylabel = "", yreversed = false, xticks = ([], []))
        end
        draw_sub_core!(ax, layers, facies, i, core_coords)
        
    end

    facies_codes = [101, 103, 105]
    facies_labels = ["ooidal grainstone", "ooidal packstone", "packstone"]
    legend_elements = [PolyElement(color = get_facies_color(code)) for code in facies_codes]
    Legend(fig[1, length(core_coords) + 1], legend_elements, facies_labels)

    return fig
end

function plot_cross_section(layers, facies)

    n_positions = size(layers)[1]
    
    fig = Figure(resolution = (20 * n_positions, 600))
    
    for pos in 1:n_positions
        pos_layers = layers[pos, 50, :]
        pos_facies = facies[pos, 50, :]
        
        if pos == 1
            ax = Axis(fig[1, pos]; xlabel = "", ylabel = "Depth (m)", yreversed = false, xticks = ([], []))
        else
            ax = Axis(fig[1, pos]; xlabel = "", ylabel = "", yreversed = false, xticks = ([], []))
        end
        
        subcore!(ax, pos_layers, pos_facies)
    end
    
    facies_codes = [101, 103, 105]
    facies_labels = ["ooidal grainstone", "ooidal packstone", "packstone"]
    legend_elements = [PolyElement(color = get_facies_color(code)) for code in facies_codes]
    Legend(fig[1, n_positions + 1], legend_elements, facies_labels)
    
    return fig
end

cross_fig = plot_cross_section(layers, reproj_facies)
save("fig/STACKER_cross_section.png", cross_fig)
# calculate proportions of what faciesin each core

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
    all_proportions = []
    for (core_x, core_y) in core_coords
        core_layers = layers[core_x, core_y, :]
        core_facies = facies[core_x, core_y, :]
        proportions = calculate_proportion_facies(core_layers, core_facies)
        push!(all_proportions, proportions)
    end
    return all_proportions
    write("results/STACKER_cores_proportions.txt", all_proportions)
end


fig = draw_multiple_cores(layers, reproj_facies, core_coords) 
save("fig/STACKER_cores.png", fig)

calculate_all_cores_proportions(layers, reproj_facies, core_coords)
end
