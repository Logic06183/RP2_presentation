#!/usr/bin/env Rscript
# Final enhanced climate trajectory diagram with full annotations and sources

suppressPackageStartupMessages({
  library(sf)
  library(ggplot2)
  library(dplyr)
  library(terra)
  library(patchwork)
  library(tidyr)  # For pivot_wider
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
premium_colors <- c(
  "2" = "#228B22", "3" = "#9ACD32", "4" = "#FFD700", "5" = "#FF8C00", 
  "6" = "#FF6347", "7" = "#DC143C", "8" = "#8B008B", "9" = "#32CD32",
  "11" = "#4169E1", "12" = "#6495ED", "13" = "#00CED1", "14" = "#87CEEB", 
  "15" = "#B0E0E6", "23" = "#20B2AA", "26" = "#D3D3D3", "29" = "#708090"
)

koppen_labels <- c(
  "2" = "Am", "3" = "Aw", "4" = "BWh", "5" = "BWk", "6" = "BSh", "7" = "BSk",
  "8" = "Csa", "9" = "Csb", "11" = "Cwa", "12" = "Cwb", "13" = "Cwc", 
  "14" = "Cfa", "15" = "Cfb", "23" = "Dwc", "26" = "Dfb", "29" = "ET"
)

# Cities
cities <- data.frame(
  city = c("Lilongwe", "Harare", "Johannesburg", "Cape Town"),
  country = c("Malawi", "Zimbabwe", "South Africa", "South Africa"),
  lon = c(33.7703, 31.0492, 28.0341, 18.4241),
  lat = c(-13.9626, -17.8292, -26.1952, -33.9249)
)

extract_climate_at_point <- function(raster, lon, lat) {
  point <- vect(data.frame(x = lon, y = lat), geom = c("x", "y"), crs = "EPSG:4326")
  climate_value <- extract(raster, point)[1, 2]
  return(as.character(climate_value))
}

create_annotated_map <- function(raster_path, title, subtitle, warming_color, scenario_label, scenario_key) {
  # Process raster
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
  
  # Extract climate for each city in this scenario
  city_climates <- cities
  for (i in 1:nrow(cities)) {
    climate_code <- extract_climate_at_point(koppen_raster, cities$lon[i], cities$lat[i])
    city_climates$climate_code[i] <- climate_code
    city_climates$climate_label[i] <- koppen_labels[climate_code]
  }
  
  present_codes <- unique(koppen_sf$climate_code)
  present_colors <- premium_colors[present_codes]
  present_colors <- present_colors[!is.na(present_colors)]
  
  # Create map
  ggplot() +
    geom_sf(data = koppen_sf, 
            aes(fill = climate_code), 
            color = "white", linewidth = 0.1, alpha = 0.85) +
    scale_fill_manual(values = present_colors, na.value = "transparent") +
    
    # City points
    geom_point(data = city_climates, 
               aes(x = lon, y = lat), 
               size = 5, color = "white", fill = "#D2691E", 
               shape = 21, stroke = 2.5) +
    
    # City annotations with climate zones
    geom_label(data = city_climates,
               aes(x = lon + 2.2, y = lat + 1.2, 
                   label = paste0(city, "\n", climate_label)),
               size = 3, fontface = "bold", hjust = 0,
               fill = "white", color = "black", alpha = 0.95,
               label.padding = unit(0.25, "lines")) +
    
    coord_sf(xlim = c(12, 42), ylim = c(-35, -8), expand = FALSE) +
    labs(title = title, subtitle = subtitle, 
         x = "Longitude (°E)", y = "Latitude (°S)") +
    theme_premium() +
    
    # Scenario indicator
    annotate("rect", xmin = 38, xmax = 41.8, ymin = -34.8, ymax = -31,
             fill = warming_color, color = "white", alpha = 0.95, linewidth = 1.2) +
    annotate("text", x = 39.9, y = -32.9, 
             label = scenario_label, 
             size = 4.2, fontface = "bold", color = "white", lineheight = 0.85)
}

# Create all three maps
baseline_map <- create_annotated_map(
  "high_res_koppen/1991_2020/koppen_geiger_0p00833333.tif",
  "Current Climate Zones", "1991-2020 Baseline Period",
  "#2E8B57", "BASELINE\n1991-2020", "baseline"
)

moderate_map <- create_annotated_map(
  "high_res_koppen/2071_2099/ssp245/koppen_geiger_0p00833333.tif",
  "Moderate Warming", "SSP2-4.5 Scenario (+2.5°C)",
  "#FF8C00", "MODERATE\n+2.5°C\n2071-2099", "moderate"
)

extreme_map <- create_annotated_map(
  "high_res_koppen/2071_2099/ssp585/koppen_geiger_0p00833333.tif",
  "Extreme Warming", "SSP5-8.5 Scenario (+4.5°C)",
  "#DC143C", "EXTREME\n+4.5°C\n2071-2099", "extreme"
)

# Create comprehensive legend
legend_comprehensive <- ggplot() +
  geom_point(aes(x = 1, y = 1), alpha = 0) +
  scale_fill_manual(
    name = "Köppen-Geiger Climate Classification",
    values = premium_colors,
    labels = paste(names(koppen_labels), "-", koppen_labels),
    na.value = "transparent"
  ) +
  theme_void() +
  theme(
    legend.position = "bottom",
    legend.title = element_text(family = "Arial", size = 12, face = "bold"),
    legend.text = element_text(family = "Arial", size = 8),
    legend.key.size = unit(0.4, "cm"),
    legend.margin = margin(t = 20),
    legend.box.spacing = unit(1, "cm")
  ) +
  guides(fill = guide_legend(ncol = 8, byrow = TRUE))

# Final comprehensive diagram
final_enhanced <- baseline_map + moderate_map + extreme_map + 
  plot_layout(nrow = 1) +
  plot_annotation(
    title = "Southern Africa Climate Change Trajectory: Köppen-Geiger Zone Evolution",
    subtitle = "Current Climate Conditions → Future Warming Scenarios (Major Cities Annotated)",
    caption = paste(
      "Data Source: Beck, H.E., T.R. McVicar, N. Vergopolan, A. Berg, N.J. Lutsko, A. Dufour, Z. Zeng, X. Jiang,",
      "A.I.J.M. van Dijk, and D.G. Miralles (2023). High-resolution (1 km) Köppen-Geiger maps for 1901–2099",
      "based on constrained CMIP6 projections. Scientific Data 10, 724. DOI: 10.1038/s41597-023-02549-6",
      "Available at: https://figshare.com/articles/dataset/21789074",
      "",
      "Baseline: 1991-2020 (30-year climate normal) | Future Projections: 2071-2099 CMIP6 scenarios",
      sep = "\n"
    ),
    theme = theme(
      plot.title = element_text(family = "Arial", size = 20, face = "bold", hjust = 0.5, margin = margin(b = 8)),
      plot.subtitle = element_text(family = "Arial", size = 14, hjust = 0.5, color = "gray30", margin = margin(b = 12)),
      plot.caption = element_text(family = "Arial", size = 8, hjust = 0.5, color = "gray50", 
                                  lineheight = 1.4, margin = margin(t = 25))
    )
  )

final_with_legend <- final_enhanced / legend_comprehensive + 
  plot_layout(heights = c(1, 0.22))

# Save final enhanced diagram
ggsave("southern_africa_climate_trajectory_enhanced_annotated.svg", final_with_legend, 
       width = 38, height = 24, bg = "white", device = "svg")

cat("\n✅ Enhanced climate trajectory diagram completed!\n")
cat("File: southern_africa_climate_trajectory_enhanced_annotated.svg\n")
cat("Ready for Figma editing and presentation use.\n")