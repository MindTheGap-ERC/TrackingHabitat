using CairoMakie, GeoMakie
using GeoMakie.GeoJSON
using GeoMakie.GeoInterface
using Proj

source = "+proj=utm +zone=18 +datum=WGS84 +units=m +no_defs"
dest = "+proj=longlat +datum=WGS84"
fig = Figure(size = (4000, 3000),fontsize = 10)

data = GeoJSON.read("results/tracked_species.geojson")
geometries = [f.geometry for f in data.features]
tag = "Reef"
data_tag = filter(f -> f.properties[:Species] == tag, data.features)

# find repeated_IDs
function find_repeat_ID()
    list_trackID = [f.properties[:trackID] for f in data_tag]
    repeated_IDs = String[]
    for ID in list_trackID
        if count(==(ID), list_trackID) > 1
            push!(repeated_IDs, ID)
        end
    end
    return unique(repeated_IDs)
end

repeated_IDs = find_repeat_ID()

n_colors = length(repeated_IDs)
colors = distinguishable_colors(n_colors, [RGB(1,1,1), RGB(0,0,0)], dropseed=true)
color_map = Dict(id => colors[mod1(i, length(colors))] for (i, id) in enumerate(repeated_IDs))


polygons_repeated = filter(f -> f.properties[:trackID] in repeated_IDs, data_tag)
polygons_repeated_1945 = filter(f -> f.properties[:Year] == 1945, polygons_repeated)
polygons_repeated_2019 = filter(f -> f.properties[:Year] == 2019, polygons_repeated)

ax = GeoAxis(
    fig[1,1];
    title = "Tracked Species (1945)",
    source = source,
    dest = dest
    
)

GeoMakie.poly!(
    ax, 
    [f.geometry for f in polygons_repeated_1945];
    color = distinguishable_colors(n_colors, [RGB(1,1,1), RGB(0,0,0)], dropseed=true),    
    strokecolor = :black, 
    strokewidth = 0.5
)

ax2 = GeoAxis(
    fig[1,2];
    title = "Tracked Species (2019)",
    source = source,
    dest = dest
)

GeoMakie.poly!(
    ax2, 
    [f.geometry for f in polygons_repeated_2019];
    color = distinguishable_colors(n_colors, [RGB(1,1,1), RGB(0,0,0)], dropseed=true),    
    strokecolor = :black, 
    strokewidth = 0.5
)


legend_elements = [PolyElement(color=color_map[id]) for id in repeated_IDs]
legend_labels = [string(id) for id in repeated_IDs]

Legend(fig[1, 3], 
       legend_elements,
       legend_labels;
       framevisible = false,
       patchsize = (30, 30),
       labelsize = 20)

fig
save("results/tracked_$(tag)_comparison.png", fig)