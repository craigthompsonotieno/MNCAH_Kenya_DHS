# =============================================================================
# MNCAH Kenya DHS Analysis — Script 2: Compute Indicators
# Author: Craig Thompson Otieno
# Purpose: Compute survey-weighted MNCAH indicators at national & county level
# Indicators: Maternal, Child, Adolescent, Environmental Health
# =============================================================================

library(tidyverse)
library(srvyr)
library(writexl)

output_path <- "Data/Clean"

# Handle strata with single PSU (common in DHS data)
options(survey.lonely.psu = "adjust")

# Load cleaned data from Script 1
ir <- readRDS(file.path(output_path, "ir_clean.rds"))
kr <- readRDS(file.path(output_path, "kr_clean.rds"))
hr <- readRDS(file.path(output_path, "hr_clean.rds"))


# 1. HELPER FUNCTION: compute weighted % at national + county level ----
compute_indicator <- function(data, indicator_col, label,
                              weight_col = "weight",
                              cluster_col = "cluster",
                              stratum_col = "stratum") {
  
  svy <- data %>%
    filter(!is.na(.data[[indicator_col]])) %>%
    as_survey_design(
      ids     = all_of(cluster_col),
      strata  = all_of(stratum_col),
      weights = all_of(weight_col)
    )
  
  # National estimate
  national <- svy %>%
    summarise(
      estimate = survey_mean(.data[[indicator_col]], vartype = "ci", na.rm = TRUE)
    ) %>%
    mutate(
      county_code = 0,
      county_name = "NATIONAL",
      indicator   = label,
      estimate    = round(estimate * 100, 1),
      lower_ci    = round(estimate_low * 100, 1),
      upper_ci    = round(estimate_upp * 100, 1),
      n           = nrow(svy$variables)
    ) %>%
    select(county_code, county_name, indicator, estimate, lower_ci, upper_ci, n)
  
  # County-level estimates
  county <- svy %>%
    group_by(county_code, county_name) %>%
    summarise(
      estimate = survey_mean(.data[[indicator_col]], vartype = "ci", na.rm = TRUE),
      n        = unweighted(n()),
      .groups  = "drop"
    ) %>%
    mutate(
      indicator = label,
      estimate  = round(estimate * 100, 1),
      lower_ci  = round(estimate_low * 100, 1),
      upper_ci  = round(estimate_upp * 100, 1)
    ) %>%
    select(county_code, county_name, indicator, estimate, lower_ci, upper_ci, n)
  
  return(bind_rows(national, county))
}

# 2. MATERNAL HEALTH INDICATORS (from IR) ----
# Filter: women with last birth in last 5 years (standard DHS denominator)
ir_maternal <- ir %>%
  filter(!is.na(m14_1))  # Has ANC visit info → implies recent birth

## 2.1. ANC 4+ visits ----
ir_maternal <- ir_maternal %>%
  mutate(anc4plus = case_when(
    m14_1 >= 4 & m14_1 < 98 ~ 1L,
    m14_1 < 4               ~ 0L,
    TRUE                    ~ NA_integer_
  ))

anc4 <- compute_indicator(ir_maternal, "anc4plus", "ANC 4+ visits (%)")

## 2.2. Skilled birth attendant (SBA) ----
# m3a = doctor, m3b = nurse/midwife, m3c = auxiliary midwife attended delivery
ir_maternal <- ir_maternal %>%
  mutate(sba = case_when(
    (as.numeric(m3a_1) == 1 | as.numeric(m3b_1) == 1 | as.numeric(m3c_1) == 1) ~ 1L,
    (!is.na(m3a_1) | !is.na(m3b_1) | !is.na(m3c_1))                           ~ 0L,
    TRUE ~ NA_integer_
  ))

sba <- compute_indicator(ir_maternal, "sba", "Skilled birth attendant (%)")

## 2.3. Postnatal care for mother within 2 days ----
# m62_1: timing of first PNC check for mother (1 = within 4h, 2 = 4-23h, 3 = 1 day, 4 = 2 days)
ir_maternal <- ir_maternal %>%
  mutate(pnc_mother = case_when(
    as.numeric(m62_1) %in% 1:4 ~ 1L,   # Within 2 days
    as.numeric(m62_1) > 4      ~ 0L,
    TRUE                       ~ NA_integer_
  ))

