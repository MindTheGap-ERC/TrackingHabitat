using CairoMakie
import CairoMakie: Axis as MAxis
using DataFrames
using XLSX
using Statistics
using CSV
# Load the data
df_Abacos = XLSX.readtable("data/Abacos.xlsx","sum") |> DataFrame
df_Joulters =XLSX.readtable("data/Joulters.xlsx","sum") |> DataFrame
const AREA = 60
# Data preparartion
df_Abacos_seagrass_1945 = filter(row -> row.v_class == "Seagrass" && row.v_area > AREA, df_Abacos) |> 
                          row -> log10.(row.v_area)

df_Abacos_seagrass_2019 = filter(row -> !ismissing(row.m_class) &&
                                        !ismissing(row.m_area) &&
                                        row.m_class == "Seagrass" &&
                                        row.m_area > AREA,
                                 df_Abacos) |> 
                          row -> log10.(row.m_area)

df_Joulters_seagrass_1945 = filter(row -> !ismissing(row.v_class) &&
                                        !ismissing(row.v_area) &&
                                        row.v_class == "Seagrass" &&
                                        row.v_area > AREA,
                                 df_Joulters) |> 
                          row -> log10.(row.v_area)

df_Joulters_seagrass_2019 = filter(row -> !ismissing(row.m_class) &&
                                        !ismissing(row.m_area) &&
                                        row.m_class == "Seagrass" &&
                                        row.m_area > AREA,
                                 df_Joulters) |> 
                          row -> log10.(row.m_area)

# Determine unified axis limits
all_data = vcat(
    df_Joulters_seagrass_1945,
    df_Joulters_seagrass_2019,
    df_Abacos_seagrass_1945,
    df_Abacos_seagrass_2019
)
x_min = floor(minimum(all_data))
x_max = ceil(maximum(all_data))
y_max_Abacos = 1200
y_max_Joulters = 100

# Plotting with unified axes
fig = Figure(resolution = (600, 300))
ax = MAxis(fig[1, 1], xlabel = L"Log(Area \ (m^2))", ylabel = "Number of patches", title = "Joulters Cays",
          limits = (x_min, x_max, 0, y_max_Joulters))
#ax2 = MAxis(fig[1, 2], xlabel = L"Log(Area \ (m^2))", ylabel = "Numbers", title = "Joulters Cay 2019",
#           limits = (x_min, x_max, 0, y_max_Joulters))
ax3 = MAxis(fig[1, 2], xlabel = L"Log(Area \ (m^2))", ylabel = "Number of patches", title = "North Abacos",
           limits = (x_min, x_max, 0, y_max_Abacos))
#ax4 = MAxis(fig[2, 2], xlabel = L"Log(Area \ (m^2))", ylabel = "Numbers", title = "Abacos 2019",
#           limits = (x_min, x_max, 0, y_max_Abacos))

# Use same number of bins for all histograms
nbins = 20
hist!(ax, df_Joulters_seagrass_1945, bins = nbins, color = :blue, alpha = 0.5, label = "1945")
hist!(ax, df_Joulters_seagrass_2019, bins = nbins, color = :orange, alpha = 0.5, label = "2019")
hist!(ax3, df_Abacos_seagrass_1945, bins = nbins, color = :blue, alpha = 0.5, label = "1945")
hist!(ax3, df_Abacos_seagrass_2019, bins = nbins, color = :orange, alpha = 0.5, label = "2019")

axislegend(ax)
#axislegend(ax2)
axislegend(ax3)
#axislegend(ax4)

fig
save("fig/seagrass_histograms.png", fig)

# Data Edge preparartion
eg_Abacos_seagrass_1945 = filter(row -> row.v_class == "Seagrass" && row.v_area > 60, df_Abacos) |> row -> row.v_length

eg_Abacos_seagrass_2019 = filter(row -> !ismissing(row.m_class) &&
                                        !ismissing(row.m_area) &&
                                        row.m_class == "Seagrass" &&
                                        row.m_area > 60,
                                 df_Abacos) |> row -> row.m_length

eg_Joulters_seagrass_1945 = filter(row -> !ismissing(row.v_class) &&
                                        !ismissing(row.v_area) &&
                                        row.v_class == "Seagrass" &&
                                        row.v_area > 60,
                                 df_Joulters) |> row -> row.v_length

eg_Joulters_seagrass_2019 = filter(row -> !ismissing(row.m_class) &&
                                        !ismissing(row.m_area) &&
                                        row.m_class == "Seagrass" &&
                                        row.m_area > 60,
                                 df_Joulters) |> row -> row.m_length

# ED calculation
A_ed_2019 = sum(eg_Abacos_seagrass_2019) /  sum(10 .^ df_Abacos_seagrass_2019)
A_ed_1945 = sum(eg_Abacos_seagrass_1945) /  sum(10 .^ df_Abacos_seagrass_1945)
J_ed_2019 = sum(eg_Joulters_seagrass_2019) /  sum(10 .^ df_Joulters_seagrass_2019)
J_ed_1945 = sum(eg_Joulters_seagrass_1945) /  sum(10 .^ df_Joulters_seagrass_1945)

# Statistics
A_med_2019 = 10^median(df_Abacos_seagrass_2019)
A_med_1945 = 10^median(df_Abacos_seagrass_1945)
J_med_2019 = 10^median(df_Joulters_seagrass_2019)
J_med_1945 = 10^median(df_Joulters_seagrass_1945)

A_mpa_2019 = 10^mean(df_Abacos_seagrass_2019)
A_mpa_1945 = 10^mean(df_Abacos_seagrass_1945)
J_mpa_2019 = 10^mean(df_Joulters_seagrass_2019)
J_mpa_1945 = 10^mean(df_Joulters_seagrass_1945)

