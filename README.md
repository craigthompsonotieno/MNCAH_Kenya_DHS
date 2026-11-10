
# MNCAH Kenya — Subnational Analysis Using DHS 2014

**Survey-weighted analysis of Maternal, Newborn, Child & Adolescent Health (MNCAH) indicators across Kenya's 47 counties.**

**Tools:** R | DHS Survey Data | Statistical Analysis | GIS | Power BI

---

## Overview

Maternal, newborn, child, and adolescent health outcomes vary considerably across Kenya's 47 counties. Understanding these disparities is essential for identifying underserved populations, targeting interventions, and supporting evidence-based healthcare decisions.

This project analyzes the **Kenya Demographic and Health Survey (KDHS) 2014** to examine subnational inequalities in maternal healthcare, child health, adolescent reproductive health, and household environmental conditions.

Using R and complex survey analysis techniques, the project produces survey-weighted county-level estimates with 95% confidence intervals.

The analysis also integrates geographic information and DHS geocovariates to explore relationships between health indicators and contextual factors.

An interactive Power BI dashboard presents the findings through county rankings, indicator comparisons, equity-gap analyses, geographic visualizations, and individual county profiles.

Beyond descriptive statistics, this project demonstrates how survey data can be transformed into useful evidence for public health research, programme monitoring, and development planning.

---

## Research Objectives

1. Estimate key maternal, child, adolescent, and household health indicators across Kenya's 47 counties.
2. Identify geographic inequalities in healthcare access and health outcomes.
3. Apply complex survey methods to produce statistically appropriate estimates and confidence intervals.
4. Examine contextual and geographic factors associated with health indicators.
5. Develop accessible dashboards that support evidence-based planning and programme monitoring.
6. Demonstrate a reproducible analytical workflow using R, GIS, and Power BI.

---

## Key Findings and Insights

### 1. Significant Geographic Inequalities in Childhood Immunization

The analysis reveals substantial county-level variation in full immunization coverage among children aged 12–23 months.

For example:

- **Nandi County:** 93.9%
- **Mandera County:** 28.5%
- **Coverage gap:** 65.4 percentage points

These findings demonstrate that national averages can conceal substantial regional inequalities.

Counties with lower coverage may require further investigation into healthcare accessibility, service delivery, infrastructure, and other potential barriers.

The results can help inform discussions about where additional assessments or targeted interventions may be necessary.

### 2. Child Malnutrition Remains an Important Health Concern

The dashboard reports the following estimates:

- **Stunting prevalence:** 26.0%
- **Wasting prevalence:** 5.1%

Stunting reflects long-term nutritional disadvantage, while wasting is associated with acute undernutrition.

Understanding these differences is important for designing appropriate nutrition-related interventions.

The county-level estimates also help identify areas where nutritional outcomes warrant further investigation.

### 3. Household Environmental Conditions Vary Across Counties

The analysis examines environmental conditions associated with health and well-being, including:

- Improved drinking water access
- Improved sanitation facilities
- Household electricity access

The dashboard reports improved drinking water coverage of approximately **65.7%**, while the Baringo County profile shows **38.8%**.

This illustrates the importance of geographic disaggregation when assessing household infrastructure and development inequalities.

Such findings may help development organizations identify areas requiring closer investigation.

### 4. Subnational Analysis Reveals Disparities Hidden by National Averages

National-level statistics provide an overall picture of development outcomes but can conceal substantial differences across geographic areas.

By estimating indicators across all 47 counties, this project provides a more detailed understanding of health inequalities.

The combination of survey-weighted estimates, confidence intervals, county rankings, and geographic visualizations supports more informed interpretation of these differences.

---

## Potential Applications and Impact

This project demonstrates how rigorous statistical analysis and data visualization can support decision-making in public health and development.

### For Policymakers and County Governments

The county-level comparisons can help:

- Identify geographic inequalities in health outcomes.
- Highlight areas that may require further assessment.
- Inform healthcare planning and resource-allocation discussions.
- Support evidence-based county development strategies.
- Monitor disparities using consistently defined indicators.

The analysis identifies differences between counties but does not establish their underlying causes.

### For NGOs and Development Organizations

Organizations working in public health, nutrition, WASH, and community development can use the analytical approach to:

- Support programme needs assessments.
- Identify historically underserved counties.
- Establish contextual baselines for research.
- Develop monitoring and evaluation indicators.
- Inform discussions about programme priorities.
- Identify questions requiring further field investigation.

### For Researchers and Students

The repository provides a reproducible workflow demonstrating:

- DHS data preparation and cleaning.
- Complex survey weighting.
- County-level statistical estimation.
- Confidence interval calculation.
- Geospatial data integration.
- Geographic inequality analysis.
- Automated reporting and visualization.

