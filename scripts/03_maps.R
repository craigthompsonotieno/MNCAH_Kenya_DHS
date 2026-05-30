# =============================================================================
# MNCAH Kenya DHS Analysis — Script 3: County Choropleth Maps
# Author: Craig Thompson Otieno
# Purpose: Generate publication-quality county choropleth maps
# =============================================================================

library(tidyverse)
library(sf)
library(scales)
library(patchwork)
library(janitor)

if (!requireNamespace("geodata", quietly = TRUE)) install.packages("geodata")
if (!requireNamespace("terra", quietly = TRUE)) install.packages("terra")

library(geodata)
library(terra)

output_path <- "Data/Clean"

dir.create(file.path(output_path, "maps"), showWarnings = FALSE, recursive = TRUE)
dir.create(file.path(output_path, "shapefiles"), showWarnings = FALSE, recursive = TRUE)

# 1. LOAD INDICATORS ----
all_indicators  <- readRDS(file.path(output_path, "all_indicators.rds"))
wide_indicators <- readRDS(file.path(output_path, "wide_indicators.rds"))


# 2. LOAD KENYA COUNTY POLYGONS ----
kenya_poly <- geodata::gadm(
  country = "KEN",
  level   = 1,
  path    = file.path(output_path, "shapefiles")
)

kenya_sf <- st_as_sf(kenya_poly) %>%
  clean_names() %>%
  mutate(
    county_name_shp = str_to_title(str_trim(name_1))
  )


# 3. CLEAN COUNTY NAMES ----
clean_county <- function(x) {
  x %>%
    as.character() %>%
    str_trim() %>%
    str_remove("^\\.?\\s*\\d*\\s*") %>%
    str_squish() %>%
    str_to_title() %>%
    str_replace_all("-", " ") %>%
    str_squish() %>%
    str_replace("^Elgeyo Marakwet$", "Elgeyo-Marakwet") %>%
    str_replace("^Tharaka Nithi$", "Tharaka-Nithi") %>%
    str_replace("^Murang'A$", "Murang'a")
}

matched <- all_indicators %>%
  filter(county_name != "NATIONAL") %>%
  distinct(county_code, county_name) %>%
  mutate(county_name_clean = clean_county(county_name)) %>%
  left_join(
    kenya_sf %>%
      st_drop_geometry() %>%
      distinct(county_name_shp) %>%
      mutate(match_found = TRUE),
    by = c("county_name_clean" = "county_name_shp")
  )

unmatched <- matched %>%
  filter(is.na(match_found))

if (nrow(unmatched) > 0) {
  cat("\n⚠ Unmatched counties:\n")
  print(unmatched, n = Inf)
} else {
  cat("\n✓ All counties matched successfully\n")
}

# 4. MERGE FUNCTION ----
merge_for_map <- function(indicator_name) {
  
  ind_data <- all_indicators %>%
    filter(
      indicator == indicator_name,
      county_name != "NATIONAL"
    ) %>%
    mutate(
      county_name_clean = clean_county(county_name)
    )
  
  kenya_sf %>%
    left_join(
      ind_data,
      by = c("county_name_shp" = "county_name_clean")
    )
}

# 5. MAP THEME ----
unicef_blue   <- "#1CABE2"
unicef_navy   <- "#374EA2"
unicef_yellow <- "#FFC20E"
bg_color      <- "#F7F9FC"

map_theme <- theme_void() +
  theme(
    plot.background  = element_rect(fill = bg_color, color = NA),
    panel.background = element_rect(fill = bg_color, color = NA),
    legend.position  = "bottom",
    legend.title     = element_text(size = 8, face = "bold", color = "#2C3E50"),
    legend.text      = element_text(size = 7, color = "#2C3E50"),
    legend.key.width = unit(1.5, "cm"),
    legend.key.height = unit(0.3, "cm"),
    plot.title       = element_text(
      size = 11,
      face = "bold",
      color = "#2C3E50",
      hjust = 0.5,
      margin = margin(b = 4)
    ),
    plot.subtitle    = element_text(
      size = 8,
      color = "#7F8C8D",
      hjust = 0.5,
      margin = margin(b = 8)
    ),
    plot.caption     = element_text(size = 6, color = "#95A5A6", hjust = 0)
  )

blank_panel <- ggplot() +
  theme_void() +
  theme(
    plot.background  = element_rect(fill = bg_color, color = NA),
    panel.background = element_rect(fill = bg_color, color = NA)
  )

# 6. DRAW MAP FUNCTION ----

