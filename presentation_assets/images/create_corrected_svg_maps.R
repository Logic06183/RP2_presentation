#!/usr/bin/env Rscript
# Create corrected SVG climate maps using polygon approach from successful maps
# Baseline (1991-2020) vs Future Projection (2071-2099)

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
      plot.title = element_text(size = 14, hjust = 0.5, face = "bold"),
      plot.subtitle = element_text(size = 11, hjust = 0.5, color = "gray30"),
      axis.text = element_text(size = 9),
      axis.title = element_text(size = 10),
      legend.title = element_text(size = 10, face = "bold"),
      legend.text = element_text(size = 8),
      legend.position = "bottom",
      legend.key.size = unit(0.35, "cm"),
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

climate_labels_traditional <- c(
  "1" = "Af - Tropical rainforest",
  "2" = "Am - Tropical monsoon", 
  "3" = "Aw - Tropical savannah",
  "4" = "BWh - Hot desert",
  "5" = "BWk - Cold desert",
  "6" = "BSh - Hot semi-arid",
  "7" = "BSk - Cold semi-arid",
  "8" = "Csa - Mediterranean hot",
  "9" = "Csb - Mediterranean warm",
  "10" = "Csc - Mediterranean cold",
  "11" = "Cwa - Humid subtropical",
  "12" = "Cwb - Subtropical highland",
  "13" = "Cwc - Subtropical cold",
  "14" = "Cfa - Humid temperate",
  "15" = "Cfb - Oceanic",
  "16" = "Cfc - Subpolar oceanic"
)

create_climate_map_corrected <- function(raster_path, title, subtitle, output_file) {
  tryCatch({
    cat("Creating map:", title, "\n")
    
    # Load raster (using polygon approach like successful maps)
    koppen_raster <- rast(raster_path)
    
    # Define southern Africa bounds
    sa_bbox <- ext(10, 42, -35, -8)
    koppen_sa <- crop(koppen_raster, sa_bbox)
    
    # Convert to smooth polygons (key step from successful maps)
    cat("Converting to polygons...\n")
    koppen_polygons <- as.polygons(koppen_sa, dissolve = TRUE)
    koppen_sf <- st_as_sf(koppen_polygons)
    
    # Get the column name (it varies between files)
    data_col <- names(koppen_sf)[1]
    
    # Clean and prepare data
    koppen_sf <- koppen_sf %>%
      filter(!is.na(.data[[data_col]])) %>%
      mutate(climate_code = as.character(.data[[data_col]]))
    
    cat("Data prepared, creating plot...\n")
    
    # Create map using the successful approach
    p <- ggplot() +
      geom_sf(data = koppen_sf, 
              aes(fill = climate_code), 
              color = NA,
              alpha = 0.9) +
      scale_fill_manual(
        name = "Köppen-Geiger Climate Zones",
        values = traditional_koppen_colors,
        labels = function(x) climate_labels_traditional[x],
        na.value = "transparent",
        guide = guide_legend(
          override.aes = list(alpha = 1),
          ncol = 3
        )
      ) +
      coord_sf(xlim = c(12, 42), ylim = c(-35, -8), expand = FALSE) +
      labs(
        title = title,
        subtitle = subtitle,
        x = "Longitude (°E)",
        y = "Latitude (°S)"
      ) +
      theme_publication()
    
    # Save as SVG
    ggsave(output_file, p, width = 16, height = 12, bg = "white")
    cat("✅ Saved:", output_file, "\n")
    
    return(p)
    
  }, error = function(e) {
    cat("❌ Error creating map:", e$message, "\n")
    return(NULL)
  })
}

# Create corrected maps
baseline_map <- create_climate_map_corrected(
  "high_res_koppen/1991_2020/koppen_geiger_0p00833333.tif",
  "Southern Africa Climate Zones: Historical Baseline (1991-2020)",
  "Köppen-Geiger Classification - 30-year climate normal period",
  "southern_africa_baseline_1991_2020_corrected.svg"
)

future_map <- create_climate_map_corrected(
  "high_res_koppen/2071_2099/ssp245/koppen_geiger_0p00833333.tif",
  "Southern Africa Climate Zones: Future Projection (2071-2099)",
  "Köppen-Geiger Classification - SSP2-4.5 moderate warming scenario",
  "southern_africa_future_2071_2099_ssp245_corrected.svg"
)

# Create comparison if both maps succeeded
if (!is.null(baseline_map) && !is.null(future_map)) {
  comparison_plot <- baseline_map + future_map + 
    plot_layout(ncol = 2) +
    plot_annotation(
      title = "Climate Change Impact on Southern Africa",
      subtitle = "Köppen-Geiger Zones: Baseline (1991-2020) vs Future Projection (2071-2099, SSP2-4.5)",
      theme = theme(
        plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
        plot.subtitle = element_text(size = 12, hjust = 0.5, color = "gray30")
      )
    )
  
  ggsave("southern_africa_climate_comparison_corrected.svg", comparison_plot, 
         width = 28, height = 14, bg = "white")
  
  cat("✅ Comparison map saved: southern_africa_climate_comparison_corrected.svg\n")
}

cat("\n🎯 Corrected SVG maps completed!\n")