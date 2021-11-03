# Script to replicate figure 4 and 5

using StatsBase, Statistics, LinearAlgebra, StatsPlots, XLSX, PrettyTables, GLM

# -------------- Figure 4 --------------------------------------------------------------------------------------------------------------------------------

t_fig_4 = DataFrame(XLSX.readtable("clean/t_fig_2_3.xlsx", "Sheet1")...) # load directly from file
transform!(t_fig_4, :country .=> ByRow(string) .=> :country, renamecols=false) # change type to String
transform!(t_fig_4, :year .=> ByRow(Int) .=> :year, renamecols=false) # change type to Int64
transform!(t_fig_4, [:FD_GO, :VA_GO, :U, :D] .=> ByRow(Float64) .=> [:FD_GO, :VA_GO, :U, :D], renamecols=false) # change type to Float64

function plot_fig4(df::DataFrame, a, b, year::Int64)

    lims = ifelse(a == :D, (1.4,3.1), (0.28,0.72)) # different x, y axis limits
    df = subset(df, :year => ByRow(x -> x == year))
    # unfortunately unable to change size of annotations
    p = @df df scatter(cols(a), cols(b), xlims=lims, ylims=lims, legend=:none, series_annotations=:country,
    xlabel="$(String(a)) ($(year))", ylabel="$(String(b)) ($(year))") # need to use cols(a) to pass from function
    plot!(0.1:0.1:3.1,0.1:0.1:3.1, col=:red, lw=2) # 45 degree line

    return p
end

l = @layout [a b ; c d] # 2×2 layout
p1 = plot_fig4(t_fig_4, :VA_GO, :FD_GO, 1995)
p2 = plot_fig4(t_fig_4, :VA_GO, :FD_GO, 2011)
p3 = plot_fig4(t_fig_4, :D, :U, 1995)
p4 = plot_fig4(t_fig_4, :D, :U, 2011)
title = "Figure 4: GVC Measures and their Correlation over time"
p_fig4 = plot(p1, p2, p3, p4, layout=l, plot_title=title, plot_titlefontsize=10)
savefig(p_fig3, "images/figure4.png") # export image to folder


# -------------- Figure 5 and 6 --------------------------------------------------------------------------------------------------------------------------------

# data for upper panel
gdf = groupby(t_fig_4, :year)
corr_FD_VA = combine(gdf, [:FD_GO, :VA_GO] => ((x, y) -> cor(x, y)) => :correlation)
corr_U_D = combine(gdf, [:U, :D] => ((x, y) -> cor(x, y)) => :correlation)

# data for lower panel: simple OLS grouped per year
corr_confint_FD_VA = DataFrame(year=Int[], beta=Float64[], lower=Float64[], upper=Float64[]) # initiatlizing DataFrame
corr_confint_U_D = DataFrame(year=Int[], beta=Float64[], lower=Float64[], upper=Float64[])

for i in years
    
    df = subset(t_fig_4, :year => ByRow(x -> x == i))

    ols = lm(@formula(FD_GO ~ VA_GO), df)
    β = coef(ols)[2]
    conf = confint(ols)[2,:]
    push!(corr_confint_FD_VA, [i β conf[1] conf[2]]) # push data to the dataframe

    ols = lm(@formula(U ~ D), df)
    β = coef(ols)[2]
    conf = confint(ols)[2,:]
    push!(corr_confint_U_D, [i β conf[1] conf[2]]) # push data to the dataframe
 
end

# figure 5
p1 = @df corr_FD_VA plot(:year, :correlation, xlims=(1994,2012), ylims=(0.79,1.01),
 lw=2, color=:blue, label=:none, ylabel="Correlation: FD on VA")

p2 = @df corr_confint_FD_VA scatter(:year, [:beta, :lower, :upper], xlims=(1994,2012), ylims=(0.68,1.32), label=:none,
 ylabel="Slope coeff and conf int")
plot!(corr_confint_FD_VA.year, corr_confint_FD_VA.beta, color=:blue, lw=2, label=:none)

l = @layout [a ; b] # 2×2 layout
title = "Figure 5: FU/GO and VA/GO over time"
p_fig4 = plot(p1, p2, layout=l, plot_title=title, plot_titlefontsize=10)
savefig(p_fig3, "images/figure5.png") # export image to folder


# figure 6
p1 = @df corr_U_D plot(:year, :correlation, xlims=(1994,2012), ylims=(0.79,1.01),
 lw=2, color=:blue, label=:none, ylabel="Correlation: U on D")

p2 = @df corr_confint_U_D scatter(:year, [:beta, :lower, :upper], xlims=(1994,2012), ylims=(0.68,1.32), label=:none,
 ylabel="Slope coeff and conf int")
plot!(corr_confint_U_D.year, corr_confint_U_D.beta, color=:blue, lw=2, label=:none)

l = @layout [a ; b] # 2×2 layout
title = "Figure 6: U and D over time"
p_fig4 = plot(p1, p2, layout=l, plot_title=title, plot_titlefontsize=10)
savefig(p_fig3, "images/figure6.png") # export image to folder