draw_map <- function(indicator_name, title, subtitle = "",
                     colors = c("#1CABE2", "#FFF09C", "#FFC20E", "#F26A21", "#E2231A"),
                     reverse_palette = FALSE) {
  
  map_data <- merge_for_map(indicator_name)
  
  x <- map_data$estimate
  
  # Rank/quantile stretching so counties do not look same-color
  fill_stretched <- rep(NA_real_, length(x))
  keep <- which(!is.na(x) & is.finite(x))
  
  if (length(keep) == 1) {
    fill_stretched[keep] <- 0.5
  }
  
  if (length(keep) > 1) {
    fill_stretched[keep] <- percent_rank(x[keep])
  }
  
  map_data$fill_stretched <- fill_stretched
  
  # Legend labels based on actual indicator values
  x_nonmiss <- x[!is.na(x) & is.finite(x)]
  
  if (length(x_nonmiss) == 0) {
    raw_breaks <- c(0, 25, 50, 75, 100)
  } else {
    raw_breaks <- quantile(
      x_nonmiss,
      probs = c(0, 0.25, 0.50, 0.75, 1),
      na.rm = TRUE
    )
  }
  
  breaks_fill <- c(0, 0.25, 0.50, 0.75, 1.00)
  labels <- paste0(round(raw_breaks, 1), "%")
  
  if (reverse_palette) {
    colors <- rev(colors)
  }
  
  national_val <- all_indicators %>%
    filter(
      indicator == indicator_name,
      county_name == "NATIONAL"
    ) %>%
    pull(estimate)
  
  national_text <- if (length(national_val) == 0 || all(is.na(national_val))) {
    ""
  } else {
    paste0("National average: ", round(national_val[1], 1), "%")
  }
  
  ggplot(map_data) +
    geom_sf(aes(fill = fill_stretched), color = "white", linewidth = 0.35) +
    scale_fill_gradientn(
      colours = colors,
      values = breaks_fill,
      limits = c(0, 1),
      breaks = breaks_fill,
      labels = labels,
      name = "(%)",
      na.value = "gray85",
      oob = scales::squish,
      guide = guide_colorbar(
        title.position = "top",
        barwidth = unit(5, "cm"),
        barheight = unit(0.4, "cm")
      )
    ) +
    coord_sf(expand = FALSE) +
    labs(
      title    = title,
      subtitle = if (nchar(subtitle) > 0) subtitle else national_text,
      caption  = "Source: Kenya DHS 2014 | Weighted estimates"
    ) +
    map_theme
}

# 7. GENERATE INDIVIDUAL MAPS ----
map_anc4 <- draw_map(
  "ANC 4+ visits (%)",
  "ANC 4+ Coverage",
  colors = c("#EAF4FB", "#B9E2F4", "#1CABE2", "#0077B6", "#003B73")
)

map_sba <- draw_map(
  "Skilled birth attendant (%)",
  "Skilled Birth Attendant",
  colors = c("#E8F5E9", "#A5D6A7", "#66BB6A", "#2E7D32", "#004D40")
)

map_pnc <- draw_map(
  "Postnatal care - mother within 2 days (%)",
  "Postnatal Care (Mother)",
  colors = c("#F3E5F5", "#CE93D8", "#AB47BC", "#7B1FA2", "#4A148C")
)

map_fac <- draw_map(
  "Facility delivery (%)",
  "Facility Delivery",
  colors = c("#E0F2F1", "#80CBC4", "#26A69A", "#00897B", "#004D40")
)

map_imm <- draw_map(
  "Full immunization coverage (%)",
  "Full Immunization",
  colors = c("#F7FCB9", "#C7E9B4", "#7FCDBB", "#41B6C4", "#225EA8")
)

map_stunt <- draw_map(
  "Stunting prevalence - HAZ < -2SD (%)",
  "Stunting Prevalence",
  colors = c("#FFF5F0", "#FCBBA1", "#FC9272", "#FB6A4A", "#CB181D")
)

map_wast <- draw_map(
  "Wasting prevalence - WHZ < -2SD (%)",
  "Wasting Prevalence",
  colors = c("#FFF7EC", "#FDD49E", "#FDBB84", "#FC8D59", "#D7301F")
)

map_contra <- draw_map(
  "Modern contraceptive use - adolescents 15-19 (%)",
  "Modern Contraceptive Use\n(Adolescents 15-19)",
  colors = c("#F1EEF6", "#D7B5D8", "#DF65B0", "#DD1C77", "#980043")
)

map_adol_birth <- draw_map(
  "Adolescents 15-19 who have begun childbearing (%)",
  "Adolescent Childbearing\n(15-19 years)",
  colors = c("#FFF7EC", "#FDD49E", "#FDBB84", "#FC8D59", "#D94801")
)

map_water <- draw_map(
  "Improved drinking water source (%)",
  "Improved Water Source",
  colors = c("#EFF3FF", "#BDD7E7", "#6BAED6", "#3182BD", "#08519C")
)

map_san <- draw_map(
  "Improved sanitation facility (%)",
  "Improved Sanitation",
  colors = c("#EDF8E9", "#BAE4B3", "#74C476", "#31A354", "#006D2C")
)

map_elec <- draw_map(
  "Households with electricity (%)",
  "Household Electricity Access",
  colors = c("#FFFFCC", "#FFEDA0", "#FED976", "#FEB24C", "#F03B20")
)

