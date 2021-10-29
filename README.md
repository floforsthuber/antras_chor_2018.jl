# Replication of *On the Measurement of Upstreamness and Downstreamness in Global Value Chains* by *Antras and Chor (2018)*

[![Build Status](https://github.com/forsthuber92/antras_chor_2018.jl/workflows/CI/badge.svg)](https://github.com/forsthuber92/antras_chor_2018.jl/actions)
[![Coverage](https://codecov.io/gh/forsthuber92/antras_chor_2018.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/forsthuber92/antras_chor_2018.jl)

The original paper *On the Measurement of Upstreamness and Downstreamness in Global Value Chains* was written by *Pol Antras and Davin Chor (2018)* and can 
be accessed [here](https://scholar.harvard.edu/files/antras/files/upstream_ac_29dec2017_withtables.pdf), with slides for the presentation of the paper are available [here](https://scholar.harvard.edu/files/antras/files/upstream_ac_slides_dec17.pdf).

The authors' files for replication can be accessed [here](https://scholar.harvard.edu/files/antras/files/upstream_ac_replication.zip).<br/>
The replication uses the STATA format available from WIOD [here](http://www.wiod.org/database/wiots13).<br/>
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

***Corresponds to table 2 on page 16:***
<br/>

------------------------------------------------------------------------------------------------------------------
                          FD_GO                     VA_GO                      U                       D          
                 -----------------------   -----------------------   ---------------------   ---------------------
                        (1)          (2)          (3)          (4)         (5)         (6)         (7)         (8)
------------------------------------------------------------------------------------------------------------------
year             -0.0008***                -0.0021***                0.0069***               0.0088***            
                    (0.000)                   (0.000)                  (0.001)                 (0.000)            
year: 1996                        0.0001                 -0.0024**                -0.0043*                 0.0039*
                                 (0.001)                   (0.001)                 (0.002)                 (0.002)
year: 1997                       -0.0014                -0.0036***                  0.0021                0.0064**
                                 (0.001)                   (0.001)                 (0.003)                 (0.002)
year: 1998                        0.0043                -0.0043***                 -0.0034                -0.0063*
                                 (0.002)                   (0.001)                 (0.007)                 (0.003)
year: 1999                        0.0087                -0.0062***                  0.0092                 -0.0014
                                 (0.005)                   (0.001)                 (0.012)                 (0.003)
year: 2000                       -0.0011                -0.0135***               0.0170***               0.0329***
                                 (0.002)                   (0.001)                 (0.005)                 (0.004)
year: 2001                       -0.0024                -0.0161***               0.0198***               0.0431***
                                 (0.002)                   (0.002)                 (0.006)                 (0.004)
year: 2002                       -0.0004                -0.0142***                 0.0131*               0.0262***
                                 (0.002)                   (0.002)                 (0.006)                 (0.004)
year: 2003                       -0.0016                -0.0150***               0.0263***               0.0378***
                                 (0.002)                   (0.002)                 (0.006)                 (0.004)
year: 2004                      -0.0056*                -0.0179***               0.0352***               0.0514***
                                 (0.003)                   (0.002)                 (0.007)                 (0.005)
year: 2005                       -0.0051                -0.0223***               0.0497***               0.0715***
                                 (0.003)                   (0.002)                 (0.007)                 (0.005)
year: 2006                     -0.0086**                -0.0267***               0.0662***               0.0972***
                                 (0.003)                   (0.002)                 (0.008)                 (0.005)
year: 2007                    -0.0122***                -0.0283***               0.0802***               0.1136***
                                 (0.003)                   (0.002)                 (0.007)                 (0.005)
year: 2008                    -0.0124***                -0.0326***               0.0975***               0.1379***
                                 (0.003)                   (0.002)                 (0.008)                 (0.006)
year: 2009                       -0.0026                -0.0273***               0.0734***               0.0869***
                                 (0.003)                   (0.002)                 (0.007)                 (0.006)
year: 2010                      -0.0067*                -0.0289***               0.0844***               0.1094***
                                 (0.003)                   (0.002)                 (0.008)                 (0.006)
year: 2011                     -0.0081**                -0.0295***               0.0912***               0.1163***
                                 (0.003)                   (0.002)                 (0.008)                 (0.006)
------------------------------------------------------------------------------------------------------------------
country_sector          Yes          Yes          Yes          Yes         Yes         Yes         Yes         Yes
------------------------------------------------------------------------------------------------------------------
Estimator               OLS          OLS          OLS          OLS         OLS         OLS         OLS         OLS
------------------------------------------------------------------------------------------------------------------
N                    24,076       24,076       24,076       24,076      24,076      24,076      24,076      24,076
R2                    0.941        0.941        0.954        0.954       0.923       0.924       0.945       0.946
------------------------------------------------------------------------------------------------------------------



# Final notes

All mistakes are my own.