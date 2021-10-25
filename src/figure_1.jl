# Script for replicating figure 1

using Statistics, LinearAlgebra

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
    A = [ID_ctry[i, j] / GO_ctry[j] for i in 1:n_ctrys, j in 1:n_ctrys] # N×N, input share matrix
    B = [ID_ctry[i, j] / GO_ctry[i] for i in 1:n_ctrys, j in 1:n_ctrys] # N×N, output share matrix

    # country level statistics
    FD_GO = FD_ctry ./ GO_ctry # N×1
    VA_GO = VA_ctry ./ GO_ctry # N×1
    U = inv(I - A) * GO_ctry # N×1
    D = inv(I - B) * GO_ctry # N×1

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
    transform!(t_country_wide, [:U, :D] .=> ByRow(x -> x/1_000_000) .=> [:U, :D]) # rescale U, D for better comparison
    transform!(t_country_wide, [:FD_GO, :VA_GO, :U, :D] .=> ByRow(x -> round(x, digits=3)) .=> [:FD_GO, :VA_GO, :U, :D]) # rescale U, D for better comparison

    return t_country_wide

end

a = country_level_position(df, 2011)
