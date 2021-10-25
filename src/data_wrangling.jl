# Script for formatting the raw data

using DataFrames, StatFiles

# -------------- loading data -----------------------------------------------------------------------------------------------------------------------

df = DataFrame(load("raw/wiot_full.dta")) # entire 2013 version of WIOD (1995-2011) in long format
df2 = copy(df) # make a copy in case code does not work so we dont need to load entire dataset every time!
df = df[end-3_000_000:end, :] # work with smaller df for now

rename!(df, :row_item => :row_sector, :col_item => :col_sector)
transform!(df, [:row_country, :col_country] .=> ByRow(string) .=> [:row_country, :col_country], renamecols=false) # convert columns to strings

transform!(df, [:year, :row_sector, :col_sector] .=> ByRow(Int64) .=> [:year, :row_sector, :col_sector], renamecols=false) # convert columns to Float64
sort!(df, names(df[:, Not([:col_country, :value])])) # now sorted alphabetically and numerically except for row_country where the additional variables
# TOT, GO, VA are at the bottom of each year

# -------------- data wrangling -----------------------------------------------------------------------------------------------------------------------

ctrys = sort(unique(df.col_country)) # all country iso3 codes
n_ctrys = length(ctrys) # 40 + ROW = 41 countries in WIOD Release 2013 
goods_sectors = 1:16 # numbers associated with goods sectors
service_sectors = 17:35 # numbers associated with service sectors
n_sectors = length([goods_sectors; service_sectors]) # 35 different sectors in WIOD Release 2013

# The function "make matrix" accepts is designed to use the input data from WIOD in stata format (above), it returns the specified year's
# 1. ID_corrected ... "net inventory corrected" intermediate demand, N*S×N*S matrix
# 2. FD_corrected ... "net inventory corrected" final demand, N*S×N matrix
# 3. GO ... total final output, N*S×1 vector
# 4. other ... total other expenses, N*S×1 vector
# Notes: use "sort!" exessively in order to make sure the matrices are sorted accordingly to country-sector pairs
# Notes: also computes original ID and FD, IV - if needed we can extract them from the function too

function obtain_matrices(df::DataFrame, year::Int64)

    # subset df at start to make difference in subsets below clearer
    df1 = subset(df, :year => ByRow(x -> x == year), :row_country => ByRow(x -> x in ctrys), :col_country => ByRow(x -> x in ctrys)) 


    # ---------------- Intermediate demand matrix, N*S×N*S
    ID_long = subset(df1, :row_sector => ByRow(x -> x in 1:35), :col_sector => ByRow(x -> x in 1:35)) # subsetting for correct sectors
    
    sort!(ID_long, [:row_country, :row_sector, :col_country, :col_sector]) # sort according to country and sector
    ID_long[:, :id_col] .= ID_long.col_country .* "___" .* string.(ID_long.col_sector) # identifier column for wide format

    ID_wide = unstack(ID_long, [:row_country, :row_sector], :id_col, :value) # transform into wide format
    ID = Matrix(convert.(Float64, ID_wide[:, Not([:row_country, :row_sector])])) # N*S×N*S, matrix object to perform matrix algebra


    # ---------------- Final demand matrix, N*S×N
    FD_long = subset(df1, :row_sector => ByRow(x -> x in 1:35), :col_sector => ByRow(x -> x in 37:41)) # subsetting for correct sectors

    gdf = groupby(FD_long, [:row_country, :row_sector, :col_country]) # sum the four sources of final demand into one
    FD_long = combine(gdf, :value => sum => :total)

    sort!(FD_long, [:row_country, :col_country, :row_sector]) # sort according to country and sector
    FD_wide = unstack(FD_long, [:row_country, :row_sector], :col_country, :total) # transform into wide format
    FD = Matrix(convert.(Float64, FD_wide[:, Not([:row_country, :row_sector])])) # N*S×N, matrix object to perform matrix algebra


    # ---------------- Inventory demand matrix, N*S×N
    IV_long = subset(df1, :row_sector => ByRow(x -> x in 1:35), :col_sector => ByRow(x -> x == 42)) # subsetting for correct sectors
    
    sort!(IV_long, [:row_country, :row_sector, :col_country]) # sort according to country and sector
    gdf = groupby(IV_long, [:row_country, :row_sector, :col_country]) 
    IV_long = combine(gdf, :value => sum => :total)
    IV_wide = unstack(IV_long, [:row_country, :row_sector], :col_country, :total) # transform into wide format

    IV = Matrix(convert.(Float64, IV_wide[:, Not([:row_country, :row_sector])])) # N*S×N, matrix object to perform matrix algebra
  
    
    # ---------------- Gross output, N*S×N
    GO_long = subset(df, :year => ByRow(x -> x == year), :row_country => ByRow(x -> x == "GO"), :col_country => ByRow(x -> x in ctrys), 
    :col_sector => ByRow(x -> x in 1:35)) # subsetting for GO (gross output), countries and sectors (notice using df not df1 anymore)
    
    sort!(GO_long, [:col_country, :col_sector])
    GO = GO_long.value


    # ---------------- Value added matrix, N*S×N
    VA_long = subset(df, :year => ByRow(x -> x == year), :row_country => ByRow(x -> x == "VA"), :col_country => ByRow(x -> x in ctrys), 
    :col_sector => ByRow(x -> x in 1:35)) # subsetting for VA, countries and sectors (notice using df not df1 anymore)

    sort!(VA_long, [:col_country, :col_sector])
    VA = VA_long.value


    # ---------------- Other records matrix, N*S×N
    other = ["CIF", "ITM", "PUA", "PUF", "TXP"] # subsetting for [CIF, ITM, PUA, PUF, TXP], countries and sectors
    other_long = subset(df, :year => ByRow(x -> x == year), :row_country => ByRow(x -> x in other), :col_country => ByRow(x -> x in ctrys), 
    :col_sector => ByRow(x -> x in 1:35)) # (notice using df not df1 anymore)

    gdf = groupby(other_long, [:col_country, :col_sector]) # sum the four sources of final demand into one
    other_long = combine(gdf, :value => sum => :total)

    sort!(other_long, [:col_country, :col_sector])
    other = other_long.total


    # ---------------- Net inventory correction (page 12, also see Antras et al. (2012))
    # basically adjust intermediate and final demand matrix by inventory fraction

    IV_all = [sum(IV[i, :]) for i in 1:n_ctrys*n_sectors] # spread inventory at country level across ID/FD (could do more refined and match countries)
    iv_correction = GO ./ (GO .- IV_all)

    ID_corrected = [ID[i, j] * iv_correction[i] for i in 1:n_ctrys*n_sectors, j in 1:n_ctrys*n_sectors]
    FD_corrected = [FD[i, j] * iv_correction[i] for i in 1:n_ctrys*n_sectors, j in 1:n_ctrys]

    replace!(ID_corrected, NaN => 0.0) # sometimes zeros are interpreted as NaN (particular for sector 35, private households with employed persons)
    replace!(FD_corrected, NaN => 0.0)

    return ID, FD, GO, VA, IV, other

end

#ID, FD, GO, VA, IV, other = obtain_matrices(df, 2011)