Researchers can adapt the workflow to other DHS datasets, subject to survey-specific methodology, variable definitions, and data-access conditions.

### For Monitoring, Evaluation and Learning Professionals

The project demonstrates how complex household survey datasets can be transformed into accessible analytical products.

Its methodology can support:

- Indicator development and standardization.
- Geographic performance comparisons.
- Data quality assurance.
- Evidence synthesis.
- Programme learning.
- Stakeholder reporting.
- Identification of research and monitoring priorities.

### For Data Analysts and Developers

The project demonstrates an end-to-end analytical workflow connecting R, spatial analysis, Excel exports, and Power BI.

This approach can be adapted to other development datasets requiring data cleaning, indicator calculation, regional comparisons, and interactive reporting.

---

## Indicators

### Maternal Health

| Indicator | DHS Variables | Source |
|---|---|---|
| ANC 4+ visits | `m14_1 >= 4` | IR |
| Skilled birth attendant | `m3a_1`, `m3b_1`, `m3c_1` | IR |
| Postnatal care for mother within 2 days | `m50_1`, `m51_1`, `m52_1`; recent birth eligibility | IR |
| Facility delivery | `m15_1` | IR |

**Postnatal care methodology note:**

The original implementation incorrectly interpreted `m62_1` as the timing of postnatal care, resulting in artificial 100% estimates.

The revised calculation uses:

- `m50_1`: Whether the mother received a post-delivery check.
- `m51_1`: Timing of the post-delivery check.
- `m52_1`: Provider who performed the check.

The revised diagnostic produced a preliminary survey-weighted national estimate of **53.07%**, with a 95% confidence interval of **50.53%–55.60%**.

This result is provisional until the final indicator definition, eligibility rules, and survey design are fully validated.

### Child Health

| Indicator | DHS Variables | Source |
|---|---|---|
| Full immunization coverage (12–23 months) | `h2`, `h3`, `h4`, `h5`, `h6`, `h7`, `h8`, `h9` | KR |
| Stunting prevalence | `hw70` | KR |
| Wasting prevalence | `hw72` | KR |
| Diarrhea treatment with ORS | `h11`, `h13` | KR |

### Adolescent Health

| Indicator | DHS Variables | Source |
|---|---|---|
| Modern contraceptive use (15–19 years) | `v313` | IR |
| Adolescents who have begun childbearing | `v201` | IR |
| ANC 4+ among adolescents with a recent birth | `m14_1` | IR |

### Household and Environmental Health

| Indicator | DHS Variables | Source |
|---|---|---|
| Improved drinking water source | `hv201` | HR |
| Improved sanitation facility | `hv205` | HR |
| Household electricity access | `hv206` | HR |

---

## Methodology

### Data Sources

The analysis uses the Kenya Demographic and Health Survey 2014 datasets:

- Individual Recode (IR)
- Kids Recode (KR)
- Household Recode (HR)
- DHS geographic information
- DHS geocovariates

### Survey Design

The analysis accounts for the stratified, multistage cluster sampling design used by the DHS.

Survey estimates are calculated using the R `survey` and `srvyr` packages.

Key methodological components include:

