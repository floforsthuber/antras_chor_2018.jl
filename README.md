# Replication of *On the Measurement of Upstreamness and Downstreamness in Global Value Chains* by *Antras and Chor (2018)*

[![Build Status](https://github.com/forsthuber92/antras_chor_2018.jl/workflows/CI/badge.svg)](https://github.com/forsthuber92/antras_chor_2018.jl/actions)
[![Coverage](https://codecov.io/gh/forsthuber92/antras_chor_2018.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/forsthuber92/antras_chor_2018.jl)

The original paper *On the Measurement of Upstreamness and Downstreamness in Global Value Chains* was written by *Pol Antras and Davin Chor (2018)* and can 
be accessed [here](https://scholar.harvard.edu/files/antras/files/upstream_ac_29dec2017_withtables.pdf), with slides for the presentation of the paper are available [here](https://scholar.harvard.edu/files/antras/files/upstream_ac_slides_dec17.pdf).

The authors' files for replication can be accessed [here](https://scholar.harvard.edu/files/antras/files/upstream_ac_replication.zip).
The replication uses the STATA format produced by WIOD and accessible [here](http://www.wiod.org/database/wiots13).
My own files are available via Google Drive. 

# Results

***Corresponds to figure 2 on page 13:***
<br/>
![](https://raw.githubusercontent.com/forsthuber92/antras_chor_2018.jl/main/images/figure2.png)
<br/>

***Corresponds to figure 3 on page 14:***
<br/>
![](https://raw.githubusercontent.com/forsthuber92/antras_chor_2018.jl/main/images/figure3.png)
<br/>

***Spearman coefficients on page 14:***
<br/>
<table>
  <thead>
    <tr class = "header headerLastRow">
      <th style = "text-align: right;">year_base</th>
      <th style = "text-align: right;">year_comp</th>
      <th style = "text-align: right;">measure</th>
      <th style = "text-align: right;">value</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td style = "text-align: right;">1995</td>
      <td style = "text-align: right;">2011</td>
      <td style = "text-align: right;">D</td>
      <td style = "text-align: right;">0.749</td>
    </tr>
    <tr>
      <td style = "text-align: right;">1995</td>
      <td style = "text-align: right;">2011</td>
      <td style = "text-align: right;">FD_GO</td>
      <td style = "text-align: right;">0.799</td>
    </tr>
    <tr>
      <td style = "text-align: right;">1995</td>
      <td style = "text-align: right;">2011</td>
      <td style = "text-align: right;">U</td>
      <td style = "text-align: right;">0.803</td>
    </tr>
    <tr>
      <td style = "text-align: right;">1995</td>
      <td style = "text-align: right;">2011</td>
      <td style = "text-align: right;">VA_GO</td>
      <td style = "text-align: right;">0.783</td>
    </tr>
  </tbody>
</table>



# Final notes

All mistakes are my own.