# MNCAH Kenya — Subnational Analysis Using DHS 2022

**Subnational Disparities in Maternal, Newborn, Child & Adolescent Health Indicators in Kenya**  
*A Kenya DHS 2022 Survey Analysis*

---

## Overview

This project uses the **Kenya Demographic and Health Survey (DHS) 2022** to compute and visualize subnational estimates of key **MNCAH (Maternal, Newborn, Child, and Adolescent Health)** indicators across all 47 counties of Kenya.

The analysis applies complex survey weighting methodology to produce statistically valid county-level estimates with confidence intervals, mirroring the methodology used by UNICEF and WHO for global MNCAH data products.

---

## Indicators Computed

### Maternal Health
| Indicator | Data Source |
|---|---|
| ANC 4+ coverage (%) | IR - Individual Recode |
| Skilled birth attendant at delivery (%) | IR |
| Postnatal care for mother within 2 days (%) | IR |
| Facility delivery (%) | IR |

### Child Health
| Indicator | Data Source |
|---|---|
| Full immunization coverage — children 12–23 months (%) | KR - Kids Recode |
| Stunting prevalence — HAZ < −2 SD (%) | KR |
| Wasting prevalence — WHZ < −2 SD (%) | KR |
| Diarrhea treatment with ORS (%) | KR |

### Adolescent Health
| Indicator | Data Source |
|---|---|
| Modern contraceptive use — women aged 15–19 (%) | IR |
| Adolescents who have begun childbearing (%) | IR |
| ANC 4+ among adolescents with a recent birth (%) | IR |

### Environmental / Household Health
| Indicator | Data Source |
|---|---|
| Improved drinking water source — JMP definition (%) | HR - Household Recode |
| Improved sanitation facility — JMP definition (%) | HR |
| Households with electricity access (%) | HR |

---

## Methodology

- **Survey design**: Complex sample survey with stratified multi-stage cluster sampling
- **Weighting**: All estimates are computed using DHS sample weights (`v005 / 1,000,000`) applied via the `srvyr` R package
- **Variance estimation**: Taylor linearization via the `survey` package, with confidence intervals reported at the 95% level
- **Anthropometric z-scores**: WHO 2006 Child Growth Standards
- **Water/sanitation classification**: WHO/UNICEF JMP (Joint Monitoring Programme) definitions
- **Geographic boundaries**: Kenya 47-county boundaries (2019 census delineation) from the `rKenyaCensus` R package

---

## Tools & Stack

| Tool | Purpose |
|---|---|
| **R** (`srvyr`, `survey`) | Survey-weighted analysis |
| **R** (`sf`, `ggplot2`, `patchwork`) | Choropleth mapping |
| **R** (`haven`, `tidyverse`) | Data cleaning & wrangling |
| **Power BI** | Interactive dashboard |
| **DHS Program data** | Source survey data |

---

## Project Structure

```
MNCAH_Kenya_DHS/
├── 01_setup_and_load.R      # Load & clean all DHS recode files
├── 02_compute_indicators.R  # Compute survey-weighted MNCAH indicators
├── 03_maps.R                # Generate choropleth maps & equity charts
├── outputs/
│   ├── powerbi/
│   │   └── MNCAH_Kenya_DHS_Indicators.xlsx   ← Power BI data source
│   ├── maps/
│   │   ├── 01_maternal_health_panel.png
│   │   ├── 02_child_health_panel.png
│   │   ├── 03_adolescent_environmental_panel.png
│   │   └── 04_equity_gap_chart.png
│   └── tables/
└── README.md
```

---

## How to Run

1. **Clone this repo**  
   ```bash
   git clone https://github.com/craigthompsonotieno/mncah-kenya-dhs.git
   cd mncah-kenya-dhs
   ```

2. **Download DHS Kenya 2022 data**  
   Register and request access at [dhsprogram.com](https://dhsprogram.com). Download the Stata (.dta) files for:
   - Individual Recode (IR)
   - Kids Recode (KR)
   - Household Recode (HR)
   - GPS data (GE)

3. **Update file path** in `01_setup_and_load.R`:
   ```r
   dhs_path <- "path/to/your/DHS/Kenya2022"
   ```

4. **Run scripts in order**:
   ```r
   source("01_setup_and_load.R")
   source("02_compute_indicators.R")
   source("03_maps.R")
   ```

5. **Open Power BI** and import `outputs/powerbi/MNCAH_Kenya_DHS_Indicators.xlsx`

---

## Key Findings

*(Update this section after running the analysis)*

- **ANC 4+**: National coverage of XX%, ranging from XX% (lowest county) to XX% (highest county)
- **Full immunization**: National coverage of XX%, with significant subnational variation
- **Stunting**: National prevalence of XX%, highest in XX and XX counties
- **Improved water**: XX% of households nationally, with stark urban-rural disparities

---

## Data Access

This analysis uses **Kenya DHS 2022** microdata. DHS datasets are publicly available but require registration at [dhsprogram.com](https://dhsprogram.com). Microdata are not included in this repository in compliance with DHS Program data use conditions.

---

## Author

**Craig Thompson Omondi Otieno**  
BSc Statistics, Jomo Kenyatta University of Agriculture and Technology  
[GitHub](https://github.com/craigthompsonotieno) | [LinkedIn](https://www.linkedin.com/in/craigthompsonotieno/)

---

## References

- Kenya National Bureau of Statistics (KNBS). *Kenya Demographic and Health Survey 2022*. Nairobi, Kenya.
- WHO/UNICEF Joint Monitoring Programme (JMP) for Water Supply, Sanitation and Hygiene.
- WHO Multicentre Growth Reference Study Group (2006). *WHO Child Growth Standards*.
- Lumley, T. (2020). *Complex Surveys: A Guide to Analysis Using R*. Wiley.
