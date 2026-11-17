using MAT
using Random

const ROUND_CLOUD_POINT_COUNT = 8000
const ROUND_CLOUD_RADIUS = 1.0
const ROUND_CLOUD_OUTPUT = normpath(joinpath(
    @__DIR__, "..", "Stacker", "parameters", "Roundshape_8000.mat"))


function generate_roundshape_cloudpoint(npoints::Integer=ROUND_CLOUD_POINT_COUNT;
                                        radius::Real=ROUND_CLOUD_RADIUS)
    npoints > 0 || throw(ArgumentError("npoints must be positive"))
    radius > 0 || throw(ArgumentError("radius must be positive"))

    angles = 2π .* rand(npoints)
    radii = radius .* sqrt.(rand(npoints))
    return hcat(radii .* cos.(angles), radii .* sin.(angles))
end

function save_roundshape_cloudpoint(
    output_path::AbstractString=ROUND_CLOUD_OUTPUT;
    npoints::Integer=ROUND_CLOUD_POINT_COUNT,
    radius::Real=ROUND_CLOUD_RADIUS,
)
    cloudPointXYCoords = generate_roundshape_cloudpoint(npoints; radius)
    mkpath(dirname(output_path))
    matopen(output_path, "w") do file
        write(file, "cloudPointXYCoords", cloudPointXYCoords)
    end
    return output_path
end

save_roundshape_cloudpoint()
