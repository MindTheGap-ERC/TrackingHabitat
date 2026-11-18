using Test
using CairoMakie

const REJECTIONSAMPLING_NO_RUN = true
include(joinpath(@__DIR__, "rejectionsampling.jl"))

const N_TEST = 3000        # fewer points than TARGET_NUMBER, enough to see the shape
const MODES = [:original, :filled, :bbox]
const MODE_TITLE = Dict(:original => "original (holes empty)",
                        :filled   => "filled (holes filled)",
                        :bbox     => "bounding box")
const FIG_PATH = joinpath("fig", "rejectionsampling_comparison.png")

# same sampling as process_feature, but returns the clouds instead of writing .mat
function sample_mode(rng, polys_all, mode::Symbol, n)
    polys = mode == :original ? polys_all : [P[1:1] for P in polys_all]
    bbox = polygons_bbox(polys)
    cloud = mode == :bbox ? sample_bbox(rng, bbox, n) : sample_polygons(rng, polys, bbox, n)
    return cloud, polys, bbox
end

in_any(x, y, polys) = any(P -> inside_polygon(x, y, P), polys)

# ------------------------------------------------------------ synthetic case
# Two parts: a 4x4 square with a 2x2 hole in the middle, plus a small 1x1 square.
square(x0, y0, w) = [(x0, y0), (x0 + w, y0), (x0 + w, y0 + w), (x0, y0 + w), (x0, y0)]
const SYNTH = [Ring[square(0.0, 0.0, 4.0), square(1.0, 1.0, 2.0)],
               Ring[square(5.0, 0.0, 1.0)]]

@testset "rejectionsampling" begin
    @testset "inside_polygon (even-odd)" begin
        donut = SYNTH[1]
        @test inside_polygon(0.5, 0.5, donut)       # in the ring
        @test !inside_polygon(2.0, 2.0, donut)      # in the hole
        @test !inside_polygon(4.5, 2.0, donut)      # outside
        @test inside_polygon(2.0, 2.0, donut[1:1])  # hole filled
    end

    @testset "synthetic: points land where they should" begin
        for mode in MODES
            cloud, polys, bbox = sample_mode(Xoshiro(1), SYNTH, mode, N_TEST)
            @test size(cloud) == (N_TEST, 2)
            minx, maxx, miny, maxy = bbox
            @test all(minx .<= cloud[:, 1] .<= maxx) && all(miny .<= cloud[:, 2] .<= maxy)
            if mode != :bbox
                @test all(in_any(cloud[i, 1], cloud[i, 2], polys) for i in 1:N_TEST)
            end
            in_hole = count(i -> 1 < cloud[i, 1] < 3 && 1 < cloud[i, 2] < 3, 1:N_TEST)
            mode == :original ? (@test in_hole == 0) : (@test in_hole > 0)
        end
        # uniform density: area donut = 12, small square = 1 -> ~1/13 in the small one
        cloud, _, _ = sample_mode(Xoshiro(2), SYNTH, :original, 20_000)
        @test isapprox(count(>(5.0), cloud[:, 1]) / 20_000, 1 / 13; atol = 0.01)
    end

    @testset "normalize / rotate" begin
        cloud, _, bbox = sample_mode(Xoshiro(3), SYNTH, :bbox, N_TEST)
        norm, scaling = normalize_points(cloud, bbox)
        @test all(-1 .<= norm .<= 1)
        @test scaling ≈ 6.0 / 2 / 1000
        rot = rotate_points(norm, ANGLE)
        @test all(abs.(mean(rot, dims = 1)) .< 1e-12)
        # rotation preserves pairwise distances
        d(p, i, j) = hypot(p[i, 1] - p[j, 1], p[i, 2] - p[j, 2])
        @test d(rot, 1, 2) ≈ d(norm, 1, 2)
    end

    @testset "reproducible with same seed" begin
        a, _, _ = sample_mode(Xoshiro(SEED), SYNTH, :original, 500)
        b, _, _ = sample_mode(Xoshiro(SEED), SYNTH, :original, 500)
        @test a == b
    end
end

# ------------------------------------------------------------ real data
println("Loading $(INPUT.JSONpath) ...")
data = import_data(INPUT.JSONpath)
repeated_IDs = find_repeat_ID(data)
# largest 1945 patch per species
features = [first(sort_and_select(select_patch(data, repeated_IDs, s))) for s in Species]

@testset "real patches" begin
    for f in features
        polys_all = get_polygons(f)
        for mode in MODES
            cloud, polys, _ = sample_mode(Xoshiro(SEED), polys_all, mode, 500)
            @test size(cloud) == (500, 2)
            mode != :bbox && @test all(in_any(cloud[i, 1], cloud[i, 2], polys) for i in 1:500)
        end
    end
end

# ------------------------------------------------------------ figure
function draw_rings!(ax, polys_all)
    for P in polys_all, (k, r) in enumerate(P)
        lines!(ax, first.(r), last.(r);
               color = k == 1 ? :black : :red, linewidth = k == 1 ? 0.8 : 0.6)
    end
end

function draw_bbox!(ax, bbox)
    minx, maxx, miny, maxy = bbox
    lines!(ax, [minx, maxx, maxx, minx, minx], [miny, miny, maxy, maxy, miny];
           color = :gray50, linestyle = :dash, linewidth = 0.6)
end

cases = [("synthetic (donut + square)", SYNTH);
         [(string(f.properties[:trackID]), get_polygons(f)) for f in features]]

fig = Figure(size = (1200, 360 * length(cases)))
for (row, (label, polys_all)) in enumerate(cases)
    Label(fig[row, 0], label; rotation = π / 2, tellheight = false, fontsize = 14)
    nholes = sum(length(P) - 1 for P in polys_all)
    for (col, mode) in enumerate(MODES)
        cloud, _, bbox = sample_mode(Xoshiro(SEED), polys_all, mode, N_TEST)
        ax = Axis(fig[row, col]; aspect = DataAspect(),
                  title = row == 1 ? MODE_TITLE[mode] : "",
                  subtitle = "$(length(polys_all)) part(s), $nholes hole(s)")
        scatter!(ax, cloud[:, 1], cloud[:, 2]; markersize = 2, color = (:steelblue, 0.7))
        draw_rings!(ax, polys_all)
        draw_bbox!(ax, bbox)
        hidedecorations!(ax)
    end
end
Legend(fig[length(cases) + 1, 1:3],
       [LineElement(color = :black), LineElement(color = :red),
        LineElement(color = :gray50, linestyle = :dash),
        MarkerElement(marker = :circle, color = :steelblue, markersize = 8)],
       ["outer ring", "hole", "bounding box", "cloud point"];
       orientation = :horizontal, framevisible = false)

save(FIG_PATH, fig)
println("Saved comparison figure to $FIG_PATH")
fig
