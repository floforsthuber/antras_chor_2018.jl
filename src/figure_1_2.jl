# Script for replicating figure 1

using StatsBase, Statistics, LinearAlgebra, StatsPlots

# -------------- Previous scripts -----------------------------------------------------------------------------------------------------------------------

include("src/data_wrangling.jl")

# -------------- Sectoral aggregation for country level I/O-Table ---------------------------------------------------------------------------------------

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
t_fig_1_2 = DataFrame(year=Int[], country=String[], FD_GO=Float64[], VA_GO=Float64[], U=Float64[], D=Float64[])

for i in years
    append!(t_fig_1_2, country_level_position(df, i))
end

# -------------- Figure 1 --------------------------------------------------------------------------------------------------------------------------------

t_fig_1_2_long = stack(t_fig_1_2, Not([:year, :country]))

function plot_fig1(df::DataFrame, country::Vector, series::Vector) # input vectors in so we can plot multiple countries for comparison
    
    df = subset(df, :country => ByRow(x -> x in country), :variable => ByRow(x -> x in series))

    p = @df df plot(:year, :value, group=(:country, :variable), lw=2, legend=:topleft, 
        ylims=(round(minimum(:value), digits=1)-0.15,round(maximum(:value), digits=1)+0.15))

    return p
end

l = @layout [a ; b] # below each other
p1 = plot_fig1(t_fig_1_2_long, ["world"], ["FD_GO", "VA_GO"]) # add both measures (should be the same in theory) - slight difference (should adjust for "others"?)
p2 = plot_fig1(t_fig_1_2_long, ["world"], ["U", "D"]) # coincide very well
p_fig1 = plot(p1, p2, layout = l, plot_title="GVC Positioning over Time")
savefig(p_fig1, "images/figure1.png") # export image to folder

# -------------- Figure 2 ------------------------------------------------------------------------------------------------------------------------------

# computing percentiles per country-series group
t_fig2 = subset(t_fig_1_2_long, :country => ByRow(x -> x != "world")) # take out world to calculate percentiles
gdf = groupby(t_fig2, [:year, :variable])
begin
    t_fig2 = combine(gdf,
     :value => (x -> percentile(x, 0.25)) => :quantile_25,
     :value => (x -> percentile(x, 0.50)) => :quantile_50,
     :value => (x -> percentile(x, 0.75)) => :quantile_75) 
end
rename!(t_fig2, :variable => :series) # name conflict in formatting
df_fig2_long = stack(t_fig2, Not([:year, :series]))

function plot_fig2(df::DataFrame, series::String) # input vectors in so we can plot multiple countries for comparison
    
    df = subset(df, :series => ByRow(x -> x == series))

    p = @df df plot(:year, :value, group=:variable, lw=2, legend=:topright, 
        ylims=(round(minimum(:value), digits=1)-0.15,round(maximum(:value), digits=1)+0.15))

    return p
end

plot_fig2(df_fig2_long, "U")