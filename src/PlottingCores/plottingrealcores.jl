using CairoMakie

include("plottingcores.jl")

# get core layers from manual measurements
core_collection = ["core_78_3_7", "core_78_3_18", "core_78_3_18", "core_78_10_13", "core_78_3_48","core_2_43"]

core_78_3_7 = [-4.6, -2]

core_78_3_18 = [-2.8, -2.6, -2.5, -2.45, -2.4, -2.3, -2.2, -0.3]

core_78_10_13 = [-2.4,-0.6]

core_78_3_48 = [-1.95,-0.3]

core_2_43 = [-3.5, -2.2, -0.6]

layers = [core_78_3_7, core_78_3_18, core_78_10_13, core_78_3_48, core_2_43]

# get core facies from manual measurements
core_facies_collection = ["f_core_78_3_7", "f_core_78_3_18", "f_core_78_10_13", "f_core_78_3_48", "f_core_2_43"]#

f_core_78_3_7 = [100, 103]

f_core_78_3_18 = [100, 101, 103, 105, 103, 101, 103, 101]

f_core_78_10_13 = [100, 101]

f_core_78_3_48 = [100, 103]

f_core_2_43 = [100, 105, 103]

# facies: combine all cores into a matrix
facies = [f_core_78_3_7, f_core_78_3_18, f_core_78_10_13, f_core_78_3_48, f_core_2_43]#

# define core locations
core_coords = [(1,1), (2,1), (3,1), (4,1), (5,1)] #

figreal = PlottingCores.draw_multiple_cores(layers, facies, core_coords)
save("fig/real_cores.png", figreal)