# Script for replicating figure 2 and 3

using StatsBase, Statistics, LinearAlgebra, StatsPlots, XLSX

# -------------- Previous scripts -----------------------------------------------------------------------------------------------------------------------

include("src/data_wrangling.jl") # formats the raw input data obtained from WIOD

# -------------- Sectoral aggregation for country level I/O-Table ---------------------------------------------------------------------------------------

# the function "country_level_position" uses the output from the function "obtain_matrices"
# it prepares the data to replicate figure 2 and 3 by aggregating from a country-sector level to a country level I/O-Table
# outputs:
# t_country_wide ... yearly statistics of final demand share, value added share and measures of U and D at country level

function country_level_position(df::DataFrame, year::Int64)

    ID, FD, GO, VA, IV, other = obtain_matrices(df, year) # N*S×N*S, N*S×N, N*S×1, N*S×1, N*S×N, N*S×1

    # aggregate to country level
    ID_ctry = [sum(ID[i:i+n_sectors-1, j:j+n_sectors-1]) for i in 1:n_sectors:n_sectors*n_ctrys, j in 1:n_sectors:n_sectors*n_ctrys] # N×N
    FD_ctry = [sum(FD[i:i+n_sectors-1, j]) for i in 1:n_sectors:n_sectors*n_ctrys, j in 1:n_ctrys] # N×N, sum over origin sector
    IV_ctry = [sum(IV[i:i+n_sectors-1, j]) for i in 1:n_sectors:n_sectors*n_ctrys, j in 1:n_ctrys] # N×N, sum over origin sector
    GO_ctry = [sum(GO[i:i+n_sectors-1]) for i in 1:n_sectors:n_sectors*n_ctrys] # N×1, sum over destination countries
    VA_ctry = [sum(VA[i:i+n_sectors-1]) for i in 1:n_sectors:n_sectors*n_ctrys] # N×1
    
    # net inventory correction
    iv_correction = [GO_ctry[i]/(GO_ctry[i]-IV_ctry[i, j]) for i in 1:n_ctrys, j in 1:n_ctrys] # N×N, to match country wise inventory changes

    ID_ctry = ID_ctry .* iv_correction # N×N, element wise multiplication
    FD_ctry = FD_ctry .* iv_correction # N×N

    FD_ctry = [sum(FD_ctry[i, :]) for i in 1:n_ctrys] # N×1, sum over destination countries
    
    # input/output share matrices
    A = [ID_ctry[i, j] / GO_ctry[j] for i in 1:n_ctrys, j in 1:n_ctrys] # N×N, iterate output over destination country
    B = [ID_ctry[i, j] / GO_ctry[i] for i in 1:n_ctrys, j in 1:n_ctrys] # N×N, iterate output over reporting country

    # country level statistics
    FD_GO = FD_ctry ./ GO_ctry # N×1
    VA_GO = VA_ctry ./ GO_ctry # N×1
    U_num = inv(I - A) * GO_ctry # N×1, numerator of equation (5)
    D_num = transpose(GO_ctry) * inv(I - B) # N×1, numerator of equation (7), notice difference in matrix algebra
    
    U = U_num ./ GO_ctry # N×1
    D = transpose(D_num) ./ GO_ctry # N×1, transpose to have column vector

    # weighted average of all countries to create a world GVC position
    FD_GO_world = sum(FD_GO .* GO_ctry) / sum(GO_ctry) 
    VA_GO_world = sum(VA_GO .* GO_ctry) / sum(GO_ctry) 
    U_world = sum(U .* GO_ctry) / sum(GO_ctry) 
    D_world = sum(D .* GO_ctry) / sum(GO_ctry)

    # collect data in a nice dataframe
    summary_stats = hcat(fill(year, size(ctrys)), ctrys, FD_GO, VA_GO, U, D)
    t_country_wide = DataFrame(summary_stats, :auto)
    push!(t_country_wide, [year "world" FD_GO_world VA_GO_world U_world D_world]) # add data for world
    rename!(t_country_wide, [:year, :country, :FD_GO, :VA_GO, :U, :D])
    transform!(t_country_wide, [:FD_GO, :VA_GO, :U, :D] .=> ByRow(x -> round(x, digits=3)) .=> [:FD_GO, :VA_GO, :U, :D]) # rescale U, D for better comparison

    return t_country_wide

