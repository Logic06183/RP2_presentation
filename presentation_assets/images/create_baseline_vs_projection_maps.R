#!/usr/bin/env Rscript
# Create baseline (1991-2020) vs future projection (2071-2099) comparison maps
# Shows climate change impact on southern Africa Köppen-Geiger zones

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
  "16" = "#d1e5f0"   # Cfc - Subpolar oceanic
)

# Köppen-Geiger labels
koppen_labels <- c(
  "1" = "Af", "2" = "Am", "3" = "Aw", "4" = "BWh", "5" = "BWk", 
  "6" = "BSh", "7" = "BSk", "8" = "Csa", "9" = "Csb", "10" = "Csc",
  "11" = "Cwa", "12" = "Cwb", "13" = "Cwc", "14" = "Cfa", "15" = "Cfb", "16" = "Cfc"
)

# Define southern Africa bounds
africa_bounds <- ext(15, 35, -36, -20)

create_climate_map <- function(raster_path, title, subtitle) {
  # Load and crop raster
  koppen_raster <- rast(raster_path)
  koppen_africa <- crop(koppen_raster, africa_bounds)
  
  # Convert to data frame
  koppen_df <- as.data.frame(koppen_africa, xy = TRUE)
  names(koppen_df)[3] <- "koppen_code"
  koppen_df <- koppen_df[!is.na(koppen_df$koppen_code), ]
  
  # Add labels
  koppen_df$climate_zone <- factor(koppen_df$koppen_code, 
                                   levels = as.numeric(names(koppen_labels)),
                                   labels = koppen_labels)
  
  # Create map
  ggplot(koppen_df, aes(x = x, y = y, fill = climate_zone)) +
    geom_raster() +
    scale_fill_manual(values = traditional_koppen_colors,
                      name = "Köppen-Geiger\nClimate Zone",
                      na.value = "white") +
    coord_fixed(ratio = 1, expand = FALSE) +
    labs(
      title = title,
      subtitle = subtitle,
      x = "Longitude (°E)",
      y = "Latitude (°S)"
    ) +
    theme_publication() +
    guides(fill = guide_legend(ncol = 8, byrow = TRUE))
}

# Create baseline map (1991-2020)
cat("Creating baseline map (1991-2020)...\n")
baseline_map <- create_climate_map(
  "high_res_koppen/1991_2020/koppen_geiger_0p00833333.tif",
  "Southern Africa Climate Zones: Baseline Period",
  "Köppen-Geiger Classification 1991-2020 (30-year historical average)"
)

# Create future projection map (2071-2099, SSP2-4.5 moderate scenario)
cat("Creating future projection map (2071-2099, SSP2-4.5)...\n")
future_map <- create_climate_map(
  "high_res_koppen/2071_2099/ssp245/koppen_geiger_0p00833333.tif",
  "Southern Africa Climate Zones: Future Projection",
  "Köppen-Geiger Classification 2071-2099 (SSP2-4.5 scenario)"
)

# Save individual maps
ggsave("southern_africa_baseline_1991_2020.png", baseline_map, 
       width = 12, height = 8, dpi = 300, bg = "white")

ggsave("southern_africa_future_2071_2099_ssp245.png", future_map, 
       width = 12, height = 8, dpi = 300, bg = "white")

# Create comparison plot
comparison_plot <- baseline_map + future_map + 
  plot_layout(ncol = 2) +
  plot_annotation(
    title = "Climate Change Impact on Southern Africa",
    subtitle = "Köppen-Geiger Climate Zone Comparison: Historical vs Future Projections",
    theme = theme(plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
                  plot.subtitle = element_text(size = 12, hjust = 0.5, color = "gray30"))
  )

ggsave("southern_africa_climate_comparison_baseline_vs_future.png", comparison_plot, 
       width = 20, height = 10, dpi = 300, bg = "white")

cat("\n✅ Maps created successfully:\n")
cat("- southern_africa_baseline_1991_2020.png\n")
cat("- southern_africa_future_2071_2099_ssp245.png\n") 
cat("- southern_africa_climate_comparison_baseline_vs_future.png\n")