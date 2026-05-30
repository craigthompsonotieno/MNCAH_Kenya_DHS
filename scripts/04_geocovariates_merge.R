# =============================================================================
# MNCAH Kenya DHS Analysis — Script 4: GeoCovariates Integration
# Author: Craig Thompson Otieno
# Purpose: Add DHS geocovariates to county-level MNCAH indicator outputs
# =============================================================================

library(tidyverse)
library(janitor)
library(writexl)

# 0. PATHS ----
output_path <- "Data/Clean"

dir.create(file.path(output_path, "powerbi"), showWarnings = FALSE, recursive = TRUE)
dir.create(file.path(output_path, "tables"),  showWarnings = FALSE, recursive = TRUE)

# 1. LOAD EXISTING OUTPUTS FROM SCRIPTS 1–2 ----
geo_cov        <- readRDS(file.path(output_path, "geo_cov.rds"))
all_indicators <- readRDS(file.path(output_path, "all_indicators.rds"))
wide_indicators <- readRDS(file.path(output_path, "wide_indicators.rds"))


# 2. CLEAN NAMES AGAIN JUST IN CASE ----
geo_cov <- geo_cov %>% clean_names()

cat("\nColumns in geocovariates file:\n")
print(names(geo_cov))

# 3. DETECT CLUSTER ID COLUMN ----
# DHS geocovariates files usually have a cluster number column.
# This makes the code flexible in case the exact column name differs.
possible_cluster_cols <- c(
  "dhsclust", "dhs_cluster", "cluster", "cluster_number",
  "v001", "hv001", "caseid"
)

cluster_col <- possible_cluster_cols[possible_cluster_cols %in% names(geo_cov)][1]

if (is.na(cluster_col)) {
  stop(
    "No cluster ID column found in geo_cov. Check column names printed above and add the correct one to possible_cluster_cols."
  )
}


# 4. LOAD CLEAN DHS DATA TO GET COUNTY-CLUSTER LINK ----
# We use household data because it has county + cluster for all sampled households.
hr <- readRDS(file.path(output_path, "hr_clean.rds"))

county_cluster_lookup <- hr %>%
  select(cluster, county_code, county_name, residence) %>%
  distinct() %>%
  mutate(cluster = as.numeric(cluster))

cat("✓ Created county-cluster lookup from HR file\n")

# 5. PREPARE GEOCOVARIATES CLUSTER DATA ----
geo_cluster <- geo_cov %>%
  mutate(cluster = as.numeric(.data[[cluster_col]]))

# 6. MERGE GEOCOVARIATES TO COUNTY LOOKUP ----
geo_county_raw <- county_cluster_lookup %>%
  left_join(geo_cluster, by = "cluster")

unmatched_clusters <- geo_county_raw %>%
  filter(if_all(everything(), ~ is.na(.x)) | is.na(county_name))


# 7. SELECT NUMERIC GEOCOVARIATE COLUMNS ----
# Exclude county/cluster identifiers, then summarize numeric variables by county.
id_cols <- c(
  "cluster", "county_code", "county_name", "residence",
  cluster_col
)

numeric_geo_cols <- geo_county_raw %>%
  select(where(is.numeric)) %>%
  select(-any_of(c("cluster", "county_code"))) %>%
  names()


if (length(numeric_geo_cols) == 0) {
  stop("No numeric geocovariate columns found after merging. Inspect geo_cov column types.")
}

# 8. COUNTY-LEVEL GEOCOVARIATE SUMMARY ----
county_geocovariates <- geo_county_raw %>%
  group_by(county_code, county_name) %>%
  summarise(
    n_clusters_with_geocov = n_distinct(cluster[!is.na(cluster)]),
    across(
      all_of(numeric_geo_cols),
      ~ round(mean(.x, na.rm = TRUE), 3),
      .names = "mean_{.col}"
    ),
    .groups = "drop"
  ) %>%
  mutate(
    across(
      starts_with("mean_"),
      ~ ifelse(is.nan(.x), NA_real_, .x)
    )
  )


