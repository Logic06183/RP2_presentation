#!/usr/bin/env Rscript
# Simple 1km Resolution Climate Map
# Using basic terra and sf packages only

suppressPackageStartupMessages({
  library(sf)
  library(ggplot2)
  library(dplyr)
  library(scales)
  library(terra)
})

# Publication theme
theme_publication <- function() {
  theme_minimal() +
    theme(
      text = element_text(size = 10),
      plot.title = element_text(size = 14, hjust = 0.5, face = "bold"),
      plot.subtitle = element_text(size = 12, hjust = 0.5, color = "gray30"),
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

# Köppen climate colors (simplified for main African zones)
koppen_colors_africa <- c(
  "1" = "#0000ff",   # Af - Tropical rainforest
  "2" = "#0078ff",   # Am - Tropical monsoon  
  "3" = "#46aafa",   # Aw - Tropical savannah
  "4" = "#ff0000",   # BWh - Hot desert
  "5" = "#ff9696",   # BWk - Cold desert
  "6" = "#f5a500",   # BSh - Hot steppe
  "7" = "#ffdc64",   # BSk - Cold steppe
  "8" = "#ffff00",   # Csa - Mediterranean hot
  "9" = "#c8c800",   # Csb - Mediterranean warm
  "11" = "#96ff96",  # Cwa - Humid subtropical hot
  "12" = "#64c864",  # Cwb - Subtropical highland
  "13" = "#329632",  # Cwc - Subtropical cold
  "14" = "#c8ff50",  # Cfa - Humid subtropical
  "15" = "#64ff50",  # Cfb - Oceanic
  "16" = "#32c800"   # Cfc - Subpolar oceanic
)

climate_labels_africa <- c(
  "1" = "Tropical rainforest",
  "2" = "Tropical monsoon", 
  "3" = "Tropical savannah",
  "4" = "Hot desert",
  "5" = "Cold desert",
  "6" = "Hot semi-arid",
  "7" = "Cold semi-arid",
  "8" = "Mediterranean hot",
  "9" = "Mediterranean warm",
  "11" = "Humid subtropical",
  "12" = "Subtropical highland",
  "13" = "Subtropical cold",
  "14" = "Humid temperate",
  "15" = "Oceanic",
  "16" = "Subpolar oceanic"
)

create_1km_map <- function() {
  tryCatch({
    cat("Creating 1km resolution climate map for southern Africa...\n")
    
    # Load ultra high-resolution raster
    koppen_raster <- rast("high_res_koppen/1991_2020/koppen_geiger_0p00833333.tif")
    
    # Define southern Africa bounds
    sa_bbox <- ext(10, 42, -35, -8)
    
    # Crop to region
    koppen_sa <- crop(koppen_raster, sa_bbox)
    
    cat(sprintf("Cropped to %d x %d pixels for southern Africa\n", 
                ncol(koppen_sa), nrow(koppen_sa)))
    
    # Convert to polygons with dissolve for smooth boundaries
    cat("Converting to smooth vector polygons...\n")
    koppen_polygons <- as.polygons(koppen_sa, dissolve = TRUE)
    koppen_sf <- st_as_sf(koppen_polygons)
    
    # Clean data
    koppen_sf <- koppen_sf %>%
      filter(!is.na(koppen_geiger_0p00833333)) %>%
      mutate(climate_code = as.character(koppen_geiger_0p00833333)) %>%
      select(climate_code, geometry)
    
    # Study countries and cities
    study_countries <- data.frame(
      country = c("South Africa", "Zimbabwe", "Malawi"),
      gdp = c(6023, 2156, 520),
      city = c("Johannesburg", "Harare", "Lilongwe"),
      lon = c(28.034088, 31.0492, 33.7703),
      lat = c(-26.195246, -17.8292, -13.9626),
      stringsAsFactors = FALSE
    )
    
    cities_sf <- st_as_sf(study_countries, coords = c("lon", "lat"), crs = 4326)
    
    # Create ultra-smooth map
    p <- ggplot() +
      # Ultra high-resolution climate zones (1km data)
      geom_sf(data = koppen_sf, 
              aes(fill = climate_code), 
              color = NA,  # No borders for maximum smoothness
              alpha = 0.95) +
      # Add city points
      geom_sf(data = cities_sf, 
              aes(size = gdp),
              color = "#E3120B", 
              fill = "white",
              shape = 21,
              stroke = 2.5) +
      # City labels with country names
      geom_sf_text(data = cities_sf,
                   aes(label = paste0(city, "\n", country)),
                   nudge_x = 2, nudge_y = 1,
                   size = 3.5, fontface = "bold",
                   color = "black") +
      # Color mapping
      scale_fill_manual(
        name = "Köppen-Geiger Climate (1km resolution)",
        values = koppen_colors_africa,
        labels = climate_labels_africa,
        na.value = "transparent",
        guide = guide_legend(
          override.aes = list(alpha = 1),
          ncol = 3
        )
      ) +
      scale_size_continuous(
        name = "GDP per capita (USD)",
        range = c(4, 9),
        labels = scales::dollar_format(),
        guide = guide_legend(
          override.aes = list(color = "#E3120B", fill = "white", stroke = 2.5)
        )
      ) +
      coord_sf(xlim = c(12, 40), ylim = c(-35, -8), expand = FALSE) +
      labs(
        title = "Southern Africa: Ultra High-Resolution Climate Zones",
        subtitle = "Beck et al. (2023) 1km Köppen-Geiger classification - smooth boundaries",
        x = "Longitude (°E)",
        y = "Latitude (°S)"
      ) +
      theme_publication() +
      theme(
        legend.box = "horizontal",
        legend.box.just = "center"
      )
    
    return(p)
    
  }, error = function(e) {
    cat(sprintf("Error: %s\n", e$message))
    return(NULL)
  })
}

# Create the 1km map
cat("Starting 1km resolution map creation...\n")
map_1km <- create_1km_map()

if (!is.null(map_1km)) {
  # Save ultra high-quality versions
  ggsave("southern_africa_1km_resolution_smooth.png", 
         plot = map_1km,
         width = 16, height = 12, 
         dpi = 600,
         bg = "white")
  
  ggsave("southern_africa_1km_resolution_smooth.svg", 
         plot = map_1km,
         width = 16, height = 12, 
         bg = "white")
  
  cat("✅ SUCCESS: Ultra high-resolution maps created!\n")
  cat("- southern_africa_1km_resolution_smooth.png (600 DPI)\n")
  cat("- southern_africa_1km_resolution_smooth.svg\n")
  
} else {
  cat("❌ Failed to create 1km map\n")
}