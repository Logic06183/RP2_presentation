#!/usr/bin/env Rscript
# Complete final diagram with comprehensive legend and data sources
# Based on the publication-ready version with added climate zone key

suppressPackageStartupMessages({
  library(sf)
  library(ggplot2)
  library(dplyr)
  library(terra)
  library(patchwork)
})

theme_final <- function() {
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
      plot.margin = margin(12, 12, 12, 12)
    )
}

# Enhanced colors for maximum clarity
final_colors <- c(
  "2" = "#228B22", "3" = "#90EE90", "4" = "#FFD700", "5" = "#FF8C00", 
  "6" = "#FF6347", "7" = "#DC143C", "8" = "#8B008B", "9" = "#32CD32",
  "11" = "#1E90FF", "12" = "#4169E1", "13" = "#00CED1", "14" = "#87CEEB", 
  "15" = "#B0E0E6", "23" = "#20B2AA", "26" = "#D3D3D3", "29" = "#696969"
)

# Complete climate zone descriptions
complete_zone_names <- c(
  "2" = "Am - Tropical monsoon",
  "3" = "Aw - Tropical savannah", 
  "4" = "BWh - Hot desert",
  "5" = "BWk - Cold desert",
  "6" = "BSh - Hot semi-arid",
  "7" = "BSk - Cold semi-arid",
  "8" = "Csa - Mediterranean hot summer",
  "9" = "Csb - Mediterranean warm summer",
  "11" = "Cwa - Humid subtropical",
  "12" = "Cwb - Subtropical highland",
  "13" = "Cwc - Subtropical cold",
  "14" = "Cfa - Humid temperate",
  "15" = "Cfb - Oceanic",
  "23" = "Dwc - Cold, dry winter",
  "26" = "Dfb - Cold, no dry season",
  "29" = "ET - Tundra"
)

# Cities with climate zone assignments for each scenario
cities_complete <- data.frame(
  city = c("Lilongwe", "Harare", "Johannesburg", "Cape Town"),
  country = c("Malawi", "Zimbabwe", "South Africa", "South Africa"),
  lon = c(33.7703, 31.0492, 28.0341, 18.4241),
  lat = c(-13.9626, -17.8292, -26.1952, -33.9249),
  baseline_zone = c("Cwa", "Cwb", "Cwb", "Csa"),
  moderate_zone = c("Cwa", "Cwb", "Cwa", "Csa"), 
  extreme_zone = c("Aw", "Cwa", "Cwa", "BWh"),
  stringsAsFactors = FALSE
)

create_final_scenario_map <- function(raster_path, title, subtitle, warming_color, scenario_label, zone_column) {
  # Process raster data
  koppen_raster <- rast(raster_path)
  sa_bbox <- ext(10, 42, -35, -8)
  koppen_sa <- crop(koppen_raster, sa_bbox)
  koppen_sa_agg <- aggregate(koppen_sa, fact = 4, fun = "modal")
  
  koppen_polygons <- as.polygons(koppen_sa_agg, dissolve = TRUE)
  koppen_sf <- st_as_sf(koppen_polygons)
  
  data_col <- names(koppen_sf)[1]
  koppen_sf <- koppen_sf %>%
    filter(!is.na(.data[[data_col]])) %>%
    mutate(climate_code = as.character(.data[[data_col]]))
  
  # Get city zones for this scenario
  city_data <- cities_complete
  city_data$current_zone <- city_data[[zone_column]]
  
  present_codes <- unique(koppen_sf$climate_code)
  present_colors <- final_colors[present_codes]
  present_colors <- present_colors[!is.na(present_colors)]
  
  # Create map
  ggplot() +
    geom_sf(data = koppen_sf, 
            aes(fill = climate_code), 
            color = "white", linewidth = 0.1, alpha = 0.85) +
    scale_fill_manual(values = present_colors, na.value = "transparent") +
    
    # Country labels
    annotate("text", x = 34, y = -12, label = "MALAWI", 
             size = 4.5, fontface = "bold", color = "gray25", alpha = 0.8) +
    annotate("text", x = 30, y = -19, label = "ZIMBABWE", 
             size = 4.5, fontface = "bold", color = "gray25", alpha = 0.8) +
    annotate("text", x = 24, y = -29, label = "SOUTH AFRICA", 
             size = 4.5, fontface = "bold", color = "gray25", alpha = 0.8) +
    
    # City points
    geom_point(data = city_data, 
               aes(x = lon, y = lat), 
               size = 6, color = "white", fill = "#B22222", 
               shape = 21, stroke = 3) +
    
    # City labels with climate zones
    geom_label(data = city_data,
               aes(x = lon + 2.5, y = lat + 1, 
                   label = paste0(city, "\n(", current_zone, ")")),
               size = 3.2, fontface = "bold", hjust = 0,
               fill = "white", color = "black", alpha = 0.95,
               label.padding = unit(0.3, "lines"),
               label.r = unit(0.15, "lines")) +
    
    coord_sf(xlim = c(12, 42), ylim = c(-35, -8), expand = FALSE) +
    labs(title = title, subtitle = subtitle, 
         x = "Longitude (°E)", y = "Latitude (°S)") +
    theme_final() +
    
    # Scenario indicator
    annotate("rect", xmin = 38, xmax = 41.8, ymin = -34.8, ymax = -30.8,
             fill = warming_color, color = "white", alpha = 0.95, linewidth = 1.5) +
    annotate("text", x = 39.9, y = -32.8, 
             label = scenario_label, 
             size = 4.5, fontface = "bold", color = "white", lineheight = 0.8)
}

