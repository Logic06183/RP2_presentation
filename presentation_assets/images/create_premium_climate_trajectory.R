#!/usr/bin/env Rscript
# Premium climate trajectory diagram with climate zone transition table
# Shows exactly how each city's climate changes across scenarios

suppressPackageStartupMessages({
  library(sf)
  library(ggplot2)
  library(dplyr)
  library(terra)
  library(patchwork)
  library(gridExtra)
  library(grid)
})

theme_premium <- function() {
  theme_minimal() +
    theme(
      text = element_text(family = "Arial", size = 10),
      plot.title = element_text(size = 13, hjust = 0.5, face = "bold", margin = margin(b = 5)),
      plot.subtitle = element_text(size = 10, hjust = 0.5, color = "gray40", margin = margin(b = 8)),
      axis.text = element_text(size = 8, color = "gray50"),
      axis.title = element_text(size = 9, color = "gray40"),
      legend.position = "none",
      panel.grid = element_line(color = "gray90", linewidth = 0.2),
      panel.background = element_rect(fill = "white", color = NA),
      plot.background = element_rect(fill = "white", color = NA),
      plot.margin = margin(10, 10, 10, 10)
    )
}

# Professional Köppen-Geiger colors
premium_koppen_colors <- c(
  "2" = "#2F4F2F", "3" = "#6B8E23", "4" = "#DAA520", "5" = "#D2691E", 
  "6" = "#CD853F", "7" = "#A0522D", "8" = "#8B008B", "9" = "#228B22",
  "11" = "#4682B4", "12" = "#5F9EA0", "13" = "#48D1CC", "14" = "#87CEFA", 
  "15" = "#B0E0E6", "23" = "#20B2AA", "26" = "#D3D3D3", "29" = "#708090"
)

koppen_full_names <- c(
  "2" = "Am - Tropical monsoon", "3" = "Aw - Tropical savannah", 
  "4" = "BWh - Hot desert", "5" = "BWk - Cold desert",
  "6" = "BSh - Hot semi-arid", "7" = "BSk - Cold semi-arid",
  "8" = "Csa - Mediterranean hot", "9" = "Csb - Mediterranean warm",
  "11" = "Cwa - Humid subtropical", "12" = "Cwb - Subtropical highland",
  "13" = "Cwc - Subtropical cold", "14" = "Cfa - Humid temperate",
  "15" = "Cfb - Oceanic", "23" = "Dwc - Cold, dry winter",
  "26" = "Dfb - Cold, no dry season", "29" = "ET - Tundra"
)

# Major cities
cities <- data.frame(
  city = c("Lilongwe", "Harare", "Johannesburg", "Cape Town"),
  country = c("Malawi", "Zimbabwe", "South Africa", "South Africa"),
  lon = c(33.7703, 31.0492, 28.0341, 18.4241),
  lat = c(-13.9626, -17.8292, -26.1952, -33.9249),
  stringsAsFactors = FALSE
)

extract_climate_at_point <- function(raster, lon, lat) {
  point <- vect(data.frame(x = lon, y = lat), geom = c("x", "y"), crs = "EPSG:4326")
  climate_value <- extract(raster, point)[1, 2]
  return(as.character(climate_value))
}

# Extract climate zones for all cities across all scenarios
climate_transitions <- data.frame()

scenarios <- list(
  baseline = "high_res_koppen/1991_2020/koppen_geiger_0p00833333.tif",
  moderate = "high_res_koppen/2071_2099/ssp245/koppen_geiger_0p00833333.tif",
  extreme = "high_res_koppen/2071_2099/ssp585/koppen_geiger_0p00833333.tif"
)

for (scenario_name in names(scenarios)) {
  raster_path <- scenarios[[scenario_name]]
  koppen_raster <- rast(raster_path)
  
  for (i in 1:nrow(cities)) {
    climate_code <- extract_climate_at_point(koppen_raster, cities$lon[i], cities$lat[i])
    climate_zone <- ifelse(is.na(climate_code) || is.null(koppen_full_names[climate_code]), 
                          "Unknown", koppen_full_names[climate_code])
    
    climate_transitions <- rbind(climate_transitions, data.frame(
      city = cities$city[i],
      country = cities$country[i],
      scenario = scenario_name,
      climate_code = climate_code,
      climate_zone = climate_zone,
      stringsAsFactors = FALSE
    ))
  }
}

