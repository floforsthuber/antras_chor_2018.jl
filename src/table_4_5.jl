# Script to replicate table 4 and 5 (regression from equation 15 and 16)

using DataFrames, FixedEffectModels, RegressionTables, StatsBase, Statistics, LinearAlgebra, CSV

# -------------- Previous scripts -----------------------------------------------------------------------------------------------------------------------

include("src/data_wrangling.jl") # formats the raw input data obtained from WIOD

# -------------- Country-sector level I/O-Table ---------------------------------------------------------------------------------------------------------

# function to format matrix to DataFrame in main function "country_sector_level_head_reis_index"
function head_reis_df(result::Matrix, year::Int64, output::String) 
    namestable = ["year", "row_country", "row_sector"]
    namestable = [namestable; repeat(ctrys, inner=n_sectors) .* "_" .* string.(repeat(1:35, outer=n_ctrys))]

    if (output == "ID")
        data = UpperTriangular(result)
    else
        data = UpperTriangular(result)
        for diagonal in 1:size(data, 1)
            data[diagonal, diagonal] = 0.0 # set diagonal entries = 0.0 as we filter them out later
        end
    end


    table = hcat(fill(year, n_ctrys*n_sectors), repeat(ctrys, inner=n_sectors), repeat(1:35, outer=n_ctrys), UpperTriangular(data))
    table = DataFrame(table, namestable)

    table_long = stack(table, Not([:year, :row_country, :row_sector]))
    table_long = subset(table_long, :value => ByRow(x -> x != 0.0))

    table_long = hcat(table_long, DataFrame(reduce(vcat, permutedims.(split.(table_long.variable, "_"))), [:col_country, :col_sector]))
    table_long = table_long[:, Not(:variable)]

    transform!(table_long, [:row_country, :col_country] .=> ByRow(string) .=> [:row_country, :col_country], renamecols=false) # change type to String
    transform!(table_long, [:year, :row_sector] .=> ByRow(Int) .=> [:year, :row_sector], renamecols=false) # change type to Int64
    transform!(table_long, :value .=> ByRow(Float64) .=> :value, renamecols=false) # change type to Float64
    transform!(table_long, :col_sector .=> ByRow(x -> parse(Int64,x)) .=> :col_sector, renamecols=false) # change type to Int64

    return table_long
end

function country_sector_level_head_reis_index(df::DataFrame, year::Int64, output::String)

    ID, FD, GO, VA, IV, other = obtain_matrices(df, year) # N*S×N*S, N*S×N, N*S×1, N*S×1, N*S×N, N*S×1

    # net inventory correction
    iv_correction = [GO[i]/(GO[i]-IV[i, j]) for i in 1:n_ctrys*n_sectors, j in 1:n_ctrys] # N*S×N, to match country wise inventory changes
    # notice difference in column size, need spread inventory correction of country column to country-sector columns
    # i.e. ID[1,1:35]/iv_correction[1,1], however problem with indexing => ceil(Int, 34/35)=1, ceil(Int, 36/35)=2
    ID_corrected = [ID[i, j]*iv_correction[i, ceil(Int, j/n_sectors)] for i in 1:n_ctrys*n_sectors, j in 1:n_ctrys*n_sectors] # N*S×N*S
    FD_corrected = [FD[i, j]*iv_correction[i, j] for i in 1:n_ctrys*n_sectors, j in 1:n_ctrys] # N*S×N

    replace!(ID_corrected, NaN => 0.0) # sometimes zeros are interpreted as NaN (particular for sector 35, private households with employed persons)
    replace!(FD_corrected, NaN => 0.0)

    # footnote 22 on page 21: substitute 1e-18 for any zero entries otherwise trade costs explode to infinity!
    ID = replace!(x -> x <= 0.0 ? 1e-18 : x, ID_corrected) # N*S×N*S
    FD = replace!(x -> x <= 0.0 ? 1e-18 : x, FD_corrected) # N*S×N

    # claculate Head-Reis index
    θ = 5 # assumption on trade elasticity
    τ_ID = [((ID[i, j] * ID[j, i]) / (ID[i, i] * ID[j, j]))^(-1/(2θ)) for i in 1:n_ctrys*n_sectors, j in 1:n_ctrys*n_sectors] # bilater country-sector trade costs
    τ_FD = [((FD[i, ceil(Int, j/n_sectors)] * FD[j, ceil(Int, i/n_sectors)]) / (FD[i, ceil(Int, i/n_sectors)] * FD[j, ceil(Int, j/n_sectors)]))^(-1/(2θ)) for i in 1:n_ctrys*n_sectors, j in 1:n_ctrys*n_sectors]

    result = output == "ID" ? τ_ID : τ_FD

    head_reis_df(result::Matrix, year::Int64, output::String) 
    
