# Script to replicate table 6 and 7 (regression from equation 17 and 18)

using DataFrames, FixedEffectModels, RegressionTables, StatsBase, Statistics, LinearAlgebra, CSV

# -------------- Previous scripts -----------------------------------------------------------------------------------------------------------------------

include("src/data_wrangling.jl") # formats the raw input data obtained from WIOD

# -------------- Country-sector level I/O-Table ---------------------------------------------------------------------------------------------------------

function country_sector_level_composition_indicators(df::DataFrame, year::Int64, output::String)

    ID, FD, GO, VA, IV, other = obtain_matrices(df, year) # N*S×N*S, N*S×N, N*S×1, N*S×1, N*S×N, N*S×1

    # net inventory correction
    iv_correction = [GO[i]/(GO[i]-IV[i, j]) for i in 1:n_ctrys*n_sectors, j in 1:n_ctrys] # N*S×N, to match country wise inventory changes
    # notice difference in column size, need spread inventory correction of country column to country-sector columns
    # i.e. ID[1,1:35]/iv_correction[1,1], however problem with indexing => ceil(Int, 34/35)=1, ceil(Int, 36/35)=2
    ID_corrected = [ID[i, j]*iv_correction[i, ceil(Int, j/n_sectors)] for i in 1:n_ctrys*n_sectors, j in 1:n_ctrys*n_sectors] # N*S×N*S
    FD_corrected = [FD[i, j]*iv_correction[i, j] for i in 1:n_ctrys*n_sectors, j in 1:n_ctrys] # N*S×N
    
    ID = replace!(ID_corrected, NaN => 0.0) # sometimes zeros are interpreted as NaN (particular for sector 35, private households with employed persons)
    FD = replace!(FD_corrected, NaN => 0.0)

    FD_ctry = [sum(FD[:, j]) for j in 1:n_ctrys] # 1×N
    FD_ctry = transpose(FD_ctry)

    sector_iterator = 0:n_sectors:n_ctrys*n_sectors-1 
    # sum the same sector over all destination countries and divide by total final demand of destination country 
    α = [sum(FD[sector_iterator .+ i, j]/FD_ctry[j]) for i in 1:n_sectors, j in 1:n_ctrys] # S×N, each column sums to 1.0

    # sum the same sector over all destination country-industry pairs and divide by corresponding output of country-industry
    γ = [sum(ID[sector_iterator .+ i, j])/GO[j] for i in 1:n_sectors, j in 1:n_ctrys*n_sectors] # S×N*S

    # in DataFrame format
    # add ifelse since dimensions are different, i.e. S×N vs S×N*S
    if (output == "α") 
        table_α = hcat(fill(year, n_sectors), 1:35, α)
        namestable = ["year", "row_sector"]
        namestable = [namestable; ctrys]
        table_α = DataFrame(table_α, namestable)
        table_α_long = stack(table_α, Not([:year, :row_sector]))
        rename!(table_α_long, :variable => :country)
        
        result = table_α_long
    
    else 
        table_γ = hcat(fill(year, n_sectors), 1:35, γ)
        namestable = ["year", "row_sector"]
        namestable = [namestable; repeat(ctrys, inner=n_sectors) .* "_" .* string.(repeat(1:35, outer=n_ctrys))]
        table_γ = DataFrame(table_γ, namestable)
        table_γ_long = stack(table_γ, Not([:year, :row_sector]))
        table_γ_long = hcat(table_γ_long, DataFrame(reduce(vcat, permutedims.(split.(table_γ_long.variable, "_"))), [:country, :col_sector]))
        transform!(table_γ_long, :col_sector => ByRow(x -> parse(Int64,x)) => :col_sector, renamecols=false) # change type to Int

        result = table_γ_long[:, Not(:variable)]
    end

    transform!(result, :country => ByRow(string) => :country, renamecols=false) # change type to String
    transform!(result, [:year, :row_sector] .=> ByRow(Int64) .=> [:year, :row_sector], renamecols=false) # change type to Int
    transform!(result, :value => ByRow(Float64) => :value, renamecols=false) # change type to Float64

    return result
end


t_tab6 = DataFrame(year=Int[], country=String[], row_sector=Int64[], value=Float64[]) # initialize empty DataFrames
t_tab7 = DataFrame(year=Int[], country=String[], row_sector=Int64[], col_sector=Int64[], value=Float64[])

for i in years
    append!(t_tab6, country_sector_level_composition_indicators(df, i, "α"))
    append!(t_tab7, country_sector_level_composition_indicators(df, i, "γ"))
end

CSV.write("clean/t_tab6.csv", t_tab6)
CSV.write("clean/t_tab7.csv", t_tab7)

