#!/usr/bin/env Rscript
# Create warming progression diagram: baseline → moderate → high → extreme scenarios
# Shows climate trajectory under different warming pathways

suppressPackageStartupMessages({
  library(sf)
  library(ggplot2)
  library(dplyr)
  library(scales)
  library(terra)
  library(patchwork)
})

theme_progression <- function() {
  theme_minimal() +
    theme(
      text = element_text(size = 9),
      plot.title = element_text(size = 11, hjust = 0.5, face = "bold"),
      plot.subtitle = element_text(size = 9, hjust = 0.5, color = "gray30"),
      axis.text = element_text(size = 7),
      axis.title = element_text(size = 8),
      legend.title = element_text(size = 8, face = "bold"),
      legend.text = element_text(size = 6),
      legend.position = "none",  # Remove individual legends
      legend.key.size = unit(0.25, "cm"),
      panel.grid = element_line(color = "gray95", linewidth = 0.1),
      panel.background = element_rect(fill = "white", color = NA),
      plot.background = element_rect(fill = "white", color = NA),
      plot.margin = margin(5, 5, 5, 5)
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

create_scenario_map <- function(raster_path, title, subtitle, warming_level) {
  tryCatch({
    cat("Creating", title, "\n")
    
    # Load and process raster
    koppen_raster <- rast(raster_path)
    sa_bbox <- ext(10, 42, -35, -8)
    koppen_sa <- crop(koppen_raster, sa_bbox)
    koppen_sa_agg <- aggregate(koppen_sa, fact = 4, fun = "modal")
    
    # Convert to polygons
    koppen_polygons <- as.polygons(koppen_sa_agg, dissolve = TRUE)
    koppen_sf <- st_as_sf(koppen_polygons)
    
    # Get data column and prepare
    data_col <- names(koppen_sf)[1]
    koppen_sf <- koppen_sf %>%
      filter(!is.na(.data[[data_col]])) %>%
      mutate(climate_code = as.character(.data[[data_col]]))
    
    # Get present codes
    present_codes <- sort(as.numeric(unique(koppen_sf$climate_code)))
    present_colors <- traditional_koppen_colors[as.character(present_codes)]
    
    # Create map with warming indicator
    p <- ggplot() +
      geom_sf(data = koppen_sf, 
              aes(fill = climate_code), 
              color = NA,
              alpha = 0.9) +
      scale_fill_manual(values = present_colors, na.value = "transparent") +
      coord_sf(xlim = c(12, 42), ylim = c(-35, -8), expand = FALSE) +
      labs(
        title = title,
        subtitle = subtitle,
        x = "Longitude (°E)",
        y = "Latitude (°S)"
      ) +
      theme_progression() +
      # Add warming level indicator
      annotate("rect", xmin = 40, xmax = 41.8, ymin = -34.5, ymax = -32.5,
               fill = "white", color = "black", alpha = 0.9) +
      annotate("text", x = 40.9, y = -33.5, 
               label = paste("Warming:\n", warming_level), 
               size = 3, fontface = "bold", hjust = 0.5,
               color = if(warming_level == "Baseline") "green" else if(grepl("Low", warming_level)) "orange" else if(grepl("Moderate", warming_level)) "red" else "darkred")
    
    return(p)
    
  }, error = function(e) {
    cat("❌ Error:", e$message, "\n")
    return(NULL)
  })
}

# Create progression maps
cat("Creating warming progression diagram...\n")

# 1. Baseline (1991-2020)
baseline_map <- create_scenario_map(
  "high_res_koppen/1991_2020/koppen_geiger_0p00833333.tif",
  "Baseline Period",
  "1991-2020 climate normal",
  "Baseline"
)

# 2. Low warming (SSP1-2.6)
low_warming_map <- create_scenario_map(
  "high_res_koppen/2071_2099/ssp126/koppen_geiger_0p00833333.tif",
  "Low Warming",
  "SSP1-2.6 (~1.5°C warming)",
  "Low (+1.5°C)"
)

# 3. Moderate warming (SSP2-4.5)
moderate_warming_map <- create_scenario_map(
  "high_res_koppen/2071_2099/ssp245/koppen_geiger_0p00833333.tif",
  "Moderate Warming",
  "SSP2-4.5 (~2.5°C warming)",
  "Moderate (+2.5°C)"
)

# 4. Extreme warming (SSP5-8.5)
extreme_warming_map <- create_scenario_map(
  "high_res_koppen/2071_2099/ssp585/koppen_geiger_0p00833333.tif",
  "Extreme Warming",
  "SSP5-8.5 (~4.5°C warming)",
  "Extreme (+4.5°C)"
)

# Create combined legend using baseline data (most complete)
baseline_raster <- rast("high_res_koppen/1991_2020/koppen_geiger_0p00833333.tif")
sa_bbox <- ext(10, 42, -35, -8)
baseline_cropped <- crop(baseline_raster, sa_bbox)
baseline_agg <- aggregate(baseline_cropped, fact = 4, fun = "modal")
baseline_polygons <- as.polygons(baseline_agg, dissolve = TRUE)
baseline_sf <- st_as_sf(baseline_polygons)
data_col <- names(baseline_sf)[1]
baseline_sf <- baseline_sf %>%
  filter(!is.na(.data[[data_col]])) %>%
  mutate(climate_code = as.character(.data[[data_col]]))

all_codes <- sort(as.numeric(unique(baseline_sf$climate_code)))
all_colors <- traditional_koppen_colors[as.character(all_codes)]
all_labels <- climate_labels[as.character(all_codes)]

# Create shared legend
legend_plot <- ggplot() +
  geom_point(aes(x = 1, y = 1), alpha = 0) +  # Invisible point
  scale_fill_manual(
    name = "Köppen-Geiger Climate Zones",
    values = all_colors,
    labels = all_labels,
    na.value = "transparent"
  ) +
  theme_void() +
  theme(
    legend.position = "bottom",
    legend.title = element_text(size = 10, face = "bold"),
    legend.text = element_text(size = 8),
    legend.key.size = unit(0.4, "cm")
  ) +
  guides(fill = guide_legend(ncol = 8, byrow = TRUE))

# Create progression diagram
progression_plot <- (baseline_map | low_warming_map) / 
                   (moderate_warming_map | extreme_warming_map) /
                   legend_plot +
  plot_layout(heights = c(1, 1, 0.3)) +
  plot_annotation(
    title = "Southern Africa Climate Change Progression",
    subtitle = "Köppen-Geiger Climate Zones Under Different Warming Scenarios (2071-2099)",
    theme = theme(
      plot.title = element_text(size = 18, face = "bold", hjust = 0.5),
      plot.subtitle = element_text(size = 14, hjust = 0.5, color = "gray30")
    )
  )

# Save the complete progression diagram
ggsave("southern_africa_warming_progression_diagram.svg", progression_plot, 
       width = 24, height = 20, bg = "white")

cat("\n🎯 Warming progression diagram created!\n")
cat("File: southern_africa_warming_progression_diagram.svg\n")
cat("Shows: Baseline → Low → Moderate → Extreme warming scenarios\n")