end

t_tab4 = DataFrame(year=Int[], row_country=String[], row_sector=Int64[], col_country=String[], col_sector=Int64[], value=Float64[])
t_tab5 = DataFrame(year=Int[], row_country=String[], row_sector=Int64[], col_country=String[], col_sector=Int64[], value=Float64[])

for i in years
    append!(t_tab4, country_sector_level_head_reis_index(df, i, "ID"))
    append!(t_tab5, country_sector_level_head_reis_index(df, i, "FD"))
end

CSV.write("clean/t_tab4.csv", t_tab4) # use CSV since XLSX cannot store that many rows
CSV.write("clean/t_tab5.csv", t_tab5)

# -------------- Table 4 -----------------------------------------------------------------------------------------------------------------------------

t_tab4 = CSV.read("clean/t_tab4.csv", DataFrame) # also imports types correctly!
t_tab5 = CSV.read("clean/t_tab4.csv", DataFrame) # also imports types correctly!

function reg_tab_4_5(df::DataFrame)

    df[:, :row_origin_destination] .= df[:, :row_country] .* "_" .* string.(df[:, :row_sector]) # for standard error clustering
    df[:, :col_origin_destination] .= df[:, :row_country] .* "_" .* string.(df[:, :row_sector]) # for standard error clustering
    df[:, :origin_destination] .= df[:, :row_origin_destination] .* "___" .* df[:, :col_origin_destination] # for fixed effects
    transform!(df, :row_sector => ByRow(x -> x in goods_sectors ? 1 : 0) => :row_sector_dummy) # dummy for *reporting* sector, "goods" = 1

    df_goods = subset(df, :row_sector_dummy => ByRow(x -> x==1)) # only goods sectors
    df_services = subset(df, :row_sector_dummy => ByRow(x -> x!=1)) # only service sectors

    regression = Dict{String,Any}() # initializing dictionary to store regression results (Any could be replaced by type FixedEffectModel)
    df_names = ["all", "goods", "services"] # names of dictionary "keys"
    df_array = [df, df_goods, df_services] # names of DataFrames used

    for i in 1:length(df_names)
        push!(regression, "reg_1_" * df_names[i] => 
        FixedEffectModels.reg(df_array[i], @formula(log(value) ~ year + fe(origin_destination)), Vcov.cluster(:row_origin_destination, :col_origin_destination, :year)))
        
        push!(regression, "reg_2_" * df_names[i] => 
        FixedEffectModels.reg(df_array[i], @formula(log(value) ~ year + fe(origin_destination)), Vcov.cluster(:row_origin_destination, :col_origin_destination, :year),
            contrasts = Dict(:year => DummyCoding(base=1995)))) # treat years as dummies
    end

    reg = RegressionTables.regtable(regression["reg_1_all"], regression["reg_2_all"], regression["reg_1_goods"], regression["reg_2_goods"],
        regression["reg_1_services"], regression["reg_2_services"];
        renderSettings = asciiOutput(), regression_statistics=[:nobs, :r2], print_fe_section=true, estimformat="%0.4f") # output on the console

    return reg

end

reg_tab_4_5(t_tab4)


# -------------- Table 5 -----------------------------------------------------------------------------------------------------------------------------

reg_tab_4_5(t_tab5) # is not correct!
# should input should be a N*S×N by matrix not N*S×N*S
# results are still suprisingly close