# -------------- Table 6 -----------------------------------------------------------------------------------------------------------------------------

t_tab6 = CSV.read("clean/t_tab6.csv", DataFrame) # also imports types correctly!

function reg_tab_6(df::DataFrame)

    #df.value .= ifelse.(df.value .<= 0.0, 1e-18, df.value) # since log cannot deal with 0
    subset!(df, :value => ByRow(x -> x > 0.0)) # same results as with treatment above

    df[:, :country_industry] .= df[:, :country] .* "_" .* string.(df[:, :row_sector]) # for fixed effects
    transform!(df, :row_sector => ByRow(x -> x in goods_sectors ? 1 : 0) => :row_sector_dummy) # dummy for *reporting* sector, "goods" = 1

    df_goods = subset(df, :row_sector_dummy => ByRow(x -> x==1)) # only goods sectors
    df_services = subset(df, :row_sector_dummy => ByRow(x -> x!=1)) # only service sectors

    regression = Dict{String,Any}() # initializing dictionary to store regression results (Any could be replaced by type FixedEffectModel)
    df_names = ["all", "goods", "services"] # names of dictionary "keys"
    df_array = [df, df_goods, df_services] # names of DataFrames used

    for i in 1:length(df_names)
        push!(regression, "reg_1_" * df_names[i] => 
        FixedEffectModels.reg(df_array[i], @formula(log(value) ~ year + fe(country_industry)), Vcov.cluster(:country, :row_sector, :year)))
        
        push!(regression, "reg_2_" * df_names[i] => 
        FixedEffectModels.reg(df_array[i], @formula(log(value) ~ year + fe(country_industry)), Vcov.cluster(:country, :row_sector, :year),
            contrasts = Dict(:year => DummyCoding(base=1995)))) # treat years as dummies
    end

    reg = RegressionTables.regtable(regression["reg_1_all"], regression["reg_2_all"], regression["reg_1_goods"], regression["reg_2_goods"],
    regression["reg_1_services"], regression["reg_2_services"];
    renderSettings = asciiOutput(), regression_statistics=[:nobs, :r2], print_fe_section=true, estimformat="%0.4f") # output on the console

    return reg
end

reg_tab_6(t_tab6)

# -------------- Table 7 -----------------------------------------------------------------------------------------------------------------------------

t_tab7 = CSV.read("clean/t_tab7.csv", DataFrame) 

function reg_tab_7(df::DataFrame)

    df.value .= ifelse.(isinf.(df.value), 0.0, df.value) # treat inf as 0.0
    df.value .= ifelse.(df.value .<= 0.0, 1e-18, df.value) # since log cannot deal with 0
    #subset!(df, :value => ByRow(x -> x > 0.0)) # same results as with treatment above

    df[:, :dest_country_industry] .= df[:, :country] .* "_" .* string.(df[:, :col_sector]) # for SE clustering and fixed effects (purchasing country-industry)
    
    transform!(df, :row_sector => ByRow(x -> x in goods_sectors ? 1 : 0) => :row_sector_dummy) # dummy for *reporting* sector, "goods" = 1
    df_goods = subset(df, :row_sector_dummy => ByRow(x -> x==1)) # only goods sectors (as origin)
    df_services = subset(df, :row_sector_dummy => ByRow(x -> x!=1)) # only service sectors (as origin)

    regression = Dict{String,Any}() # initializing dictionary to store regression results (Any could be replaced by type FixedEffectModel)
    df_names = ["all", "goods", "services"] # names of dictionary "keys"
    df_array = [df, df_goods, df_services] # names of DataFrames used

    for i in 1:length(df_names)
        push!(regression, "reg_1_" * df_names[i] => 
        FixedEffectModels.reg(df_array[i], @formula(log(value) ~ year + fe(row_sector)&fe(dest_country_industry)), Vcov.cluster(:row_sector, :dest_country_industry, :year)))
        
        push!(regression, "reg_2_" * df_names[i] => 
        FixedEffectModels.reg(df_array[i], @formula(log(value) ~ year + fe(row_sector)&fe(dest_country_industry)), Vcov.cluster(:row_sector, :dest_country_industry, :year),
            contrasts = Dict(:year => DummyCoding(base=1995)))) # treat years as dummies
    end

    reg = RegressionTables.regtable(regression["reg_1_all"], regression["reg_2_all"], regression["reg_1_goods"], regression["reg_2_goods"],
    regression["reg_1_services"], regression["reg_2_services"];
    renderSettings = asciiOutput(), regression_statistics=[:nobs, :r2], print_fe_section=true, estimformat="%0.4f") # output on the console

    return reg
end

reg_tab_7(t_tab7)