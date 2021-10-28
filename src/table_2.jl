# Script to replicate table 2 (regression from equation 11)

using DataFrames, FixedEffectModels, RegressionTables, StatsBase, Statistics, LinearAlgebra, XLSX

# -------------- Previous scripts -----------------------------------------------------------------------------------------------------------------------

include("src/data_wrangling.jl") # formats the raw input data obtained from WIOD

# -------------- Country-sector I/O-Table ---------------------------------------------------------------------------------------------------------------

function country_sector_level_GVC_indicators(df::DataFrame, year::Int64)

    ID, FD, GO, VA, IV, other = obtain_matrices(df, year) # N*S×N*S, N*S×N, N*S×1, N*S×1, N*S×N, N*S×1

    # net inventory correction
    iv_correction = [GO[i]/(GO[i]-IV[i, j]) for i in 1:n_ctrys*n_sectors, j in 1:n_ctrys] # N*S×N, to match country wise inventory changes
    # notice difference in column size, need spread inventory correction of country column to country-sector columns
    # i.e. ID[1,1:35]/iv_correction[1,1], however problem with indexing => ceil(Int, 34/35)=1, ceil(Int, 36/35)=2
    ID_corrected = [ID[i, j]*iv_correction[i, ceil(Int, j/n_sectors)] for i in 1:n_ctrys*n_sectors, j in 1:n_ctrys*n_sectors] # N*S×N*S
    FD_corrected = [FD[i, j]*iv_correction[i, j] for i in 1:n_ctrys*n_sectors, j in 1:n_ctrys]
    FD_corrected = [sum(FD_corrected[i, :]) for i in 1:n_ctrys*n_sectors]

    replace!(ID_corrected, NaN => 0.0) # sometimes zeros are interpreted as NaN (particular for sector 35, private households with employed persons)
    replace!(FD_corrected, NaN => 0.0)

    # input/output coefficient matrices
    A = [ID_corrected[i, j] / GO[j] for i in 1:n_ctrys*n_sectors, j in 1:n_ctrys*n_sectors] # N*S×N*S, iterate output over destination country
    B = [ID_corrected[i, j] / GO[i] for i in 1:n_ctrys*n_sectors, j in 1:n_ctrys*n_sectors] # N*S×N*S, iterate output over reporting country

    replace!(A, NaN => 0.0) # sometimes zeros are interpreted as NaN (particular for sector 35, private households with employed persons)
    replace!(B, NaN => 0.0)

    # country-sector level statistics
    FD_GO = FD_corrected ./ GO # N*S×1
    VA_GO = VA ./ GO # N*S×1
    U_num = inv(I - A) * GO # N*S×1, numerator of equation (5)
    D_num = transpose(GO) * inv(I - B) # N*S×1, numerator of equation (7), notice difference in matrix algebra

    U = U_num ./ GO # N*S×1
    D = transpose(D_num) ./ GO # N*S×1, transpose to have column vector

    # collect data in a DataFrame
    summary_stats = hcat(fill(year, n_ctrys*n_sectors), repeat(ctrys, inner=n_sectors), repeat(1:35, outer=n_ctrys), FD_GO, VA_GO, U, D)
    t_country_sector_wide = DataFrame(summary_stats, :auto)
    rename!(t_country_sector_wide, [:year, :country, :sector, :FD_GO, :VA_GO, :U, :D])
    transform!(t_country_sector_wide, [:FD_GO, :VA_GO, :U, :D] .=> ByRow(x -> round(x, digits=3)) .=> [:FD_GO, :VA_GO, :U, :D])

    return t_country_sector_wide
end

# gather data for all years in a single data frame
t_tab2 = DataFrame(year=Int[], country=String[], sector=Int[], FD_GO=Float64[], VA_GO=Float64[], U=Float64[], D=Float64[])

for i in years
    append!(t_tab2, country_sector_level_GVC_indicators(df, i))
end

XLSX.writetable("clean/t_tab2.xlsx", t_tab2, overwrite=true) # export table 

# -------------- Table 2 --------------------------------------------------------------------------------------------------------------------------------

