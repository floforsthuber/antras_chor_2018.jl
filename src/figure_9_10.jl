# Script to replicate figure 8 and 9

using DataFrames, XLSX, StatsPlots

# -------------- Import data ---------------------------------------------------------------------------------------------------------

t_fig_9_10 = DataFrame(XLSX.readtable("clean/t_tab2.xlsx", "Sheet1")...) # still a lot of NaN
transform!(t_fig_9_10, :country .=> ByRow(string) .=> :country, renamecols=false) # change type to String
transform!(t_fig_9_10, [:year, :sector] .=> ByRow(Int) .=> [:year, :sector], renamecols=false) # change type to Int64
transform!(t_fig_9_10, [:FD_GO, :VA_GO, :U, :D] .=> ByRow(Float64) .=> [:FD_GO, :VA_GO, :U, :D], renamecols=false) # change type to Float64

subset!(t_fig_9_10, :D => ByRow(x -> !isnan(x))) # take out NaN
transform!(t_fig_9_10, :sector => ByRow(x -> ifelse(x in goods_sectors, "goods", "services")) => :sector_dummy, renamecols=false) # sector dummy for grouping

# -------------- Figure 9 --------------------------------------------------------------------------------------------------------------------------------

function plot_fig_9(df::DataFrame, year::Int64, industry::String, a, b) # input vectors in so we can plot multiple countries for comparison
    
    subset!(df, :year => ByRow(x -> x == year))    
    df = industry in ["goods", "services"] ? subset(df, :sector_dummy => ByRow(x -> x == industry)) : df

    p = @df df scatter(cols(a), cols(b), group=:sector_dummy, xlims=(-0.1,1.1), ylims=(-0.1,1.1),
        xlabel="$(String(a))", ylabel="$(String(b))", label=:none, alpha=0.65,
        title="$(industry)", smooth=:true, linecolor=:black, lw=3)

    return p
end

l = @layout [a b c] # 1×3 layout
p1 = plot_fig_9(t_fig_9_10, 2011, "goods", :VA_GO, :FD_GO)
p2 = plot_fig_9(t_fig_9_10, 2011, "services", :VA_GO, :FD_GO)
p3 = plot_fig_9(t_fig_9_10, 2011, "all industries", :VA_GO, :FD_GO)
title = "Figure 9: Correlation between FD and VA: Goods vs Services"
p_fig9 = plot(p1, p2, p3, layout=l, plot_title=title, plot_titlefontsize=10)
savefig(p_fig9, "images/figure9.png") # export image to folder

# -------------- Figure 10 --------------------------------------------------------------------------------------------------------------------------------

function plot_fig_10(df::DataFrame, year::Int64, industry::String, a, b) # input vectors in so we can plot multiple countries for comparison
    
    subset!(df, :year => ByRow(x -> x == year))    
    df = industry in ["goods", "services"] ? subset(df, :sector_dummy => ByRow(x -> x == industry)) : df

    p = @df df scatter(cols(a), cols(b), group=:sector_dummy, xlims=(0.9,4.5), ylims=(0.9,4.5),
        xlabel="$(String(a))", ylabel="$(String(b))", label=:none, alpha=0.65,
        title="$(industry)", smooth=:true, linecolor=:black, lw=3)

    return p
end

l = @layout [a b c] # 1×3 layout
p1 = plot_fig_10(t_fig_9_10, 2011, "goods", :D, :U)
p2 = plot_fig_10(t_fig_9_10, 2011, "services", :D, :U)
p3 = plot_fig_10(t_fig_9_10, 2011, "all industries", :D, :U)
title = "Figure 9: Correlation between U and D: Goods vs Services"
p_fig10 = plot(p1, p2, p3, layout=l, plot_title=title, plot_titlefontsize=10)
savefig(p_fig10, "images/figure10.png") # export image to folder