# Create climate transition table
transition_table <- climate_transitions %>%
  select(city, country, scenario, climate_zone) %>%
  pivot_wider(names_from = scenario, values_from = climate_zone) %>%
  mutate(
    location = paste0(city, ", ", country),
    baseline = ifelse(is.na(baseline), "Unknown", baseline),
    moderate = ifelse(is.na(moderate), "Unknown", moderate),
    extreme = ifelse(is.na(extreme), "Unknown", extreme)
  ) %>%
  select(location, baseline, moderate, extreme)

# Print transition table for verification
cat("Climate zone transitions:\n")
print(transition_table)

create_premium_map <- function(raster_path, title, subtitle, warming_color, scenario_label) {
  # Load and process
  koppen_raster <- rast(raster_path)
  sa_bbox <- ext(10, 42, -35, -8)
  koppen_sa <- crop(koppen_raster, sa_bbox)
  koppen_sa_agg <- aggregate(koppen_sa, fact = 4, fun = "modal")
  
  # Convert to polygons
  koppen_polygons <- as.polygons(koppen_sa_agg, dissolve = TRUE)
  koppen_sf <- st_as_sf(koppen_polygons)
  
  # Prepare data
  data_col <- names(koppen_sf)[1]
  koppen_sf <- koppen_sf %>%
    filter(!is.na(.data[[data_col]])) %>%
    mutate(climate_code = as.character(.data[[data_col]]))
  
  # Get scenario-specific city climates
  scenario_cities <- climate_transitions %>%
    filter(scenario == tolower(gsub(" .*", "", title))) %>%
    left_join(cities, by = "city")
  
  # Filter colors
  present_codes <- unique(koppen_sf$climate_code)
  present_colors <- premium_koppen_colors[present_codes]
  present_colors <- present_colors[!is.na(present_colors)]
  
  # Create enhanced map
  ggplot() +
    geom_sf(data = koppen_sf, 
            aes(fill = climate_code), 
            color = "white", 
            linewidth = 0.1,
            alpha = 0.85) +
    scale_fill_manual(values = present_colors, na.value = "transparent") +
    
    # Enhanced city points
    geom_point(data = scenario_cities, 
               aes(x = lon, y = lat), 
               size = 5, color = "white", fill = "#E31A1C", 
               shape = 21, stroke = 2.5) +
    
    # City labels with white background boxes
    geom_label(data = scenario_cities,
               aes(x = lon + 2, y = lat + 1.5, 
                   label = paste0(city, "\n", substr(climate_zone, 1, 3))),
               size = 3, fontface = "bold", hjust = 0,
               fill = "white", color = "black", 
               label.padding = unit(0.3, "lines"),
               label.r = unit(0.2, "lines")) +
    
    coord_sf(xlim = c(12, 42), ylim = c(-35, -8), expand = FALSE) +
    labs(title = title, subtitle = subtitle, 
         x = "Longitude (°E)", y = "Latitude (°S)") +
    theme_premium() +
    
    # Enhanced scenario indicator
    annotate("rect", xmin = 38, xmax = 41.8, ymin = -34.8, ymax = -31,
             fill = warming_color, color = "white", alpha = 0.95, linewidth = 1.5) +
    annotate("text", x = 39.9, y = -32.9, 
             label = scenario_label, 
             size = 4.5, fontface = "bold", color = "white", lineheight = 0.9)
}

# Create premium maps
cat("Creating premium progression maps...\n")

baseline_premium <- create_premium_map(
  scenarios$baseline$path, scenarios$baseline$title, scenarios$baseline$subtitle,
  scenarios$baseline$color, scenarios$baseline$label
)

moderate_premium <- create_premium_map(
  scenarios$moderate$path, scenarios$moderate$title, scenarios$moderate$subtitle,
  scenarios$moderate$color, scenarios$moderate$label
)

extreme_premium <- create_premium_map(
  scenarios$extreme$path, scenarios$extreme$title, scenarios$extreme$subtitle,
  scenarios$extreme$color, scenarios$extreme$label
)

