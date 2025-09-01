#!/usr/bin/env Rscript
# Create side-by-side comparison SVG maps with consistent scaling

suppressPackageStartupMessages({
  library(sf)
  library(ggplot2)
  library(dplyr)
  library(scales)
  library(terra)
  library(patchwork)
})

theme_publication <- function() {
  theme_minimal() +
    theme(
      text = element_text(size = 10),
      plot.title = element_text(size = 13, hjust = 0.5, face = "bold"),
      plot.subtitle = element_text(size = 10, hjust = 0.5, color = "gray30"),
      axis.text = element_text(size = 8),
      axis.title = element_text(size = 9),
      legend.title = element_text(size = 9, face = "bold"),
      legend.text = element_text(size = 7),
      legend.position = "bottom",
      legend.key.size = unit(0.3, "cm"),
      panel.grid = element_line(color = "gray95", linewidth = 0.1),
      panel.background = element_rect(fill = "white", color = NA),
      plot.background = element_rect(fill = "white", color = NA)
    )
}

# Traditional Köppen-Geiger colors
traditional_koppen_colors <- c(
  "1" = "#006837", "2" = "#31a354", "3" = "#74c476", "4" = "#fee08b", "5" = "#fdae61", 
  "6" = "#f46d43", "7" = "#a50026", "8" = "#762a83", "9" = "#5aae61", "10" = "#1a9850",
  "11" = "#2166ac", "12" = "#5288bd", "13" = "#7fcdbb", "14" = "#92c5de", "15" = "#c7eae5", 
  "16" = "#d1e5f0", "17" = "#762a83", "18" = "#5aae61", "19" = "#1a9850", "20" = "#006837",
  "21" = "#2166ac", "22" = "#5288bd", "23" = "#7fcdbb", "24" = "#92c5de", "25" = "#c7eae5",
  "26" = "#d1e5f0", "27" = "#74c476", "28" = "#fee08b", "29" = "#888888", "30" = "#444444"
)

climate_labels <- c(
  "1" = "Af", "2" = "Am", "3" = "Aw", "4" = "BWh", "5" = "BWk", 
  "6" = "BSh", "7" = "BSk", "8" = "Csa", "9" = "Csb", "10" = "Csc",
  "11" = "Cwa", "12" = "Cwb", "13" = "Cwc", "14" = "Cfa", "15" = "Cfb", 
  "16" = "Cfc", "17" = "Dsa", "18" = "Dsb", "19" = "Dsc", "20" = "Dsd",
  "21" = "Dwa", "22" = "Dwb", "23" = "Dwc", "24" = "Dwd", "25" = "Dfa",
  "26" = "Dfb", "27" = "Dfc", "28" = "Dfd", "29" = "ET", "30" = "EF"
)

create_climate_map_final <- function(raster_path, title, subtitle) {
  # Load raster
  koppen_raster <- rast(raster_path)
  
  # Define southern Africa bounds
  sa_bbox <- ext(10, 42, -35, -8)
  koppen_sa <- crop(koppen_raster, sa_bbox)
  
  # Aggregate slightly to improve processing
  koppen_sa_agg <- aggregate(koppen_sa, fact = 4, fun = "modal")
  
  # Convert to polygons
  koppen_polygons <- as.polygons(koppen_sa_agg, dissolve = TRUE)
  koppen_sf <- st_as_sf(koppen_polygons)
  
  # Get data column name
  data_col <- names(koppen_sf)[1]
  
  # Prepare data
  koppen_sf <- koppen_sf %>%
    filter(!is.na(.data[[data_col]])) %>%
    mutate(climate_code = as.character(.data[[data_col]]))
  
  # Get present codes for this dataset
  present_codes <- sort(as.numeric(unique(koppen_sf$climate_code)))
  cat("Present codes in", title, ":", paste(present_codes, collapse = ", "), "\n")
  
  # Filter to present codes only
  present_colors <- traditional_koppen_colors[as.character(present_codes)]
  present_labels <- climate_labels[as.character(present_codes)]
  
  # Create map
  p <- ggplot() +
    geom_sf(data = koppen_sf, 
            aes(fill = climate_code), 
            color = NA,
            alpha = 0.9) +
    scale_fill_manual(
      name = "Köppen-Geiger\nClimate Zone",
      values = present_colors,
      labels = present_labels,
      na.value = "transparent"
    ) +
    coord_sf(xlim = c(12, 42), ylim = c(-35, -8), expand = FALSE) +
    labs(
      title = title,
      subtitle = subtitle,
      x = "Longitude (°E)",
      y = "Latitude (°S)"
    ) +
    theme_publication() +
    guides(fill = guide_legend(ncol = 4, byrow = TRUE))
  
  return(p)
}

# Create both maps
cat("Creating baseline map (1991-2020)...\n")
baseline_map <- create_climate_map_final(
  "high_res_koppen/1991_2020/koppen_geiger_0p00833333.tif",
  "Historical Baseline (1991-2020)",
  "30-year climate normal"
)

cat("Creating future projection map (2071-2099)...\n")
future_map <- create_climate_map_final(
  "high_res_koppen/2071_2099/ssp245/koppen_geiger_0p00833333.tif",
  "Future Projection (2071-2099)",
  "SSP2-4.5 moderate warming scenario"
)

# Save individual maps
ggsave("southern_africa_baseline_1991_2020_individual.svg", baseline_map, 
       width = 14, height = 10, bg = "white")

ggsave("southern_africa_future_2071_2099_individual.svg", future_map, 
       width = 14, height = 10, bg = "white")

# Create side-by-side comparison
comparison_plot <- baseline_map + future_map + 
  plot_layout(ncol = 2) +
  plot_annotation(
    title = "Southern Africa Climate Change Impact",
    subtitle = "Köppen-Geiger Climate Zones: Baseline vs Future Projection",
    theme = theme(
      plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
      plot.subtitle = element_text(size = 12, hjust = 0.5, color = "gray30")
    )
  )

ggsave("southern_africa_baseline_vs_future_comparison.svg", comparison_plot, 
       width = 26, height = 12, bg = "white")

cat("\n🎯 All SVG maps successfully created!\n")
cat("Files:\n")
cat("- southern_africa_baseline_1991_2020_individual.svg\n")
cat("- southern_africa_future_2071_2099_individual.svg\n") 
cat("- southern_africa_baseline_vs_future_comparison.svg\n")