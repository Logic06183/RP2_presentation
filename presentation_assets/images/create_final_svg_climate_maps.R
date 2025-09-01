#!/usr/bin/env Rscript
# Create final working SVG climate maps: baseline vs future projection
# Fixed approach based on successful polygon conversion

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

climate_labels_traditional <- c(
  "1" = "Af", "2" = "Am", "3" = "Aw", "4" = "BWh", "5" = "BWk", 
  "6" = "BSh", "7" = "BSk", "8" = "Csa", "9" = "Csb", "10" = "Csc",
  "11" = "Cwa", "12" = "Cwb", "13" = "Cwc", "14" = "Cfa", "15" = "Cfb", 
  "16" = "Cfc", "17" = "Dsa", "18" = "Dsb", "19" = "Dsc", "20" = "Dsd",
  "21" = "Dwa", "22" = "Dwb", "23" = "Dwc", "24" = "Dwd", "25" = "Dfa",
  "26" = "Dfb", "27" = "Dfc", "28" = "Dfd", "29" = "ET", "30" = "EF"
)

create_working_climate_map <- function(raster_path, title, subtitle, output_file) {
  tryCatch({
    cat("Processing:", output_file, "\n")
    
    # Load raster
    koppen_raster <- rast(raster_path)
    
    # Define southern Africa bounds
    sa_bbox <- ext(10, 42, -35, -8)
    koppen_sa <- crop(koppen_raster, sa_bbox)
    
    # Aggregate to reduce complexity for polygon conversion
    koppen_sa_agg <- aggregate(koppen_sa, fact = 4, fun = "modal")
    
    # Convert to polygons with error handling
    koppen_polygons <- as.polygons(koppen_sa_agg, dissolve = TRUE)
    koppen_sf <- st_as_sf(koppen_polygons)
    
    # Get the actual column name (it's always the first non-geometry column)
    data_col <- names(koppen_sf)[1]
    cat("Data column name:", data_col, "\n")
    
    # Prepare data with proper filtering
    koppen_sf <- koppen_sf %>%
      filter(!is.na(.data[[data_col]])) %>%
      mutate(climate_code = as.character(.data[[data_col]]))
    
    # Get unique codes present in this dataset
    present_codes <- unique(koppen_sf$climate_code)
    cat("Present climate codes:", paste(sort(as.numeric(present_codes)), collapse = ", "), "\n")
    
    # Filter colors and labels to only those present
    present_colors <- traditional_koppen_colors[present_codes]
    present_labels <- climate_labels_traditional[present_codes]
    
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
      guides(fill = guide_legend(ncol = 3, byrow = TRUE))
    
    # Save as SVG
    ggsave(output_file, p, width = 16, height = 12, bg = "white")
    cat("✅ Successfully saved:", output_file, "\n\n")
    
    return(p)
    
  }, error = function(e) {
    cat("❌ Error creating", output_file, ":", e$message, "\n\n")
    return(NULL)
  })
}

# Create baseline map (1991-2020)
cat("Creating baseline map...\n")
baseline_map <- create_working_climate_map(
  "high_res_koppen/1991_2020/koppen_geiger_0p00833333.tif",
  "Southern Africa Climate Zones: Historical Baseline",
  "Köppen-Geiger Classification 1991-2020 (30-year climate normal)",
  "southern_africa_baseline_1991_2020_final.svg"
)

# Create future projection map (2071-2099, SSP2-4.5)
cat("Creating future projection map...\n")
future_map <- create_working_climate_map(
  "high_res_koppen/2071_2099/ssp245/koppen_geiger_0p00833333.tif",
  "Southern Africa Climate Zones: Future Projection",
  "Köppen-Geiger Classification 2071-2099 (SSP2-4.5 moderate warming)",
  "southern_africa_future_2071_2099_ssp245_final.svg"
)

cat("🎯 Processing complete!\n")