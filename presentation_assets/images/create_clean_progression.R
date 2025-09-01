#!/usr/bin/env Rscript
# Create clean warming progression: Baseline → Moderate → Extreme (3 panels)
# Focus on key scenarios without overwhelming detail

suppressPackageStartupMessages({
  library(sf)
  library(ggplot2)
  library(dplyr)
  library(terra)
  library(patchwork)
})

theme_clean <- function() {
  theme_minimal() +
    theme(
      text = element_text(size = 10),
      plot.title = element_text(size = 12, hjust = 0.5, face = "bold"),
      plot.subtitle = element_text(size = 9, hjust = 0.5, color = "gray30"),
      axis.text = element_text(size = 8),
      axis.title = element_text(size = 9),
      legend.position = "none",
      panel.grid = element_line(color = "gray95", linewidth = 0.1),
      panel.background = element_rect(fill = "white", color = NA),
      plot.background = element_rect(fill = "white", color = NA),
      plot.margin = margin(10, 10, 10, 10)
    )
}

# Köppen-Geiger colors and labels
koppen_colors <- c(
  "2" = "#31a354", "3" = "#74c476", "4" = "#fee08b", "5" = "#fdae61", 
  "6" = "#f46d43", "7" = "#a50026", "8" = "#762a83", "9" = "#5aae61",
  "11" = "#2166ac", "12" = "#5288bd", "13" = "#7fcdbb", "14" = "#92c5de", 
  "15" = "#c7eae5", "23" = "#7fcdbb", "26" = "#d1e5f0", "29" = "#888888"
)

koppen_names <- c(
  "2" = "Am - Tropical monsoon", "3" = "Aw - Tropical savannah", 
  "4" = "BWh - Hot desert", "5" = "BWk - Cold desert",
  "6" = "BSh - Hot semi-arid", "7" = "BSk - Cold semi-arid",
  "8" = "Csa - Mediterranean hot", "9" = "Csb - Mediterranean warm",
  "11" = "Cwa - Humid subtropical", "12" = "Cwb - Subtropical highland",
  "13" = "Cwc - Subtropical cold", "14" = "Cfa - Humid temperate",
  "15" = "Cfb - Oceanic", "23" = "Dwc - Cold, dry winter",
  "26" = "Dfb - Cold, no dry season", "29" = "ET - Tundra"
)

create_clean_map <- function(raster_path, title, subtitle, warming_color) {
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
  
  # Filter colors to present codes
  present_codes <- unique(koppen_sf$climate_code)
  present_colors <- koppen_colors[present_codes]
  present_colors <- present_colors[!is.na(present_colors)]
  
  # Create map
  ggplot() +
    geom_sf(data = koppen_sf, 
            aes(fill = climate_code), 
            color = NA, alpha = 0.9) +
    scale_fill_manual(values = present_colors, na.value = "transparent") +
    coord_sf(xlim = c(12, 42), ylim = c(-35, -8), expand = FALSE) +
    labs(title = title, subtitle = subtitle, x = "Longitude (°E)", y = "Latitude (°S)") +
    theme_clean() +
    # Add warming level indicator
    annotate("rect", xmin = 38, xmax = 41.5, ymin = -34, ymax = -32,
             fill = warming_color, color = "black", alpha = 0.8) +
    annotate("text", x = 39.75, y = -33, 
             label = if(grepl("Baseline", title)) "CURRENT" else "FUTURE", 
             size = 3.5, fontface = "bold", color = "white")
}

# Create three key scenarios
cat("Creating 3-panel progression diagram...\n")

baseline <- create_clean_map(
  "high_res_koppen/1991_2020/koppen_geiger_0p00833333.tif",
  "Baseline Climate",
  "1991-2020 (30-year normal)",
  "#2d8659"  # Green for current
)

moderate <- create_clean_map(
  "high_res_koppen/2071_2099/ssp245/koppen_geiger_0p00833333.tif",
  "Moderate Warming",
  "2071-2099 SSP2-4.5 (+2.5°C)",
  "#d73502"  # Orange-red for moderate
)

extreme <- create_clean_map(
  "high_res_koppen/2071_2099/ssp585/koppen_geiger_0p00833333.tif",
  "Extreme Warming",
  "2071-2099 SSP5-8.5 (+4.5°C)",
  "#67000d"  # Dark red for extreme
)

# Create shared legend
legend_data <- data.frame(
  code = names(koppen_colors),
  label = koppen_names[names(koppen_colors)],
  color = unname(koppen_colors)
)
legend_data <- legend_data[!is.na(legend_data$label), ]

legend_plot <- ggplot(legend_data, aes(x = 1, y = code, fill = code)) +
  geom_point(alpha = 0) +  # Invisible points
  scale_fill_manual(
    name = "Köppen-Geiger Climate Zones",
    values = koppen_colors,
    labels = koppen_names,
    na.value = "transparent"
  ) +
  theme_void() +
  theme(
    legend.position = "bottom",
    legend.title = element_text(size = 11, face = "bold"),
    legend.text = element_text(size = 8),
    legend.key.size = unit(0.4, "cm")
  ) +
  guides(fill = guide_legend(ncol = 4, byrow = TRUE))

# Combine into progression diagram
progression <- baseline + moderate + extreme + 
  plot_layout(nrow = 1) +
  plot_annotation(
    title = "Southern Africa Climate Change Trajectory",
    subtitle = "Köppen-Geiger Climate Zones: Current Conditions → Future Scenarios",
    caption = "Data: Beck et al. (2023) 1km Köppen-Geiger maps | Baseline: 1991-2020 | Projections: 2071-2099",
    theme = theme(
      plot.title = element_text(size = 18, face = "bold", hjust = 0.5),
      plot.subtitle = element_text(size = 14, hjust = 0.5, color = "gray30"),
      plot.caption = element_text(size = 9, hjust = 0.5, color = "gray50")
    )
  )

# Add legend below
final_diagram <- progression / legend_plot + 
  plot_layout(heights = c(1, 0.25))

# Save final diagram
ggsave("southern_africa_climate_trajectory_baseline_to_extreme.svg", final_diagram, 
       width = 28, height = 16, bg = "white")

cat("\n🎯 Clean progression diagram created!\n")
cat("File: southern_africa_climate_trajectory_baseline_to_extreme.svg\n")
cat("Shows: Current (1991-2020) → Moderate warming (+2.5°C) → Extreme warming (+4.5°C)\n")