pnc <- compute_indicator(ir_maternal, "pnc_mother", "Postnatal care - mother within 2 days (%)")

## 2.4. Facility delivery ----
# m15_1: place of delivery — facility = 20-40 range in DHS coding
ir_maternal <- ir_maternal %>%
  mutate(facility_delivery = case_when(
    as.numeric(m15_1) >= 20 & as.numeric(m15_1) < 90 ~ 1L,
    as.numeric(m15_1) < 20                            ~ 0L,
    TRUE                                              ~ NA_integer_
  ))

fac_del <- compute_indicator(ir_maternal, "facility_delivery", "Facility delivery (%)")

# 3. CHILD HEALTH INDICATORS (from KR) ----
## 3.1. Full immunization (age 12-23 months) ----
# Includes: BCG (h2), DPT1 (h3), DPT2 (h5), DPT3 (h7),
#           Polio1 (h4), Polio2 (h6), Polio3 (h8), Measles (h9)
kr_imm <- kr %>%
  filter(child_age_months >= 12 & child_age_months <= 23) %>%
  mutate(
    bcg   = as.numeric(h2) %in% 1:3,
    dpt1  = as.numeric(h3) %in% 1:3,
    dpt2  = as.numeric(h5) %in% 1:3,
    dpt3  = as.numeric(h7) %in% 1:3,
    pol1  = as.numeric(h4) %in% 1:3,
    pol2  = as.numeric(h6) %in% 1:3,
    pol3  = as.numeric(h8) %in% 1:3,
    meas  = as.numeric(h9) %in% 1:3,
    fully_immunized = as.integer(bcg & dpt1 & dpt2 & dpt3 & pol1 & pol2 & pol3 & meas)
  )

imm <- compute_indicator(kr_imm, "fully_immunized", "Full immunization coverage (%)")

## 3.2. Stunting (HAZ < -2 SD) — children under 5 ----
kr_anthro <- kr %>%
  filter(!is.na(hw70) & hw70 != 9999) %>%  # Remove missing/flagged
  mutate(stunted = as.integer(hw70 < -200 & hw70 >= -600))

stunting <- compute_indicator(kr_anthro, "stunted", "Stunting prevalence - HAZ < -2SD (%)")

## 3.3. Wasting (WHZ < -2 SD) ----
kr_anthro <- kr_anthro %>%
  filter(!is.na(hw72) & hw72 != 9999) %>%
  mutate(wasted = as.integer(hw72 < -200 & hw72 >= -500))

wasting <- compute_indicator(kr_anthro, "wasted", "Wasting prevalence - WHZ < -2SD (%)")

## 3.4. Diarrhea treatment with ORS (children under 5 with diarrhea in last 2 weeks) ----
kr_diarrhea <- kr %>%
  filter(as.numeric(h11) == 1) %>%  # Had diarrhea in last 2 weeks
  mutate(ors_treatment = as.integer(as.numeric(h13) == 1))  # Received ORS

if (nrow(kr_diarrhea) > 50) {
  ors <- compute_indicator(kr_diarrhea, "ors_treatment", "Diarrhea treated with ORS (%)")
  cat("  ✓ ORS treatment done — national:", filter(ors, county_name == "NATIONAL")$estimate, "%\n")
} else {
  cat("  ⚠ Insufficient diarrhea cases for reliable ORS estimates — skipped\n")
  ors <- NULL
}

# 4. ADOLESCENT HEALTH INDICATORS (from IR) ----
ir_adol <- ir %>% filter(age_woman >= 15 & age_woman <= 19)

# 4.1. Modern contraceptive use among adolescents (15-19) ----
# v313: 0=not using, 1=folk, 2=traditional, 3=modern
ir_adol <- ir_adol %>%
  mutate(modern_contra = case_when(
    as.numeric(v313) == 3 ~ 1L,
    as.numeric(v313) %in% 0:2 ~ 0L,
    TRUE ~ NA_integer_
  ))

contra <- compute_indicator(ir_adol, "modern_contra", "Modern contraceptive use - adolescents 15-19 (%)")

## 4.2. Adolescent women who have begun childbearing (ever had a birth) ----
ir_adol <- ir_adol %>%
  mutate(begun_childbearing = as.integer(as.numeric(v201) >= 1))

