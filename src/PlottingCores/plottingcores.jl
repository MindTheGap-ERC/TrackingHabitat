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

function draw_sub_core!(ax, layers, facies, core_x, core_y)
    core_layers = layers[core_x, core_y, :]
    core_facies = facies[core_x, core_y, :]
    core_layers_norm = core_layers .- core_layers[1] 

    for idx in eachindex(core_layers_norm)[2:end]
        top = core_layers_norm[idx]
        bottom = core_layers_norm[idx-1]
        if core_facies[idx] != 100
            hspan!(ax, bottom, top; color = get_facies_color(core_facies[idx]), alpha = get_facies_alpha(core_facies[idx]))
        end
    end

end

function draw_multiple_cores(layers, facies, core_coords)
    n_cores = length(core_coords)
    fig = Figure(resolution = (200 * n_cores, 600))
    for (i, (core_x, core_y)) in enumerate(core_coords)
        if i == 1
            ax = Axis(fig[1, i]; xlabel = "", ylabel = "Depth (m)", yreversed = false, xticks = ([], []))
        else
            ax = Axis(fig[1, i]; xlabel = "", ylabel = "", yreversed = false, xticks = ([], []))
        end
        draw_sub_core!(ax, layers, facies, core_x, core_y)
        
    end

    facies_codes = [100, 101, 102, 103, 105]
    facies_labels = ["hiatus","grainstone", "skeletal grainstone", "mud-lean packstone", "packstone"]
    legend_elements = [PolyElement(color = get_facies_color(code)) for code in facies_codes]
    Legend(fig[1, length(core_coords) + 1], legend_elements, facies_labels)

    return fig
end

# implement and save
fig = draw_multiple_cores(layers, reproj_facies, core_coords) 
save("fig/STACKER_cores.png", fig)

