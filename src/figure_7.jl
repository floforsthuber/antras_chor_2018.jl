# Script to replicate figure 7

using DataFrames, StatsBase, Statistics, LinearAlgebra, XLSX, StatsPlots

# -------------- Previous scripts -----------------------------------------------------------------------------------------------------------------------

include("src/data_wrangling.jl") # formats the raw input data obtained from WIOD

# -------------- Sectoral aggregation for country level I/O-Table ---------------------------------------------------------------------------------------

# the function "country_level_head_reis_index" uses the output from the function "obtain_matrices"
# it prepares the data to replicate figure 7 by aggregating the I/O table from a country-sector level to a country level I/O-Table
# and calculates the Head-Reis index (trade costs) for intermediate and final goods
# outputs:
# 

function country_level_head_reis_index(df::DataFrame, year::Int64)
    
    # beginning of the function is the same as in "figure_2_3.jl"

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

    # new section of function starts

    # footnote 22 on page 21: substitute 1e-18 for any zero entries otherwise trade costs explode to infinity!
    replace!(x -> x == 0.0 ? 1e-18 : x, ID_ctry)
    replace!(x -> x == 0.0 ? 1e-18 : x, FD_ctry)

    # claculate Head-Reis index
    θ = 5 # assumption on trade elasticity
    τ_ID = [((ID_ctry[i, j] * ID_ctry[j, i]) / (ID_ctry[i, i] * ID_ctry[j, j]))^(-1/(2θ)) for i in 1:n_ctrys, j in 1:n_ctrys] # bilateral trade costs
    τ_FD = [((FD_ctry[i, j] * FD_ctry[j, i]) / (FD_ctry[i, i] * FD_ctry[j, j]))^(-1/(2θ)) for i in 1:n_ctrys, j in 1:n_ctrys]

    # simple average over all country pairs where i<j => upper triangular matrix without within country trade costs (i.e. diagonal = 1.0)
    τ_avg_id = filter(x -> x != 1.0 && x != 0.0, UpperTriangular(τ_ID)) # filter out 1.0 (within country trade costs) & 0.0 (lower triangular matrix)
    τ_avg_fd = filter(x -> x != 1.0 && x != 0.0, UpperTriangular(τ_FD))

    # footnote 23 on page 21: drop largest 1% of values
    sort!(τ_avg_id)
    sort!(τ_avg_fd)
    τ_avg_id = mean(τ_avg_id[1:end-10]) # use 10/820 instead of 1%
    τ_avg_fd = mean(τ_avg_fd[1:end-10])

    return τ_avg_id, τ_avg_fd
end

t_fig_7 = DataFrame(year=Int[], τ_ID=Float64[], τ_FD=Float64[])

for i in years
    τ_avg_id, τ_avg_fd = country_level_head_reis_index(df, i)
    push!(t_fig_7, [i τ_avg_id τ_avg_fd])
end

XLSX.writetable("clean/t_fig_7.xlsx", t_fig_7, overwrite=true) # export table to folder as input for plotting figure 7

# -------------- Figure 7 -------------------------------------------------------------------------------------------------------------------


t_fig_7 = DataFrame(XLSX.readtable("clean/t_fig_7.xlsx", "Sheet1")...) # load directly from file
transform!(t_fig_7, :year .=> ByRow(Int) .=> :year, renamecols=false) # change type to Int64
transform!(t_fig_7, [:τ_ID, :τ_FD] .=> ByRow(Float64) .=> [:τ_ID, :τ_FD], renamecols=false) # change type to Float64

p_fig7 = plot(t_fig_7.year, [t_fig_7.τ_ID t_fig_7.τ_FD], xlabel="Year", ylabel="Iceberg τ", title="Figure 7: Head-Reis τ's (country level) over time",
                label=["Input-use mean τ" "Final-use mean τ"], ylims=(2.45,5.05), leg=:bottomleft, lw=2)

savefig(p_fig7, "images/figure7.png") # export image to folder