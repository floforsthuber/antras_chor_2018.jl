# Replication of *On the Measurement of Upstreamness and Downstreamness in Global Value Chains* by *Antras and Chor (2018)*

[![Build Status](https://github.com/forsthuber92/antras_chor_2018.jl/workflows/CI/badge.svg)](https://github.com/forsthuber92/antras_chor_2018.jl/actions)
[![Coverage](https://codecov.io/gh/forsthuber92/antras_chor_2018.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/forsthuber92/antras_chor_2018.jl)

The original paper *On the Measurement of Upstreamness and Downstreamness in Global Value Chains* was written by *Pol Antras and Davin Chor (2018)* and can 
be accessed [here](https://scholar.harvard.edu/files/antras/files/upstream_ac_29dec2017_withtables.pdf), with slides for the presentation of the paper [here](https://scholar.harvard.edu/files/antras/files/upstream_ac_slides_dec17.pdf) and the authors' files for replication [here](https://scholar.harvard.edu/files/antras/files/upstream_ac_replication.zip).<br/>

The replication uses the STATA format available from WIOD [here](http://www.wiod.org/database/wiots13).<br/>
My own files are available via Google Drive.

All mistakes are my own.

# Results

***Corresponds to figure 2 on page 13:***
<br/>
![](https://raw.githubusercontent.com/forsthuber92/antras_chor_2018.jl/main/images/figure2.png)
<br/>

***Corresponds to figure 3 on page 14:***
<br/>
![](https://raw.githubusercontent.com/forsthuber92/antras_chor_2018.jl/main/images/figure3.png)
<br/>

***Spearman coefficients on page 15:***
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
<br/>


***Corresponds to table A.1 in the appendix:***
<br/>

<table>
  <thead>
    <tr class = "header headerLastRow">
      <th style = "text-align: right;">variable</th>
      <th style = "text-align: right;">sector_dummy</th>
      <th style = "text-align: right;">nrow</th>
      <th style = "text-align: right;">perc_10</th>
      <th style = "text-align: right;">median</th>
      <th style = "text-align: right;">perc_90</th>
      <th style = "text-align: right;">mean</th>
      <th style = "text-align: right;">std</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td style = "text-align: right;">D</td>
      <td style = "text-align: right;">all industries</td>
      <td style = "text-align: right;">24395</td>
      <td style = "text-align: right;">1.501</td>
      <td style = "text-align: right;">2.138</td>
      <td style = "text-align: right;">2.62</td>
      <td style = "text-align: right;">2.07597</td>
      <td style = "text-align: right;">0.492284</td>
    </tr>
    <tr>
      <td style = "text-align: right;">D</td>
      <td style = "text-align: right;">goods</td>
      <td style = "text-align: right;">11152</td>
      <td style = "text-align: right;">2.032</td>
      <td style = "text-align: right;">2.377</td>
      <td style = "text-align: right;">2.723</td>
      <td style = "text-align: right;">2.36839</td>
      <td style = "text-align: right;">0.339109</td>
    </tr>
    <tr>
      <td style = "text-align: right;">D</td>
      <td style = "text-align: right;">services</td>
      <td style = "text-align: right;">13243</td>
      <td style = "text-align: right;">1.3552</td>
      <td style = "text-align: right;">1.844</td>
      <td style = "text-align: right;">2.3598</td>
      <td style = "text-align: right;">1.82972</td>
      <td style = "text-align: right;">0.465776</td>
    </tr>
    <tr>
      <td style = "text-align: right;">FD_GO</td>
      <td style = "text-align: right;">all industries</td>
      <td style = "text-align: right;">24395</td>
      <td style = "text-align: right;">0.113</td>
      <td style = "text-align: right;">0.437</td>
      <td style = "text-align: right;">0.902</td>
      <td style = "text-align: right;">0.465831</td>
      <td style = "text-align: right;">0.279695</td>
    </tr>
    <tr>
      <td style = "text-align: right;">FD_GO</td>
      <td style = "text-align: right;">goods</td>
      <td style = "text-align: right;">11152</td>
      <td style = "text-align: right;">0.072</td>
      <td style = "text-align: right;">0.365</td>
      <td style = "text-align: right;">0.699</td>
      <td style = "text-align: right;">0.376289</td>
      <td style = "text-align: right;">0.253111</td>
    </tr>
    <tr>
      <td style = "text-align: right;">FD_GO</td>
      <td style = "text-align: right;">services</td>
      <td style = "text-align: right;">13243</td>
      <td style = "text-align: right;">0.1962</td>
      <td style = "text-align: right;">0.486</td>
      <td style = "text-align: right;">0.955</td>
      <td style = "text-align: right;">0.541236</td>
      <td style = "text-align: right;">0.278791</td>
    </tr>
    <tr>
      <td style = "text-align: right;">U</td>
      <td style = "text-align: right;">all industries</td>
      <td style = "text-align: right;">24395</td>
      <td style = "text-align: right;">1.149</td>
      <td style = "text-align: right;">2.116</td>
      <td style = "text-align: right;">2.907</td>
      <td style = "text-align: right;">2.07971</td>
      <td style = "text-align: right;">0.692448</td>
    </tr>
    <tr>
      <td style = "text-align: right;">U</td>
      <td style = "text-align: right;">goods</td>
      <td style = "text-align: right;">11152</td>
      <td style = "text-align: right;">1.51</td>
      <td style = "text-align: right;">2.282</td>
      <td style = "text-align: right;">3.049</td>
      <td style = "text-align: right;">2.27794</td>
      <td style = "text-align: right;">0.650891</td>
    </tr>
    <tr>
      <td style = "text-align: right;">U</td>
      <td style = "text-align: right;">services</td>
      <td style = "text-align: right;">13243</td>
      <td style = "text-align: right;">1.055</td>
      <td style = "text-align: right;">1.98</td>
      <td style = "text-align: right;">2.765</td>
      <td style = "text-align: right;">1.91278</td>
      <td style = "text-align: right;">0.682326</td>
    </tr>
    <tr>
      <td style = "text-align: right;">VA_GO</td>
      <td style = "text-align: right;">all industries</td>
      <td style = "text-align: right;">24395</td>
      <td style = "text-align: right;">0.239</td>
      <td style = "text-align: right;">0.419</td>
      <td style = "text-align: right;">0.71</td>
      <td style = "text-align: right;">0.449917</td>
      <td style = "text-align: right;">0.192906</td>
    </tr>
    <tr>
      <td style = "text-align: right;">VA_GO</td>
      <td style = "text-align: right;">goods</td>
      <td style = "text-align: right;">11152</td>
      <td style = "text-align: right;">0.21</td>
      <td style = "text-align: right;">0.331</td>
      <td style = "text-align: right;">0.462</td>
      <td style = "text-align: right;">0.336078</td>
      <td style = "text-align: right;">0.117965</td>
    </tr>
    <tr>
      <td style = "text-align: right;">VA_GO</td>
      <td style = "text-align: right;">services</td>
      <td style = "text-align: right;">13243</td>
      <td style = "text-align: right;">0.324</td>
      <td style = "text-align: right;">0.546</td>
      <td style = "text-align: right;">0.772</td>
      <td style = "text-align: right;">0.545781</td>
      <td style = "text-align: right;">0.191647</td>
    </tr>
  </tbody>
</table>


***Corresponds to table 2 on page 16:***
<br/>
![](https://raw.githubusercontent.com/forsthuber92/antras_chor_2018.jl/main/images/table2.png)
<br/>

***Corresponds to figure 4 on page 17:***
<br/>
![](https://raw.githubusercontent.com/forsthuber92/antras_chor_2018.jl/main/images/figure4.png)
<br/>

***Corresponds to figure 5 on page 18:***
<br/>
![](https://raw.githubusercontent.com/forsthuber92/antras_chor_2018.jl/main/images/figure5.png)
<br/>

***Corresponds to figure 6 on page 19:***
<br/>
![](https://raw.githubusercontent.com/forsthuber92/antras_chor_2018.jl/main/images/figure6.png)
<br/>

***Corresponds to table 6 on page 19:***
<br/>
![](https://raw.githubusercontent.com/forsthuber92/antras_chor_2018.jl/main/images/table3.png)
<br/>

***Corresponds to figure 7 on page 22:***
<br/>
![](https://raw.githubusercontent.com/forsthuber92/antras_chor_2018.jl/main/images/table3.png)
<br/>