# Create all three scenario maps
cat("Creating complete final diagram with comprehensive legend...\n")

baseline_complete <- create_final_scenario_map(
  "high_res_koppen/1991_2020/koppen_geiger_0p00833333.tif",
  "Current Climate", "1991-2020 Baseline",
  "#2E8B57", "BASELINE\n1991-2020", "baseline_zone"
)

moderate_complete <- create_final_scenario_map(
  "high_res_koppen/2071_2099/ssp245/koppen_geiger_0p00833333.tif",
  "Moderate Warming", "SSP2-4.5 (+2.5°C)",
  "#FF8C00", "MODERATE\n+2.5°C\n2071-2099", "moderate_zone"
)

extreme_complete <- create_final_scenario_map(
  "high_res_koppen/2071_2099/ssp585/koppen_geiger_0p00833333.tif",
  "Extreme Warming", "SSP5-8.5 (+4.5°C)",
  "#DC143C", "EXTREME\n+4.5°C\n2071-2099", "extreme_zone"
)

# Create comprehensive legend with full zone descriptions
# Get all zones that appear across all scenarios
all_zones_present <- c("2", "3", "4", "5", "6", "7", "8", "9", "11", "12", "13", "14", "15", "23", "26", "29")
legend_colors <- final_colors[all_zones_present]
legend_labels <- complete_zone_names[all_zones_present]

# Create the legend as a separate plot
legend_comprehensive <- ggplot() +
  geom_point(aes(x = 1, y = 1), alpha = 0) +  # Invisible point for scale
  scale_fill_manual(
    name = "Köppen-Geiger Climate Classification Key",
    values = legend_colors,
    labels = legend_labels,
    na.value = "transparent"
  ) +
  theme_void() +
  theme(
    legend.position = "bottom",
    legend.title = element_text(family = "Arial", size = 12, face = "bold", margin = margin(b = 8)),
    legend.text = element_text(family = "Arial", size = 9),
    legend.key.size = unit(0.5, "cm"),
    legend.margin = margin(t = 20),
    legend.box.spacing = unit(0.5, "cm")
  ) +
  guides(fill = guide_legend(ncol = 4, byrow = TRUE))

# Assemble complete diagram
complete_diagram <- baseline_complete + moderate_complete + extreme_complete + 
  plot_layout(nrow = 1) +
  plot_annotation(
    title = "Southern Africa Climate Change Trajectory",
    subtitle = "Köppen-Geiger Climate Zone Evolution: Current Conditions → Future Warming Scenarios",
    caption = paste(
      "Data Source: Beck, H.E., T.R. McVicar, N. Vergopolan, A. Berg, N.J. Lutsko, A. Dufour, Z. Zeng, X. Jiang,",
      "A.I.J.M. van Dijk, and D.G. Miralles (2023). High-resolution (1 km) Köppen-Geiger maps for 1901–2099",
      "based on constrained CMIP6 projections. Scientific Data 10, 724.",
      "DOI: 10.1038/s41597-023-02549-6 | Available: https://figshare.com/articles/dataset/21789074",
      "",
      "Timeline: Baseline (1991-2020 climate normal) → Future Projections (2071-2099 CMIP6 scenarios)",
      "Major cities annotated with climate zone codes for each scenario",
      sep = "\n"
    ),
    theme = theme(
      plot.title = element_text(family = "Arial", size = 22, face = "bold", hjust = 0.5, margin = margin(b = 10)),
      plot.subtitle = element_text(family = "Arial", size = 16, hjust = 0.5, color = "gray30", margin = margin(b = 15)),
      plot.caption = element_text(family = "Arial", size = 9, hjust = 0.5, color = "gray50", 
                                  lineheight = 1.3, margin = margin(t = 20))
    )
  )

# Add comprehensive legend
final_with_complete_legend <- complete_diagram / legend_comprehensive + 
  plot_layout(heights = c(1, 0.3))

# Save the complete diagram
ggsave("southern_africa_climate_trajectory_complete_with_legend.svg", final_with_complete_legend, 
       width = 42, height = 28, bg = "white", device = "svg")

cat("\n🎯 Complete climate trajectory diagram with full legend created!\n")
cat("File: southern_africa_climate_trajectory_complete_with_legend.svg\n")
cat("\nIncludes:\n")
cat("✅ Full Köppen-Geiger climate zone definitions\n")
cat("✅ Complete data source citation with DOI\n")
cat("✅ Major cities with climate zone codes for each scenario\n")
cat("✅ Professional styling for presentations\n")
cat("✅ Ready for Figma editing (SVG format)\n")