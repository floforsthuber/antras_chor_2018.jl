# Script to replicate table 3 (regression from equation 12)

using DataFrames, FixedEffectModels, RegressionTables, StatsBase, Statistics, LinearAlgebra, XLSX, PrettyTables

# -------------- Import data --------------------------------------------------------------------------------------------------------------------------------

# import data from local drive
t_tab3 = DataFrame(XLSX.readtable("clean/t_tab2.xlsx", "Sheet1")...) # still a lot of NaN
transform!(t_tab3, :country .=> ByRow(string) .=> :country, renamecols=false) # change type to String
transform!(t_tab3, [:year, :sector] .=> ByRow(Int) .=> [:year, :sector], renamecols=false) # change type to Int64
transform!(t_tab3, [:FD_GO, :VA_GO, :U, :D] .=> ByRow(Float64) .=> [:FD_GO, :VA_GO, :U, :D], renamecols=false) # change type to Float64

# need to take out rows with NaN, considerably improves match with original numbers (too much correlation otherwise)
data_reg = subset(t_tab3, :VA_GO => ByRow(x -> !isnan(x)))
data_reg[:, :country_sector] .= data_reg[:, :country] .* "_" .* string.(data_reg[:, :sector]) # using seperate FE does not change anything?

function reg_tab3(df::DataFrame, year::Int64, y, x)
    df = subset(df, :year => ByRow(x -> x == year))

    rr_1 = FixedEffectModels.reg(df, term(y) ~ term(x), Vcov.cluster(:country_sector), save=true)
    rr_2 = FixedEffectModels.reg(df, term(y) ~ term(x) + fe(term(:country)), Vcov.cluster(:country_sector), save=true)
    rr_3 = FixedEffectModels.reg(df, term(y) ~ term(x) + fe(term(:country)) + fe(term(:sector)), Vcov.cluster(:country_sector), save=true)

    reg = RegressionTables.regtable(rr_1, rr_2, rr_3;
    renderSettings = asciiOutput(), regression_statistics=[:nobs, :r2], print_fe_section=true, estimformat="%0.4f") # output on the console

    return reg
end

# regression results in ascii format
reg_tab3(data_reg, 1995, :FD_GO, :VA_GO)
reg_tab3(data_reg, 2011, :FD_GO, :VA_GO)
reg_tab3(data_reg, 1995, :U, :D)
reg_tab3(data_reg, 2011, :U, :D)