# inport data from local drive
t_tab2 = DataFrame(XLSX.readtable("clean/t_tab2.xlsx", "Sheet1")...)
transform!(t_tab2, :country .=> ByRow(string) .=> :country, renamecols=false) # change type to String
transform!(t_tab2, [:year, :sector] .=> ByRow(Int) .=> [:year, :sector], renamecols=false) # change type to Int64
transform!(t_tab2, [:FD_GO, :VA_GO, :U, :D] .=> ByRow(Float64) .=> [:FD_GO, :VA_GO, :U, :D], renamecols=false) # change type to Float64

# use package: FixedEffectModels

# different ways of specifying the same regression, i.e. using either @formula, Symbols, Strings
# FixedEffectModels.reg(data_reg, @formula(FD_GO ~ year + fe(country_sector)), Vcov.cluster(:year, :country_sector))
# FixedEffectModels.reg(data_reg, term(:VA_GO) ~ term(:year) + fe(:country_sector), Vcov.cluster(:year, :country_sector))
# FixedEffectModels.reg(data_reg, term("VA_GO") ~ term("year") + fe(term("country_sector")), Vcov.cluster(:year, :country_sector))

data_reg = subset(t_tab2, :VA_GO => ByRow(x -> !isnan(x))) # filter out NaN
data_reg[:, :country_sector] .= data_reg[:, :country] .* "_" .* string.(data_reg[:, :sector]) # considerably improves R² compared to use columns individually

rr_FD_GO_1 = FixedEffectModels.reg(data_reg, @formula(FD_GO ~ year + fe(country_sector)), Vcov.cluster(:country_sector), save=true)
rr_FD_GO_2 = FixedEffectModels.reg(data_reg, @formula(FD_GO ~ year + fe(country_sector)), contrasts = Dict(:year => DummyCoding(base=1995)),
 Vcov.cluster(:country_sector), save=true)
rr_VA_GO_1 = FixedEffectModels.reg(data_reg, @formula(VA_GO ~ year + fe(country_sector)), Vcov.cluster(:country_sector), save=true)
rr_VA_GO_2 = FixedEffectModels.reg(data_reg, @formula(VA_GO ~ year + fe(country_sector)), contrasts = Dict(:year => DummyCoding(base=1995)),
 Vcov.cluster(:country_sector), save=true)
rr_U_1 = FixedEffectModels.reg(data_reg, @formula(U ~ year + fe(country_sector)), Vcov.cluster(:country_sector), save=true)
rr_U_2 = FixedEffectModels.reg(data_reg, @formula(U ~ year + fe(country_sector)), contrasts = Dict(:year => DummyCoding(base=1995)),
 Vcov.cluster(:country_sector), save=true)
rr_D_1 = FixedEffectModels.reg(data_reg, @formula(D ~ year + fe(country_sector)), Vcov.cluster(:country_sector), save=true)
rr_D_2 = FixedEffectModels.reg(data_reg, @formula(D ~ year + fe(country_sector)), contrasts = Dict(:year => DummyCoding(base=1995)),
 Vcov.cluster(:country_sector), save=true)

# use package: RegressionTables

RegressionTables.regtable(rr_FD_GO_1, rr_FD_GO_2, rr_VA_GO_1, rr_VA_GO_2, rr_U_1, rr_U_2, rr_D_1, rr_D_2;
 renderSettings = asciiOutput(), regression_statistics=[:nobs, :r2], print_fe_section=true, estimformat="%0.4f") # output on the console

RegressionTables.regtable(rr_FD_GO_1, rr_FD_GO_2, rr_VA_GO_1, rr_VA_GO_2, rr_U_1, rr_U_2, rr_D_1, rr_D_2;
 renderSettings = htmlOutput("images/table2.txt"), regression_statistics=[:nobs, :r2], print_fe_section=true, estimformat="%0.4f") # export as html

# regressions coincide very well, possible source of difference is the additional 300 observations of Antras and Chor (2018)
# have for VA, U, D (i.e. must have fewer NaN, but how?)
# Notice: RegressionTables reports only 3 decimal places (as opposed to 4 in the paper) => possibly need to manually edit