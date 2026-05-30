# MNCAH Kenya — Subnational Analysis Using DHS 2014

> Subnational disparities in Maternal, Newborn, Child & Adolescent Health indicators across all 47 counties of Kenya, derived from the Kenya Demographic and Health Survey (DHS) 2014.

---

## Overview

This project applies complex survey methodology to the **Kenya DHS 2014** microdata to produce county-level estimates of key MNCAH indicators with 95% confidence intervals. The approach mirrors the methodology used by UNICEF and WHO for global MNCAH data products, making outputs directly comparable to international benchmarks.

A fourth script enriches the county-level results with **DHS geocovariates** (cluster-level environmental and contextual variables), enabling correlation analysis between health indicators and geographic/contextual factors. Final outputs feed into a **Power BI** dashboard for interactive exploration.

---

## Indicators

### Maternal Health
| Indicator | DHS Variable | Source |
|---|---|---|
| ANC 4+ visits | `m14_1 >= 4` | IR — Individual Recode |
| Skilled birth attendant at delivery | `m3a_1`, `m3b_1`, `m3c_1` | IR |
| Postnatal care for mother within 2 days | `m62_1 ∈ {1–4}` | IR |
| Facility delivery | `m15_1 ∈ {20–89}` | IR |

### Child Health
| Indicator | DHS Variable | Source |
|---|---|---|
| Full immunization coverage (12–23 months) | `h2`, `h3`, `h4`, `h5`, `h6`, `h7`, `h8`, `h9` | KR — Kids Recode |
| Stunting prevalence (HAZ < −2 SD) | `hw70 < -200` | KR |
| Wasting prevalence (WHZ < −2 SD) | `hw72 < -200` | KR |
| Diarrhea treatment with ORS | `h11 == 1`, `h13 == 1` | KR |

### Adolescent Health
| Indicator | DHS Variable | Source |
|---|---|---|
| Modern contraceptive use (women 15–19) | `v313 == 3` | IR |
| Adolescents who have begun childbearing | `v201 >= 1` | IR |
| ANC 4+ among adolescents with a recent birth | `m14_1 >= 4` (subset: 15–19) | IR |

### Household & Environmental Health
| Indicator | DHS Variable | Source |
|---|---|---|
| Improved drinking water source (JMP) | `hv201 ∈ {11,12,13,21,31,41,51,61,71,72}` | HR — Household Recode |
| Improved sanitation facility (JMP) | `hv205 ∈ {11–15,21,22,23}` | HR |
| Households with electricity | `hv206 == 1` | HR |

---

## Methodology

- **Survey design**: Stratified multi-stage cluster sampling
- **Weighting**: DHS sample weights (`v005 / 1,000,000`) applied via the `srvyr` package
- **Variance estimation**: Taylor linearization (95% confidence intervals); singleton PSUs handled with `options(survey.lonely.psu = "adjust")`
- **Anthropometric z-scores**: WHO 2006 Child Growth Standards (`hw70`, `hw72`)
- **Water/sanitation classification**: WHO/UNICEF JMP definitions
- **Geographic boundaries**: Kenya GADM Level 1 county polygons via the `geodata` package
- **Geocovariates**: DHS cluster-level contextual variables from `KEGC72FL.csv`, aggregated to county level as cluster means

---

## Project Structure

```
MNCAH_Kenya_DHS/
├── scripts/
│   ├── 01_setup_and_load.R          # Load & clean DHS recode files (IR, KR, HR, GPS)
│   ├── 02_compute_indicators.R      # Compute survey-weighted MNCAH indicators
│   ├── 03_maps.R                    # Choropleth maps & equity gap charts
│   └── 04_geocovariates_merge.R     # Merge DHS geocovariates; correlation analysis
├── data/                            # DHS microdata (gitignored)
│   ├── KEIR72FL.DTA                 # Individual Recode
│   ├── KEKR72FL.DTA                 # Kids Recode
│   ├── KEHR72FL.DTA                 # Household Recode
│   ├── KEGE71FL.shp                 # GPS cluster shapefile
│   └── KEGC72FL.csv                 # Geocovariates file
├── Data/Clean/                      # Intermediate outputs (gitignored)
│   ├── powerbi/
│   │   ├── MNCAH_Kenya_DHS_Indicators.xlsx
│   │   └── MNCAH_Kenya_DHS_Indicators_With_Geocovariates.xlsx   ← Power BI source
│   ├── maps/
│   │   ├── 01_maternal_health_panel.png
│   │   ├── 02_child_health_panel.png
│   │   ├── 03_adolescent_environmental_panel.png
│   │   └── 04_equity_gap_chart.png
│   └── tables/
├── MNCAH_Kenya_DHS.Rproj
├── .gitignore
└── README.md
```

