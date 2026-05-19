using MAT
using CairoMakie
export cal_spt_entropy, plot_entropy_over_time
const PATH = "src/Stacker/modelResults/FaciesMosaic.mat"
const TIMESLICES = 1:5:100 |> collect
append!(TIMESLICES, 100)

function extract_timeslice(PATH::String, timeslice::Int)
    data = matread(PATH)
    stratadata = data["strata"]
    facies = stratadata["facies"] 
    layers = stratadata["layers"]
    return facies[:, :, timeslice], layers[:, :, timeslice]

end

function extract_cross_section(PATH::String, cross_section_idx::Int) 
    data = matread(PATH) 
    stratadata = data["strata"] 
    facies = stratadata["facies"] 
    layers = stratadata["layers"] 
    return facies[:, cross_section_idx, :], layers[:, cross_section_idx, :] 
end   




function cal_spt_entropy(facies_slice)
    x_size, y_size = size(facies_slice)
    x_size = 100
    y_size = 100
    total_count = (x_size -1) * y_size + x_size * (y_size - 1) 
    count = 0
    for x in 1:x_size-1
        for y in 1:y_size-1
            facies_slice[x, y] != facies_slice[x+1, y] ? count += 1 : nothing

        end
    end

    for x in 1:x_size 
        for y in 1:y_size-1 
            facies_slice[x, y] != facies_slice[x, y+1] ? count += 1 : nothing 
        end 
    end

    return count / total_count

end

function cal_spt_entropy(facies_slice, skip_background::Bool)
    x_size, y_size = size(facies_slice)
    x_size = 100
    y_size = 100
    count = 0
    total_count = 0


    for x in 1:x_size-1
        for y in 1:y_size
            a, b = facies_slice[x, y], facies_slice[x+1, y]
            if skip_background && (a == 0 || b == 0)
                continue  
            end
            total_count += 1
            a != b ? count += 1 : nothing
        end
    end


    for x in 1:x_size
        for y in 1:y_size-1
            a, b = facies_slice[x, y], facies_slice[x, y+1]
            if skip_background && (a == 0 || b == 0)
                continue
            end
            total_count += 1
            a != b ? count += 1 : nothing
        end
    end

    total_count == 0 && return 0.0 
    return count / total_count
end


function plot_entropy_over_time(PATH::String, timeslices::Vector{Int})
    entropies = Float64[]
    for timeslice in timeslices
        facies_slice, _ = extract_timeslice(PATH, timeslice)
        entropy = cal_spt_entropy(facies_slice)
        push!(entropies, entropy)
    end

    fig = Figure()
    ax = CairoMakie.Axis(fig[1, 1], xlabel="Time Slice", ylabel="Spatial Entropy")
    lines!(ax, timeslices, entropies)
    vert_sp_etrp = cal_spt_entropy(extract_cross_section(PATH, 25)[1], true)
    lines!(ax, [timeslices[1], timeslices[end]], [vert_sp_etrp, vert_sp_etrp], color=:red, label="Cross-section Entropy") 
    axislegend(ax)
    
    # Return figure and entropy range
    entropy_min = minimum(entropies)
    entropy_max = maximum(entropies)
    return fig, (entropy_min, entropy_max)
end


fig,ent_range = plot_entropy_over_time(PATH, TIMESLICES)
save("fig/spatial_entropy_over_time.png", fig)