adol_birth <- compute_indicator(ir_adol, "begun_childbearing", "Adolescents 15-19 who have begun childbearing (%)")

## 4.3. Adolescent antenatal care (among those with a birth) ----
ir_adol_birth <- ir_adol %>%
  filter(!is.na(m14_1)) %>%
  mutate(anc4plus = case_when(
    m14_1 >= 4 & m14_1 < 98 ~ 1L,
    m14_1 < 4               ~ 0L,
    TRUE                    ~ NA_integer_
  ))

if (nrow(ir_adol_birth) > 50) {
  adol_anc <- compute_indicator(ir_adol_birth, "anc4plus", "ANC 4+ among adolescents with recent birth (%)")
  cat("  ✓ Adolescent ANC4+ done — national:", filter(adol_anc, county_name == "NATIONAL")$estimate, "%\n")
} else {
  adol_anc <- NULL
  cat("  ⚠ Insufficient adolescent birth cases for ANC estimates — skipped\n")
}

# 5. ENVIRONMENTAL / HOUSEHOLD HEALTH INDICATORS (from HR) ----
## 5.1. Improved drinking water source (JMP definition) ----
# hv201: 11=piped to dwelling, 12=piped to yard, 13=public tap,
#        21=tube well/borehole, 31=protected well, 41=protected spring,
#        51=rainwater, 61=tanker/trucked, 71=bottled water
hr <- hr %>%
  mutate(improved_water = case_when(
    as.numeric(hv201) %in% c(11, 12, 13, 21, 31, 41, 51, 61, 71, 72) ~ 1L,
    as.numeric(hv201) %in% c(32, 33, 42, 43, 96)                     ~ 0L,
    TRUE ~ NA_integer_
  ))

water <- compute_indicator(hr, "improved_water", "Improved drinking water source (%)",
                           weight_col = "weight", cluster_col = "cluster", stratum_col = "stratum")

## 5.2. Improved sanitation facility ----
# hv205: 11=flush to sewer, 12=flush to septic, 13=flush to pit,
#        14=flush to somewhere, 21=VIP, 22=pit with slab, 23=composting
hr <- hr %>%
  mutate(improved_sanitation = case_when(
    as.numeric(hv205) %in% c(11, 12, 13, 14, 15, 21, 22, 23) ~ 1L,
    as.numeric(hv205) %in% c(31, 32, 42, 43, 96)             ~ 0L,
    TRUE ~ NA_integer_
  ))

sanitation <- compute_indicator(hr, "improved_sanitation", "Improved sanitation facility (%)",
                                weight_col = "weight", cluster_col = "cluster", stratum_col = "stratum")

## 5.3. Households with electricity ----
hr <- hr %>%
  mutate(has_electricity = as.integer(as.numeric(hv206) == 1))

electricity <- compute_indicator(hr, "has_electricity", "Households with electricity (%)",
                                 weight_col = "weight", cluster_col = "cluster", stratum_col = "stratum")

# 6. COMBINE ALL INDICATORS ----
all_indicators <- bind_rows(
  anc4, sba, pnc, fac_del,         # Maternal
  imm, stunting, wasting, ors,     # Child
  contra, adol_birth, adol_anc,    # Adolescent
  water, sanitation, electricity   # Environmental
)



# 7. WIDE FORMAT FOR POWER BI ----
wide_indicators <- all_indicators %>%
  filter(county_name != "NATIONAL") %>%
  select(county_code, county_name, indicator, estimate) %>%
  pivot_wider(names_from = indicator, values_from = estimate)

national_summary <- all_indicators %>%
  filter(county_name == "NATIONAL") %>%
  select(indicator, estimate, lower_ci, upper_ci, n) %>%
  arrange(indicator)

# 8. SAVE OUTPUTS
## 8.1. Full long format (best for Power BI) ----
write_xlsx(
  list(
    "All_Indicators_Long"  = all_indicators,
    "County_Wide"          = wide_indicators,
    "National_Summary"     = national_summary
  ),
  file.path(output_path, "powerbi", "MNCAH_Kenya_DHS_Indicators.xlsx")
)

## 8.2. Save RDS for mapping script ----
saveRDS(all_indicators,  file.path(output_path, "all_indicators.rds"))
saveRDS(wide_indicators, file.path(output_path, "wide_indicators.rds"))


