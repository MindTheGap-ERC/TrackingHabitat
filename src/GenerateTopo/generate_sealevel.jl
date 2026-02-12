using DelimitedFiles

n_points = 10000
amplitude_a = 1.0 
amplitude_b = 0.0         
periods_a = 5             
periods_b = 2   
x = range(0.0, stop=1.0, length=n_points)

y = amplitude_a .* sin.(2pi .* periods_a .* x) .+ amplitude_b .* sin.(2pi .* periods_b .* x)


# save: separate files (no header), and a combined file (x, y5, y2)
writedlm("src/Stacker/parameters/sealevel_sin.txt", y')
