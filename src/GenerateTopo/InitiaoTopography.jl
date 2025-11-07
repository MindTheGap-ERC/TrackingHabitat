using Random
using DelimitedFiles

const X_size = 250
const Y_size = 50
const Shoredepth = 0.0
const Slopedepth = -5.0

function generate_topography(x_size, y_size, shoredepth, slopedepth)
    topo = zeros(Float64, y_size, x_size)
    for i in 1:y_size
            topo[i, :] .= (slopedepth - shoredepth) / (y_size - 1) * (i - 1) + shoredepth
    end
    return topo .+ randn(y_size, x_size) .* 0.1
end

topography = generate_topography(X_size, Y_size, Shoredepth, Slopedepth)
writedlm("src/Stacker/parameters/initialtopography.txt", topography)