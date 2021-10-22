# Script for formatting the raw data

using DataFrames, StatFiles

# -------------- loading data -----------------------------------------------------------------------------------------------------------------------

df = DataFrame(load("raw/wiot_full.dta")) # entire 2013 version of WIOD (1995-2011) in long format
df2 = copy(df) # make a copy in case code does not work so we dont need to load entire dataset every time!
df = df[1:3_000_000, :] # work with smaller df for now

rename!(df, :row_item => :row_sector, :col_item => :col_sector)
transform!(df, [:row_country, :col_country] .=> ByRow(string) .=> [:row_country, :col_country], renamecols=false) # convert columns to strings

df.value = ifelse.(df.value .< 0.0, 0.0, df.value) # replace all negative values with zero (there should be no negative values in the first place)
df.value = ifelse.(df.value .== 0.0, 1e-18, df.value) # cannot have zero trade between country-sector pairs otherwise trade costs are infinite
# add a small constant of 1e-18 (less then the smallest value seen in any of the years). For more info see footnote 22 on page 21
### should we do this before or after the netting out of inventories?
transform!(df, [:year, :row_sector, :col_sector] .=> ByRow(Int64) .=> [:year, :row_sector, :col_sector], renamecols=false) # convert columns to Float64

sort!(df, names(df[:, Not([:col_country, :value])])) # now sorted alphabetically and numerically except for row_country where the additional variables
# TOT, GO, VA are at the bottom of each year

# -------------- data wrangling -----------------------------------------------------------------------------------------------------------------------

ctrys = unique(df.col_country) # all country iso3 codes
n_ctrys = length(ctrys) # 40 + ROW = 41 countries in WIOD Release 2013 
goods_sectors = 1:16 # numbers associated with goods sectors
service_sectors = 17:35 # numbers associated with service sectors
n_sectors = length([goods_sectors; service_sectors]) # 35 different sectors in WIOD Release 2013

# add column with identifiers for goods, service sectors (G, S), intermeditae and final consumption (ID, FD), inventories (I), 
# taxes (L), total output (T), value added (VA)
# also add second column with the same identifiers but keep sector number (! need to transform all to strings)

df[:, :id_crude] .= missing
df[:, :id_fine] .= missing

f(x, y, a, b, m) = a <= x <= b ? m : y

function identify(x, y, a, b, m)
    f.(df[:, x], df[:, y], a, b, m)
end

df.id_crude = identify("row_sector", "id_crude", 1, 16, "G")
df.id_crude = identify("row_sector", "id_crude", 17, 35, "S")