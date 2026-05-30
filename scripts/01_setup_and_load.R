# =============================================================================
# MNCAH Kenya DHS Analysis — Script 1: Setup & Data Loading
# Author: Craig Thompson Otieno
# Data: Kenya DHS 2014 (KDHS 2014)
# Purpose: Load and clean all DHS recode files for MNCAH indicator analysis
# =============================================================================
rm(list = ls())
# 1. INSTALL & LOAD PACKAGES ----
packages <- c(
  "haven",       # Read Stata .dta files
  "tidyverse",   # Data manipulation & visualization
  "survey",      # Complex survey design
  "srvyr",       # Tidy survey analysis (survey + dplyr)
  "sf",          # Spatial data
  "janitor",     # Clean variable names
  "labelled",    # Handle labelled variables from Stata
  "writexl",     # Export to Excel for Power BI
  "scales",      # Formatting for plots
  "ggspatial",   # Spatial ggplot extensions
  "patchwork"    # Combine multiple ggplots
)

installed <- rownames(installed.packages())
to_install <- packages[!packages %in% installed]
if (length(to_install) > 0) install.packages(to_install)

invisible(lapply(packages, library, character.only = TRUE))


# 2. SET FILE PATHS ----
dhs_path <- "data"

output_path <- "Data/Clean"
dir.create(output_path, showWarnings = FALSE, recursive = TRUE)
dir.create(file.path(output_path, "tables"), showWarnings = FALSE)
dir.create(file.path(output_path, "maps"), showWarnings = FALSE)
dir.create(file.path(output_path, "powerbi"), showWarnings = FALSE)


# 3. DEFINE EXACT FILE PATHS ----
ir_file  <- file.path(dhs_path, "KEIR72FL.DTA")
kr_file  <- file.path(dhs_path, "KEKR72FL.DTA")
br_file  <- file.path(dhs_path, "KEBR72FL.DTA")
hr_file  <- file.path(dhs_path, "KEHR72FL.DTA")
gps_file <- file.path(dhs_path, "KEGE71FL.shp")
geo_file <- file.path(dhs_path, "KEGC72FL.csv") 



# 4. LOAD DATA ----

ir_raw <- read_dta(ir_file)

kr_raw <- read_dta(kr_file)

hr_raw <- read_dta(hr_file)

gps_sf <- st_read(gps_file, quiet = TRUE)

geo_cov <- read_csv(geo_file, show_col_types = FALSE)

# 5. CLEAN VARIABLE NAMES ----
ir_raw <- ir_raw %>% clean_names()
kr_raw <- kr_raw %>% clean_names()
hr_raw <- hr_raw %>% clean_names()
gps_sf <- gps_sf %>% clean_names()
geo_cov <- geo_cov %>% clean_names()

## 5.1. CLEAN COUNTY NAMES FUNCTION ----
# Removes leading dots/spaces, extra whitespace, and converts to Title Case
clean_county <- function(x) {
  x %>%
    as.character() %>%
    stringr::str_remove_all("^\\s*\\.+\\s*") %>%  # remove leading dots and spaces
    stringr::str_replace_all("\\s+", " ") %>%     # collapse multiple spaces
    stringr::str_trim() %>%                       # trim outer spaces
    stringr::str_to_title()                       # title case
}



# 6. EXTRACT COUNTY LABELS ----
# DHS Kenya 2014: scounty = county (47 counties), v025 = urban/rural
county_labels <- ir_raw %>%
  select(scounty) %>%
  mutate(
    county_code = as.numeric(scounty),
    county_name = clean_county(as_factor(scounty))
  ) %>%
  distinct() %>%
  arrange(county_code)



# Save county labels for use in other scripts
saveRDS(county_labels, file.path(output_path, "county_labels.rds"))

# 7. PREPARE CORE ANALYSIS COLUMNS ----

## 7.1. IR: Add core columns ----
ir <- ir_raw %>%
  mutate(
    weight    = v005 / 1e6,
    cluster   = v021,
    stratum   = v022,
    
    county_code = as.numeric(scounty),
    county_name = clean_county(as_factor(scounty)),
    residence   = as_factor(v025) %>% as.character(),
    
    age_woman = v012
  )

## 7.2 KR: Add core columns ----
kr <- kr_raw %>%
  mutate(
    weight      = v005 / 1e6,
    cluster     = v021,
    stratum     = v022,
    county_code = as.numeric(scounty),
    county_name = clean_county(as_factor(scounty)),
    residence   = as_factor(v025) %>% as.character(),
    child_age_months = hw1
  )

## 7.3. HR: Add core columns ----
hr <- hr_raw %>%
  mutate(
    weight      = hv005 / 1e6,
    cluster     = hv021,
    stratum     = hv022,
    county_code = as.numeric(shcounty),
    county_name = clean_county(as_factor(shcounty)),
    residence   = as_factor(hv025) %>% as.character()
  )

# 8. SAVE CLEANED DATASETS ----
saveRDS(ir,  file.path(output_path, "ir_clean.rds"))
saveRDS(kr,  file.path(output_path, "kr_clean.rds"))
saveRDS(hr,  file.path(output_path, "hr_clean.rds"))
saveRDS(gps_sf,  file.path(output_path, "gps_sf.rds"))
saveRDS(geo_cov, file.path(output_path, "geo_cov.rds"))