# 8. COMPOSITE PANEL MAPS ----
maternal_panel <- (map_anc4 | map_sba) / (map_pnc | map_fac) +
  plot_annotation(
    title    = "Maternal Health Indicators — Kenya 2014 DHS",
    subtitle = "Survey-weighted county-level estimates",
    theme    = theme(
      plot.title = element_text(size = 14, face = "bold", color = "#2C3E50", hjust = 0.5),
      plot.subtitle = element_text(size = 9, color = "#7F8C8D", hjust = 0.5),
      plot.background = element_rect(fill = bg_color, color = NA)
    )
  )

ggsave(
  file.path(output_path, "maps", "01_maternal_health_panel.png"),
  maternal_panel,
  width = 12,
  height = 10,
  dpi = 200,
  bg = bg_color
)

child_panel <- (map_imm | map_stunt) / 
  (plot_spacer() | map_wast | plot_spacer()) +
  plot_layout(
    heights = c(1, 1),
    widths  = c(1, 1, 1)
  ) +
  plot_annotation(
    title    = "Child Health Indicators — Kenya 2014 DHS",
    subtitle = "Survey-weighted county-level estimates",
    theme    = theme(
      plot.title = element_text(size = 14, face = "bold", color = "#2C3E50", hjust = 0.5),
      plot.subtitle = element_text(size = 9, color = "#7F8C8D", hjust = 0.5),
      plot.background = element_rect(fill = bg_color, color = NA)
    )
  )

ggsave(
  file.path(output_path, "maps", "02_child_health_panel.png"),
  child_panel,
  width = 12,
  height = 9,
  dpi = 200,
  bg = bg_color
)

adol_env_panel <- (map_contra | map_adol_birth) / (map_water | map_san) +
  plot_annotation(
    title    = "Adolescent & Environmental Health — Kenya 2014 DHS",
    subtitle = "Survey-weighted county-level estimates",
    theme    = theme(
      plot.title = element_text(size = 14, face = "bold", color = "#2C3E50", hjust = 0.5),
      plot.subtitle = element_text(size = 9, color = "#7F8C8D", hjust = 0.5),
      plot.background = element_rect(fill = bg_color, color = NA)
    )
  )

ggsave(
  file.path(output_path, "maps", "03_adolescent_environmental_panel.png"),
  adol_env_panel,
  width = 12,
  height = 10,
  dpi = 200,
  bg = bg_color
)

# 9. EQUITY GAP CHART — TOP 5 vs BOTTOM 5 ONLY ----
key_indicators <- c(
  "ANC 4+ visits (%)",
  "Full immunization coverage (%)",
  "Improved drinking water source (%)",
  "Improved sanitation facility (%)"
)

equity_data <- all_indicators %>%
  filter(
    indicator %in% key_indicators,
    county_name != "NATIONAL"
  ) %>%
  mutate(
    county_name_clean = clean_county(county_name)
  ) %>%
  group_by(indicator) %>%
  arrange(desc(estimate), .by_group = TRUE) %>%
  mutate(rank_desc = row_number()) %>%
  mutate(rank_asc = row_number(desc(-estimate))) %>%
  mutate(
    group = case_when(
      rank_desc <= 5 ~ "Top 5 counties",
      rank_asc  <= 5 ~ "Bottom 5 counties",
      TRUE ~ NA_character_
    )
  ) %>%
  filter(!is.na(group)) %>%
  ungroup()

equity_plot <- equity_data %>%
  ggplot(
    aes(
      x = reorder(county_name_clean, estimate),
      y = estimate,
      fill = group
    )
  ) +
  geom_col(width = 0.72) +
  geom_text(
    aes(label = paste0(round(estimate,1), "%")),
    hjust = -0.12,
    size = 2.8
  ) +
  facet_wrap(~indicator, scales = "free_y", ncol = 2) +
  coord_flip() +
  scale_fill_manual(
    values = c(
      "Top 5 counties" = "#1CABE2",
      "Bottom 5 counties" = "#E74C3C"
    )
  ) +
  scale_y_continuous(
    expand = expansion(mult = c(0, .12)),
    labels = function(x) paste0(x, "%")
  ) +
  labs(
    title    = "Equity Gaps in MNCAH Indicators — Kenya 2014 DHS",
    subtitle = "Top 5 vs Bottom 5 performing counties only",
    x = NULL,
    y = NULL,
    fill = NULL,
    caption = "Source: Kenya DHS 2014 | Weighted estimates"
  ) +
  theme_minimal(base_size = 10) +
  theme(
    legend.position = "top",
    strip.text = element_text(face = "bold", size = 9),
    plot.title = element_text(face = "bold", size = 12),
    panel.grid.major.y = element_blank(),
    panel.grid.minor = element_blank(),
    axis.text.y = element_text(size = 8),
    axis.text.x = element_text(size = 8),
    plot.background = element_rect(fill = bg_color, color = NA)
  )

ggsave(
  file.path(output_path, "maps", "04_equity_gap_chart.png"),
  equity_plot,
  width = 14,
  height = 10,
  dpi = 220,
  bg = bg_color
)