# 9. CREATE LONG FORMAT FOR POWER BI ----
# This is useful for correlation charts and slicers in Power BI.
county_geocovariates_long <- county_geocovariates %>%
  pivot_longer(
    cols = starts_with("mean_"),
    names_to = "geocovariate",
    values_to = "geocovariate_value"
  ) %>%
  mutate(
    geocovariate = str_remove(geocovariate, "^mean_"),
    geocovariate_label = geocovariate %>%
      str_replace_all("_", " ") %>%
      str_to_title()
  )

# 10. ENRICH EXISTING INDICATOR TABLES ----
# 10.1 Long indicator table + geocovariates
indicators_with_geocov_long <- all_indicators %>%
  filter(county_name != "NATIONAL") %>%
  left_join(county_geocovariates, by = c("county_code", "county_name"))

# 10.2 Wide county indicator table + geocovariates
county_dashboard_wide <- wide_indicators %>%
  left_join(county_geocovariates, by = c("county_code", "county_name"))

# 11. SIMPLE CORRELATION TABLE ----
# Correlates each health indicator with each numeric geocovariate.
correlation_data <- indicators_with_geocov_long %>%
  select(county_code, county_name, indicator, estimate, starts_with("mean_")) %>%
  pivot_longer(
    cols = starts_with("mean_"),
    names_to = "geocovariate",
    values_to = "geocovariate_value"
  ) %>%
  group_by(indicator, geocovariate) %>%
  summarise(
    correlation = round(cor(estimate, geocovariate_value, use = "complete.obs"), 3),
    n_counties = sum(!is.na(estimate) & !is.na(geocovariate_value)),
    .groups = "drop"
  ) %>%
  mutate(
    geocovariate = str_remove(geocovariate, "^mean_"),
    geocovariate_label = geocovariate %>%
      str_replace_all("_", " ") %>%
      str_to_title(),
    relationship_strength = case_when(
      is.na(correlation) ~ "No data",
      abs(correlation) >= 0.70 ~ "Strong",
      abs(correlation) >= 0.40 ~ "Moderate",
      abs(correlation) >= 0.20 ~ "Weak",
      TRUE ~ "Very weak"
    ),
    direction = case_when(
      is.na(correlation) ~ "No data",
      correlation > 0 ~ "Positive",
      correlation < 0 ~ "Negative",
      TRUE ~ "None"
    )
  ) %>%
  arrange(indicator, desc(abs(correlation)))

# 12. SAVE OUTPUTS ----
saveRDS(county_geocovariates, file.path(output_path, "county_geocovariates.rds"))
saveRDS(indicators_with_geocov_long, file.path(output_path, "indicators_with_geocov_long.rds"))
saveRDS(county_dashboard_wide, file.path(output_path, "county_dashboard_wide.rds"))
saveRDS(correlation_data, file.path(output_path, "indicator_geocovariate_correlations.rds"))

write_xlsx(
  list(
    "Indicators_With_Geocov_Long" = indicators_with_geocov_long,
    "County_Dashboard_Wide"       = county_dashboard_wide,
    "County_Geocovariates"        = county_geocovariates,
    "Geocovariates_Long"          = county_geocovariates_long,
    "Indicator_Correlations"      = correlation_data
  ),
  file.path(output_path, "powerbi", "MNCAH_Kenya_DHS_Indicators_With_Geocovariates.xlsx")
)

# 13. QUICK QUALITY CHECKS ----
cat("Counties in indicators:", n_distinct(all_indicators$county_name[all_indicators$county_name != "NATIONAL"]), "\n")
cat("Counties in geocovariates:", n_distinct(county_geocovariates$county_name), "\n")
cat("Rows in enriched long table:", nrow(indicators_with_geocov_long), "\n")
cat("Rows in enriched wide table:", nrow(county_dashboard_wide), "\n")

cat("\nTop 20 strongest indicator-geocovariate correlations:\n")
print(
  correlation_data %>%
    filter(!is.na(correlation)) %>%
    arrange(desc(abs(correlation))) %>%
    select(indicator, geocovariate_label, correlation, relationship_strength, direction, n_counties) %>%
    head(20),
  n = 20
)

