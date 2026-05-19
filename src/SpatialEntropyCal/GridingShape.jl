using CairoMakie
using ArchGDAL
using Rasters
using GeoDataFrames

include("SpatialEntropy.jl")

const PATH = "data/vintage.shp"
const PATH2 = "data/modern_individual_Project.shp"
gdf = GeoDataFrames.read(PATH)

 function get_extent(gdf)
    xmin = Inf; xmax = -Inf
    ymin = Inf; ymax = -Inf

    for geom in gdf.geometry
        if geom === nothing || ismissing(geom) || ArchGDAL.isempty(geom)
            continue
        end

        ex = ArchGDAL.envelope(geom)

        if ex === nothing
            continue
        end

        xmin = min(xmin, ex.MinX)
        xmax = max(xmax, ex.MaxX)
        ymin = min(ymin, ex.MinY)
        ymax = max(ymax, ex.MaxY)
    end

    return xmin, xmax, ymin, ymax
end

function rasterize_layer(gdf, nx, ny, xmin, xmax, ymin, ymax)
    classes = unique(gdf.Class_name)
    class_map = Dict(c => Int16(i) for (i, c) in enumerate(classes))
    println(class_map)
    gdf.class_id = Int16[class_map[c] for c in gdf.Class_name]

    dx = X(LinRange(xmin, xmax, nx))
    dy = Y(LinRange(ymax, ymin, ny)) 

    template = Raster(fill(Int16(-1), nx, ny), dims=(dx, dy), missingval=Int16(-1))

    ras = rasterize(last, gdf;
        to=template,
        fill=gdf.class_id,
        missingval=Int16(0)
    )
    return ras, class_map
end


xmin, xmax, ymin, ymax = get_extent(gdf)
ras,class_map = rasterize_layer(gdf, 1400, 2400, xmin, xmax, ymin, ymax)
ras_modern,class_map_modern = rasterize_layer(GeoDataFrames.read(PATH2), 1400, 2400, xmin, xmax, ymin, ymax)

SE_vint = cal_spt_entropy(ras.data, true)
SE_modern = cal_spt_entropy(ras_modern.data, true)


function plot_grid_effect(path, nx::Vector{Int}, ny::Vector{Int}) 
    gdf = GeoDataFrames.read(path)
    fig = Figure() 
    entropies = Float64[]
    for (i, (nx_i, ny_i)) in enumerate(zip(nx, ny)) 
        raster, map = rasterize_layer(gdf, nx_i, ny_i, xmin, xmax, ymin, ymax) 
        entropy = cal_spt_entropy(raster.data, true)
        push!(entropies, entropy)
        println("Grid number: $(nx_i)x$(ny_i), Spatial Entropy: $entropy")
    end
        ax = Axis(fig[1, 1], xlabel="Number of grid cells", ylabel="Spatial Entropy") 
        lines!(ax, nx, entropies)

    return fig 
end 

fig1 = plot_grid_effect(PATH, [1400, 700, 350, 175, 100, 50], [2400, 1200, 600, 300, 175, 90]) 
save("fig/grid_effect.png", fig1)
function visualize_habitat(ras,class_map)
    fig = Figure(size=(1000, 800))
    ax = Axis(fig[1, 1], 
        xlabel = "Longitude / X",
        ylabel = "Latitude / Y",
        aspect = DataAspect()
    )

    habitat_colors = Dict(
        "Hardground" => :lightblue,
        "Island" => :black,
        "Macroalgae" => :gray,
        "Microfilm" => :red,
        "Reef" => :darkblue,
        "Sand" => :yellow,
        "Seagrass" => :green,
        "Slope" => :purple
    )
    
    n_classes = length(class_map)
    colors = Vector{Symbol}(undef, n_classes)
    labels = Vector{String}(undef, n_classes)
    
    for (class_name, class_id) in class_map
        colors[class_id] = get(habitat_colors, class_name, :white)
        labels[class_id] = class_name
    end
    
    cmap = cgrad(colors, n_classes, categorical=true)
    
    plt = heatmap!(ax, ras; 
        colormap = cmap,
        colorrange = (1, n_classes),
        lowclip = :white
    )

    Colorbar(fig[1, 2], plt, 
        label = "Habitat Type",
        ticks = (1:n_classes, labels)
    )

    return fig
end



fig2 = visualize_habitat(ras, class_map)
fig3 = visualize_habitat(ras_modern, class_map_modern)

save("fig/vintage_habitat.png", fig2)
save("fig/modern_habitat.png", fig3)