# Largest_Patch_Index
A_LPI_2019 = (10 .^ maximum(df_Abacos_seagrass_2019) / sum(10 .^ df_Abacos_seagrass_2019)) * 100
A_LPI_1945 = (10 .^ maximum(df_Abacos_seagrass_1945) / sum(10 .^ df_Abacos_seagrass_1945)) * 100
J_LPI_2019 = (10 .^ maximum(df_Joulters_seagrass_2019 ) / sum(10 .^ df_Joulters_seagrass_2019)) * 100
J_LPI_1945 = (10 .^ maximum(df_Joulters_seagrass_1945) / sum(10 .^ df_Joulters_seagrass_1945)) * 100

#calculate each bin, the proportion of numbers of log(A) change
prop_A_change = Float64[]
prop_J_change = Float64[]

bin_edges = [x_min + (i-1) * (x_max - x_min) / nbins for i in 1:(nbins+1)]
bin_mids  = [(bin_edges[i] + bin_edges[i+1]) / 2 for i in 1:nbins]

for i in 1:nbins
    bin_start = bin_edges[i]
    bin_end   = bin_edges[i+1]

       count_A_1945 = sum((df_Abacos_seagrass_1945 .>= bin_start) .& (df_Abacos_seagrass_1945 .< bin_end))
       count_A_2019 = sum((df_Abacos_seagrass_2019 .>= bin_start) .& (df_Abacos_seagrass_2019 .< bin_end))
       count_J_1945 = sum((df_Joulters_seagrass_1945 .>= bin_start) .& (df_Joulters_seagrass_1945 .< bin_end))
       count_J_2019 = sum((df_Joulters_seagrass_2019 .>= bin_start) .& (df_Joulters_seagrass_2019 .< bin_end))
       if count_A_1945 == 0 && count_A_2019 == 0
           push!(prop_A_change, 0.0)
       elseif count_A_1945 == 0
           push!(prop_A_change, count_A_2019 * 100.0)
       else
       push!(prop_A_change, (count_A_2019 .- count_A_1945) ./ count_A_1945 * 100)
       end

       if count_J_1945 == 0 && count_J_2019 == 0
           push!(prop_J_change, 0.0)
       elseif count_J_1945 == 0
           push!(prop_J_change, count_J_2019 * 100.0)
       else
       push!(prop_J_change, (count_J_2019 .- count_J_1945) ./ count_J_1945 * 100)
       end

end
return prop_A_change, prop_J_change
# Plotting the proportion change

fig2 = Figure(resolution = (800, 400))
ax5 = MAxis(fig2[1, 1], xlabel = L"Log(Area \ (m^2))", ylabel = "Proportion Change (%)", title = "Proportion Change in Seagrass Patch Numbers", limits = (1.5,5.5,nothing,nothing))      
barplot!(ax5, bin_mids .- 0.1, prop_A_change, color = :grey, label = "Abacos", width = 0.2)
barplot!(ax5, bin_mids .+ 0.1, prop_J_change, color = :brown, label = "Joulters Cay", width = 0.2)

axislegend(ax5)      
fig2
save("fig/proportion_change.png", fig2)

# Save the proportion change data to an Excel file
CSV.write("./results/prop_change.csv", DataFrame(Bin=1:nbins, Prop_A_Change=prop_A_change, Prop_J_Change=prop_J_change), overwrite=true)

# individual ED calculation
A_ed_2019_vec = eg_Abacos_seagrass_2019 ./  10 .^ df_Abacos_seagrass_2019
A_ed_1945_vec = eg_Abacos_seagrass_1945 ./  10 .^ df_Abacos_seagrass_1945
J_ed_2019_vec = eg_Joulters_seagrass_2019 ./  10 .^ df_Joulters_seagrass_2019
J_ed_1945_vec = eg_Joulters_seagrass_1945 ./  10 .^ df_Joulters_seagrass_1945

median_A_ed_2019 = median(A_ed_2019_vec)
median_A_ed_1945 = median(A_ed_1945_vec)
median_J_ed_2019 = median(J_ed_2019_vec)
median_J_ed_1945 = median(J_ed_1945_vec)

# plotting individual ED
fig3 = Figure(resolution = (600, 300))
ax6 = MAxis(fig3[1, 1], xlabel = L"ED_i", ylabel = "Number of patches", title = "Joulters Cays", limits = (0, 0.8, 0, 170))
#ax7 = MAxis(fig3[1, 2], xlabel = L"ED_i", ylabel = "Number", title = "Joulters Cay 2019", limits = (0, 0.8, 0, 170))
ax8 = MAxis(fig3[1, 2], xlabel = L"ED_i", ylabel = "Number of patches", title = "North Abacos", limits = (0, 0.6, 0, 870))
#ax9 = MAxis(fig3[2, 2], xlabel = L"ED_i", ylabel = "Number", title = "Abacos 2019", limits = (0, 0.6, 0, 870))

       hist!(ax6, J_ed_1945_vec, color = :blue, alpha = 0.5, label = "1945")
       hist!(ax6, J_ed_2019_vec,  color = :orange, alpha = 0.5, label = "2019")
       hist!(ax8, A_ed_1945_vec, color = :blue, alpha = 0.5, label = "1945")
       hist!(ax8, A_ed_2019_vec,  color = :orange, alpha = 0.5, label = "2019")
       axislegend(ax6)
#       axislegend(ax7)
       axislegend(ax8)
#       axislegend(ax9)      
fig3
save("fig/seagrass_ED_histograms.png", fig3)
