#!/usr/bin/env Rscript
# Create SVG climate maps with time period labels: baseline vs future projection
# Based on working approach from existing successful maps

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
      text = element_text(size = 11),
      plot.title = element_text(size = 14, hjust = 0.5, face = "bold"),
      plot.subtitle = element_text(size = 11, hjust = 0.5, color = "gray30"),
      axis.text = element_text(size = 9),
      axis.title = element_text(size = 10),
      legend.title = element_text(size = 10, face = "bold"),
      legend.text = element_text(size = 8),
      legend.position = "bottom",
      legend.key.size = unit(0.4, "cm"),
      panel.grid = element_line(color = "gray95", linewidth = 0.1),
      panel.background = element_rect(fill = "white", color = NA),
      plot.background = element_rect(fill = "white", color = NA)
    )
}

# Traditional Köppen-Geiger colors
traditional_koppen_colors <- c(
  "1" = "#006837",   # Af - Tropical rainforest
  "2" = "#31a354",   # Am - Tropical monsoon  
  "3" = "#74c476",   # Aw - Tropical savannah
  "4" = "#fee08b",   # BWh - Hot desert
  "5" = "#fdae61",   # BWk - Cold desert
  "6" = "#f46d43",   # BSh - Hot steppe
  "7" = "#a50026",   # BSk - Cold steppe
  "8" = "#762a83",   # Csa - Mediterranean hot
  "9" = "#5aae61",   # Csb - Mediterranean warm
  "10" = "#1a9850",  # Csc - Mediterranean cold
  "11" = "#2166ac",  # Cwa - Humid subtropical
  "12" = "#5288bd",  # Cwb - Subtropical highland
  "13" = "#7fcdbb",  # Cwc - Subtropical cold
  "14" = "#92c5de",  # Cfa - Humid temperate
  "15" = "#c7eae5",  # Cfb - Oceanic
  "16" = "#d1e5f0",  # Cfc - Subpolar oceanic
  "17" = "#762a83",  # Dsa
  "18" = "#5aae61",  # Dsb
  "19" = "#1a9850",  # Dsc
  "20" = "#006837",  # Dsd
  "21" = "#2166ac",  # Dwa
  "22" = "#5288bd",  # Dwb
  "23" = "#7fcdbb",  # Dwc
  "24" = "#92c5de",  # Dwd
  "25" = "#c7eae5",  # Dfa
  "26" = "#d1e5f0",  # Dfb
  "27" = "#74c476",  # Dfc
  "28" = "#fee08b",  # Dfd
  "29" = "#888888",  # ET - Tundra
  "30" = "#444444"   # EF - Ice cap
)

climate_labels <- c(
  "1" = "Af", "2" = "Am", "3" = "Aw", "4" = "BWh", "5" = "BWk", 
  "6" = "BSh", "7" = "BSk", "8" = "Csa", "9" = "Csb", "10" = "Csc",
  "11" = "Cwa", "12" = "Cwb", "13" = "Cwc", "14" = "Cfa", "15" = "Cfb", 
  "16" = "Cfc", "17" = "Dsa", "18" = "Dsb", "19" = "Dsc", "20" = "Dsd",
  "21" = "Dwa", "22" = "Dwb", "23" = "Dwc", "24" = "Dwd", "25" = "Dfa",
  "26" = "Dfb", "27" = "Dfc", "28" = "Dfd", "29" = "ET", "30" = "EF"
)

create_climate_map <- function(raster_path, title, subtitle, output_file) {
  cat("Processing:", title, "\n")
  
  # Load raster
  koppen_raster <- rast(raster_path)
  
  # Define southern Africa bounds (same as successful maps)
  africa_bounds <- ext(14, 36, -36, -18)
  
  # Crop to region of interest
  koppen_africa <- crop(koppen_raster, africa_bounds)
  
  # Aggregate slightly to reduce file size while maintaining detail
  koppen_africa <- aggregate(koppen_africa, fact = 2, fun = "modal")
  
  # Convert to data frame for ggplot
  koppen_df <- as.data.frame(koppen_africa, xy = TRUE)
  names(koppen_df)[3] <- "koppen_code"
  
  # Remove NA values
  koppen_df <- koppen_df[!is.na(koppen_df$koppen_code), ]
  
  # Convert to factor with labels
  koppen_df$climate_zone <- factor(koppen_df$koppen_code,
                                   levels = 1:30,
                                   labels = climate_labels[1:30])
  
  # Filter to only zones present in the data
  present_zones <- unique(koppen_df$climate_zone)
  present_zones <- present_zones[!is.na(present_zones)]
  
  # Create map
  p <- ggplot(koppen_df, aes(x = x, y = y, fill = climate_zone)) +
    geom_raster() +
    scale_fill_manual(values = traditional_koppen_colors,
                      name = "Köppen-Geiger Climate Zone",
                      na.value = "white",
                      drop = FALSE) +
    coord_fixed(ratio = 1, expand = FALSE) +
    labs(
      title = title,
      subtitle = subtitle,
      x = "Longitude (°E)",
      y = "Latitude (°S)"
    ) +
    theme_publication() +
    guides(fill = guide_legend(ncol = 6, byrow = TRUE))
  
  # Save as SVG
  ggsave(output_file, p, width = 14, height = 10, bg = "white")
  cat("✅ Saved:", output_file, "\n")
  
  return(p)
}

# Create baseline map (1991-2020)
baseline_map <- create_climate_map(
  "high_res_koppen/1991_2020/koppen_geiger_0p00833333.tif",
  "Southern Africa Climate Zones: Historical Baseline",
  "Köppen-Geiger Classification 1991-2020 (30-year climate normal)",
  "southern_africa_baseline_1991_2020.svg"
)

# Create future projection map (2071-2099, SSP2-4.5 moderate scenario)
future_map <- create_climate_map(
  "high_res_koppen/2071_2099/ssp245/koppen_geiger_0p00833333.tif",
  "Southern Africa Climate Zones: Future Projection",
  "Köppen-Geiger Classification 2071-2099 (SSP2-4.5 moderate warming)",
  "southern_africa_future_2071_2099_ssp245.svg"
)

# Create side-by-side comparison
comparison_plot <- baseline_map + future_map + 
  plot_layout(ncol = 2) +
  plot_annotation(
    title = "Climate Change Impact on Southern Africa Köppen-Geiger Zones",
    subtitle = "Comparison: Historical Baseline (1991-2020) vs Future Projection (2071-2099, SSP2-4.5)",
    theme = theme(
      plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
      plot.subtitle = element_text(size = 12, hjust = 0.5, color = "gray30")
    )
  )

ggsave("southern_africa_climate_comparison_baseline_vs_future.svg", comparison_plot, 
       width = 24, height = 12, bg = "white")

cat("\n🎯 All SVG maps created successfully!\n")
cat("Files generated:\n")
cat("- southern_africa_baseline_1991_2020.svg\n")
cat("- southern_africa_future_2071_2099_ssp245.svg\n")
cat("- southern_africa_climate_comparison_baseline_vs_future.svg\n")