---

## Getting Started

### Prerequisites

All packages are auto-installed by Script 1, but you can install them manually:

```r
install.packages(c(
  "haven", "tidyverse", "survey", "srvyr",
  "sf", "janitor", "labelled", "writexl",
  "scales", "ggspatial", "patchwork",
  "geodata", "terra"
))
```

### Data Access

This project uses Kenya DHS 2014 microdata. DHS datasets are free but require registration:

1. Register at [dhsprogram.com](https://dhsprogram.com)
2. Request access to the **Kenya 2014 (KDHS 2014)** survey
3. Download the Stata (`.dta`) files for IR, KR, HR, and the GPS/geocovariates files
4. Place all files in the `data/` folder

Microdata are **not included** in this repository in compliance with DHS Program data use conditions.

### Running the Analysis

1. Clone the repo:

```bash
git clone https://github.com/craigthompsonotieno/MNCAH_Kenya_DHS.git
cd MNCAH_Kenya_DHS
```

2. Open `MNCAH_Kenya_DHS.Rproj` in RStudio

3. Run scripts in order:

```r
source("scripts/01_setup_and_load.R")       # Loads and cleans all DHS files
source("scripts/02_compute_indicators.R")   # Computes all MNCAH indicators
source("scripts/03_maps.R")                 # Generates choropleth maps
source("scripts/04_geocovariates_merge.R")  # Merges geocovariates for Power BI
```

4. Open Power BI and import:
   `Data/Clean/powerbi/MNCAH_Kenya_DHS_Indicators_With_Geocovariates.xlsx`

---

## Outputs

| File | Description |
|---|---|
| `MNCAH_Kenya_DHS_Indicators.xlsx` | All indicators — long, wide, and national summary sheets |
| `MNCAH_Kenya_DHS_Indicators_With_Geocovariates.xlsx` | Enriched with geocovariates + correlation table — **Power BI source** |
| `01_maternal_health_panel.png` | ANC, SBA, PNC, facility delivery maps |
| `02_child_health_panel.png` | Immunization, stunting, wasting maps |
| `03_adolescent_environmental_panel.png` | Adolescent & WASH maps |
| `04_equity_gap_chart.png` | Top 5 vs bottom 5 counties across key indicators |

---

## Tools & Stack

| Tool | Purpose |
|---|---|
| R (`srvyr`, `survey`) | Survey-weighted analysis |
| R (`sf`, `ggplot2`, `patchwork`, `geodata`) | Choropleth mapping |
| R (`haven`, `tidyverse`, `janitor`) | Data cleaning & wrangling |
| R (`writexl`) | Excel export for Power BI |
| Power BI | Interactive dashboard |

---

## References

- Kenya National Bureau of Statistics (KNBS). *Kenya Demographic and Health Survey 2014*. Nairobi, Kenya.
- WHO/UNICEF Joint Monitoring Programme (JMP) for Water Supply, Sanitation and Hygiene.
- WHO Multicentre Growth Reference Study Group (2006). *WHO Child Growth Standards*.
- Lumley, T. (2020). *Complex Surveys: A Guide to Analysis Using R*. Wiley.

---

## Author

**Craig Thompson Omondi Otieno**  
[GitHub](https://github.com/craigthompsonotieno) · [LinkedIn](https://www.linkedin.com/in/craigthompsonotieno/)