# Create legend
legend_plot_premium <- ggplot(legend_data, aes(x = 1, y = code, fill = code)) +
  geom_point(alpha = 0) +
  scale_fill_manual(
    name = "Köppen-Geiger Climate Zones",
    values = premium_koppen_colors,
    labels = koppen_full_names,
    na.value = "transparent"
  ) +
  theme_void() +
  theme(
    legend.position = "bottom",
    legend.title = element_text(family = "Arial", size = 12, face = "bold"),
    legend.text = element_text(family = "Arial", size = 8),
    legend.key.size = unit(0.4, "cm"),
    legend.margin = margin(t = 15)
  ) +
  guides(fill = guide_legend(ncol = 4, byrow = TRUE))

# Premium final diagram
premium_diagram <- baseline_premium + moderate_premium + extreme_premium + 
  plot_layout(nrow = 1) +
  plot_annotation(
    title = "Southern Africa Climate Change Trajectory",
    subtitle = "Köppen-Geiger Climate Zone Evolution: Current → Moderate → Extreme Warming",
    caption = paste(
      "Data Source: Beck, H.E. et al. (2023) High-resolution (1 km) Köppen-Geiger maps for 1901–2099",
      "Scientific Data 10, 724. DOI: 10.1038/s41597-023-02549-6",
      "Available: https://figshare.com/articles/dataset/21789074",
      "Baseline: 1991-2020 (30-year climate normal) | Future: 2071-2099 CMIP6 projections",
      sep = "\n"
    ),
    theme = theme(
      plot.title = element_text(family = "Arial", size = 22, face = "bold", hjust = 0.5, margin = margin(b = 8)),
      plot.subtitle = element_text(family = "Arial", size = 16, hjust = 0.5, color = "gray30", margin = margin(b = 15)),
      plot.caption = element_text(family = "Arial", size = 9, hjust = 0.5, color = "gray50", 
                                  lineheight = 1.3, margin = margin(t = 20))
    )
  )

# Add legend
premium_final <- premium_diagram / legend_plot_premium + 
  plot_layout(heights = c(1, 0.25))

# Save premium diagram
ggsave("southern_africa_climate_trajectory_premium_final.svg", premium_final, 
       width = 36, height = 22, bg = "white", device = "svg")

# Create climate transition summary table as separate visualization
transition_plot <- ggplot() +
  annotate("text", x = 0.5, y = 0.9, 
           label = "Climate Zone Transitions by City",
           size = 6, fontface = "bold", hjust = 0.5) +
  annotate("text", x = 0.1, y = 0.8, 
           label = "Location", size = 4, fontface = "bold") +
  annotate("text", x = 0.4, y = 0.8, 
           label = "Baseline\n(1991-2020)", size = 4, fontface = "bold") +
  annotate("text", x = 0.65, y = 0.8, 
           label = "Moderate\n(+2.5°C)", size = 4, fontface = "bold") +
  annotate("text", x = 0.85, y = 0.8, 
           label = "Extreme\n(+4.5°C)", size = 4, fontface = "bold") +
  xlim(0, 1) + ylim(0, 1) +
  theme_void()

# Add table rows
for (i in 1:nrow(transition_table)) {
  y_pos <- 0.7 - (i-1) * 0.15
  transition_plot <- transition_plot +
    annotate("text", x = 0.1, y = y_pos, 
             label = transition_table$location[i], size = 3.5, hjust = 0) +
    annotate("text", x = 0.4, y = y_pos, 
             label = substr(transition_table$baseline[i], 1, 3), size = 3.5, hjust = 0.5) +
    annotate("text", x = 0.65, y = y_pos, 
             label = substr(transition_table$moderate[i], 1, 3), size = 3.5, hjust = 0.5) +
    annotate("text", x = 0.85, y = y_pos, 
             label = substr(transition_table$extreme[i], 1, 3), size = 3.5, hjust = 0.5)
}

# Save transition table
ggsave("climate_zone_transitions_table.svg", transition_plot, 
       width = 10, height = 6, bg = "white")

cat("\n🎯 Premium climate trajectory diagram completed!\n")
cat("Files created:\n")
cat("- southern_africa_climate_trajectory_premium_final.svg (main diagram)\n")
cat("- climate_zone_transitions_table.svg (transition summary)\n")
cat("\nFeatures:\n")
cat("- Full data source citation with DOI and URL\n")
cat("- Major cities labeled with climate zone codes\n")
cat("- Climate zone transition tracking across scenarios\n")
cat("- Professional styling optimized for Figma editing\n")
cat("- Clear time period distinctions (baseline vs projections)\n")