- DHS sampling weights (`v005 / 1,000,000` for women's data).
- Primary sampling units and sampling strata.
- Survey-weighted proportions.
- Taylor linearization for variance estimation.
- 95% confidence intervals.
- National and county-level disaggregation.
- Appropriate handling of missing data.

Indicator-specific denominators and weight variables require validation against DHS documentation.

### Geospatial Analysis

County-level results are integrated with geographic boundary data to develop choropleth maps and visualize spatial inequalities.

The workflow uses R packages including:

- `sf`
- `ggplot2`
- `geodata`
- `terra`
- `patchwork`

### Geocovariate Integration

A fourth analysis script incorporates DHS cluster-level contextual variables from `KEGC72FL.csv`.

These variables are aggregated to county level and merged with the health indicator outputs to support exploratory correlation analysis.

Correlations are interpreted as descriptive associations rather than evidence of causation.

### Data Visualization

Power BI is used to develop an interactive dashboard featuring:

- National indicator summaries.
- Maternal health indicators.
- Child health indicators.
- Adolescent and environmental health indicators.
- Geographic comparisons.
- County rankings.
- Equity-gap analysis.
- County-level drill-down profiles.

---

## Project Structure

```text
MNCAH_Kenya_DHS/
|
|-- scripts/
|   |-- 01_setup_and_load.R
|   |-- 02_compute_indicators.R
|   |-- 03_maps.R
|   `-- 04_geocovariates_merge.R
|
|-- data/
|   `-- Restricted DHS datasets (gitignored)
|
|-- Data/
|   `-- Clean/
|       |-- powerbi/
|       |-- maps/
|       `-- tables/
|
|-- MNCAH_Kenya_DHS.Rproj
|-- .gitignore
|-- README.md
`-- LICENSE
```

---

## Getting Started

### Prerequisites

Install the required R packages:

```r
install.packages(c(
  "haven",
  "tidyverse",
  "survey",
  "srvyr",
  "sf",
  "janitor",
  "labelled",
  "writexl",
  "scales",
  "ggspatial",
  "patchwork",
  "geodata",
  "terra"
))
```

### Data Access

The project uses restricted Kenya DHS 2014 microdata.

To reproduce the analysis:

1. Visit https://dhsprogram.com/
2. Register or sign in to your DHS account.
3. Request authorization to access the Kenya DHS 2014 datasets.
4. Download the required Stata recode and geographic datasets.
5. Place the files in the project's `data/` directory.

The restricted microdata are not included in this repository.

### Running the Analysis

Clone the repository:

```bash
git clone https://github.com/craigthompsonotieno/MNCAH_Kenya_DHS.git
cd MNCAH_Kenya_DHS
```

Open the RStudio project and execute the scripts sequentially:

```r
source("scripts/01_setup_and_load.R")
source("scripts/02_compute_indicators.R")
source("scripts/03_maps.R")
source("scripts/04_geocovariates_merge.R")
```

Note: File and folder capitalization must match your local repository, especially on case-sensitive operating systems.

---

## Outputs

| Output | Description |
|---|---|
| `MNCAH_Kenya_DHS_Indicators.xlsx` | Survey-weighted national and county indicators |
| `MNCAH_Kenya_DHS_Indicators_With_Geocovariates.xlsx` | Health indicators enriched with contextual variables |
| `01_maternal_health_panel.png` | Maternal health maps |
| `02_child_health_panel.png` | Child health maps |
| `03_adolescent_environmental_panel.png` | Adolescent and environmental indicators |
| `04_equity_gap_chart.png` | County-level inequality comparisons |

The enriched Excel output is intended for integration with the Power BI dashboard.

---

## Tools and Technologies

| Tool | Application |
|---|---|
| R | Statistical analysis and automation |
| `survey` / `srvyr` | Complex survey estimation |
| `tidyverse` | Data cleaning and transformation |
| `haven` | Importing DHS Stata files |
| `sf` / `geodata` | Geographic analysis |
| `ggplot2` | Statistical visualization |
| `writexl` | Excel reporting outputs |
| Power BI | Interactive analytical dashboard |

---

## Limitations and Responsible Interpretation

This analysis uses Kenya DHS 2014 data and describes historical conditions, not Kenya's current health outcomes.

Important limitations include:

- Sampling uncertainty in county-level estimates.
- Potentially small sample sizes for certain subgroups.
- Differences in eligibility populations across indicators.
- Missing or incomplete survey responses.
- The need to validate indicator definitions against official DHS guidance.
- The observational nature of the data.

Differences between counties should not automatically be interpreted as statistically significant.

Similarly, correlations between geographic variables and health indicators do not establish causal relationships.

Findings should be interpreted alongside official statistics, more recent evidence, and relevant local context.

---

## References

1. Kenya National Bureau of Statistics (KNBS). *Kenya Demographic and Health Survey 2014*.
2. The DHS Program. *Guide to DHS Statistics*.
3. WHO/UNICEF Joint Monitoring Programme for Water Supply, Sanitation and Hygiene.
4. WHO Multicentre Growth Reference Study Group (2006). *WHO Child Growth Standards*.
5. Lumley, T. (2020). *Complex Surveys: A Guide to Analysis Using R*. Wiley.

---

## Author

**Craig Thompson Omondi Otieno**

Statistician | Data Analyst | Survey Research | Development Analytics

- GitHub: https://github.com/craigthompsonotieno
- LinkedIn: https://www.linkedin.com/in/craigthompsonotieno/
- Portfolio: https://craig-data-portfolio.vercel.app/

---

## License and Data Use

### Source Code

The original scripts and documentation are licensed under the MIT License, subject to the terms in the repository's `LICENSE` file.

Copyright (c) 2026 Craig Thompson Omondi Otieno.

### DHS Data

The MIT License does not apply to DHS microdata, geographic datasets, questionnaires, reports, or other third-party materials.

Users must independently obtain the necessary authorization from The DHS Program and comply with its data-use requirements.

### Disclaimer

This is an independent analytical portfolio project and is not an official publication of The DHS Program, KNBS, WHO, UNICEF, or any other referenced institution.
