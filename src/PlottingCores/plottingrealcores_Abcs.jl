using CairoMakie

include("plottingcores.jl")

# get core layers from manual measurements
core_collection = ["TW", "CR"]

TW = [-10.5,-10,-9,-5]

CR = [-6, -3, -2.2, 1.0]

layers = [TW, CR]

# get core facies from manual measurements
core_facies_collection = ["TW", "CR"]

f_TW = [100, 103, 101, 103]

f_CR = [100, 101, 103, 101]



# facies: combine all cores into a matrix
facies = [f_TW, f_CR]

# define core locations
core_coords = [(1,1), (2,1)] #

figrealAb = PlottingCores.draw_multiple_cores(layers, facies, core_coords)
save("fig/real_cores_Abacos.png", figrealAb)