end

# gather data for all years in a single data frame
t_fig_2_3 = DataFrame(year=Int[], country=String[], FD_GO=Float64[], VA_GO=Float64[], U=Float64[], D=Float64[])

for i in years
    append!(t_fig_2_3, country_level_position(df, i))
end

XLSX.writetable("clean/t_fig_2_3.xlsx", t_fig_2_3, overwrite=true) # export table to folder as input for plotting figure 2 and 3

# -------------- Figure 2 --------------------------------------------------------------------------------------------------------------------------------

t_fig_2_3 = DataFrame(XLSX.readtable("clean/t_fig_2_3.xlsx", "Sheet1")...) # load directly from file
transform!(t_fig_2_3, :country .=> ByRow(string) .=> :country, renamecols=false) # change type to String
transform!(t_fig_2_3, :year .=> ByRow(Int) .=> :year, renamecols=false) # change type to Int64
transform!(t_fig_2_3, [:FD_GO, :VA_GO, :U, :D] .=> ByRow(Float64) .=> [:FD_GO, :VA_GO, :U, :D], renamecols=false) # change type to Float64

t_fig_2_3_long = stack(t_fig_2_3, Not([:year, :country])) # long format for plotting

function plot_fig2(df::DataFrame, country::Vector, series::Vector) # use vectors as input so we can plot multiple countries for comparison
    
    df = subset(df, :country => ByRow(x -> x in country), :variable => ByRow(x -> x in series))

    p = @df df plot(:year, :value, group=(:country, :variable), lw=2, legend=:topleft, 
        ylims=(round(minimum(:value), digits=1)-0.15,round(maximum(:value), digits=1)+0.15))

    return p
end

l = @layout [a ; b] # 2×1 layout
p1 = plot_fig2(t_fig_2_3_long, ["world"], ["FD_GO", "VA_GO"]) # add both measures (should be the same in theory) - slight difference (should adjust for "others"?)
p2 = plot_fig2(t_fig_2_3_long, ["world"], ["U", "D"]) # coincide very well
title = "Figure 2: GVC Positioning over Time (World Average)"
p_fig2 = plot(p1, p2, layout=l, plot_title=title, plot_titlefontsize=10)
savefig(p_fig2, "images/figure2.png") # export image to folder

# -------------- Figure 3 ------------------------------------------------------------------------------------------------------------------------------

# computing percentiles per country-series group
t_fig3 = subset(t_fig_2_3_long, :country => ByRow(x -> x != "world")) # take out world to calculate percentiles
gdf = groupby(t_fig3, [:year, :variable])
begin
    t_fig3 = combine(gdf,
     :value => (x -> percentile(x, 25)) => :quantile_25,
     :value => (x -> percentile(x, 50)) => :quantile_50,
     :value => (x -> percentile(x, 75)) => :quantile_75) 
end
rename!(t_fig3, :variable => :series) # name conflict in formatting
df_fig3_long = stack(t_fig3, Not([:year, :series]))

function plot_fig3(df::DataFrame, series::String) # input vectors in so we can plot multiple countries for comparison
    
    df = subset(df, :series => ByRow(x -> x == series))

    p = @df df plot(:year, :value, group=:variable, lw=2, legend=:none,
    ylims=(round(minimum(:value)-0.05, digits=1),round(maximum(:value)+0.05, digits=1)), 
    ylabel="$(series) over time")

    return p
end

l = @layout [a b ; c d] # 2×2 layout
p1 = plot_fig3(df_fig3_long, "FD_GO")
p2 = plot_fig3(df_fig3_long, "VA_GO")
p3 = plot_fig3(df_fig3_long, "U")
p4 = plot_fig3(df_fig3_long, "D")
title = "Figure 3: GVC Positioning over Time (25th, 50th, 75th country percentiles)"
p_fig3 = plot(p1, p2, p3, p4, layout=l, plot_title=title, plot_titlefontsize=10)
savefig(p_fig3, "images/figure3.png") # export image to folder
