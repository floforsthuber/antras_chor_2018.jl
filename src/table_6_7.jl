# Script to replicate table 4 and 5 (regression from equation 15 and 16)

using DataFrames, FixedEffectModels, RegressionTables, StatsBase, Statistics, LinearAlgebra, XLSX

# -------------- Previous scripts -----------------------------------------------------------------------------------------------------------------------

include("src/data_wrangling.jl") # formats the raw input data obtained from WIOD

# -------------- Country-sector level I/O-Table ---------------------------------------------------------------------------------------------------------

function country_sector_level_GVC_indicators(df::DataFrame, year::Int64)

    ID, FD, GO, VA, IV, other = obtain_matrices(df, year) # N*S×N*S, N*S×N, N*S×1, N*S×1, N*S×N, N*S×1

    # net inventory correction
    iv_correction = [GO[i]/(GO[i]-IV[i, j]) for i in 1:n_ctrys*n_sectors, j in 1:n_ctrys] # N*S×N, to match country wise inventory changes
    # notice difference in column size, need spread inventory correction of country column to country-sector columns
    # i.e. ID[1,1:35]/iv_correction[1,1], however problem with indexing => ceil(Int, 34/35)=1, ceil(Int, 36/35)=2
    ID_corrected = [ID[i, j]*iv_correction[i, ceil(Int, j/n_sectors)] for i in 1:n_ctrys*n_sectors, j in 1:n_ctrys*n_sectors] # N*S×N*S
    FD_corrected = [FD[i, j]*iv_correction[i, j] for i in 1:n_ctrys*n_sectors, j in 1:n_ctrys] # N*S×N
    FD_corrected = [sum(FD_corrected[i, :]) for i in 1:n_ctrys*n_sectors] # N*S×1

    ID = replace!(ID_corrected, NaN => 0.0) # sometimes zeros are interpreted as NaN (particular for sector 35, private households with employed persons)
    FD = replace!(FD_corrected, NaN => 0.0)

    γ = [sum(ID[i, j])/GO[j] for i in 1:n_sectors:n_ctrys*n_sectors, j in 1:n_ctrys*n_sectors]