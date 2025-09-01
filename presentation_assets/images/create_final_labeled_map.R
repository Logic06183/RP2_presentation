#!/usr/bin/env Rscript
# Final Southern Africa Climate Map with Traditional Colors & Zone Labels
# 1km resolution with climate zone callouts for each study location

suppressPackageStartupMessages({
  library(sf)
  library(ggplot2)
  library(dplyr)
  library(scales)
  library(terra)
})

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

# Traditional Köppen-Geiger colors (avoiding ocean-blue confusion)
traditional_koppen_colors <- c(
  "1" = "#006837",   # Af - Tropical rainforest (dark green)
  "2" = "#31a354",   # Am - Tropical monsoon (medium green)  
  "3" = "#74c476",   # Aw - Tropical savannah (light green)
  "4" = "#fee08b",   # BWh - Hot desert (yellow)
  "5" = "#fdae61",   # BWk - Cold desert (orange)
  "6" = "#f46d43",   # BSh - Hot steppe (red-orange)
  "7" = "#a50026",   # BSk - Cold steppe (dark red)
  "8" = "#762a83",   # Csa - Mediterranean hot (purple)
  "9" = "#5aae61",   # Csb - Mediterranean warm (green)
  "10" = "#1a9850",  # Csc - Mediterranean cold (dark green)
  "11" = "#2166ac",  # Cwa - Humid subtropical (blue)
  "12" = "#5288bd",  # Cwb - Subtropical highland (medium blue)
  "13" = "#7fcdbb",  # Cwc - Subtropical cold (teal)
  "14" = "#92c5de",  # Cfa - Humid temperate (light blue)
  "15" = "#c7eae5",  # Cfb - Oceanic (very light blue-green)
  "16" = "#d1e5f0"   # Cfc - Subpolar oceanic (pale blue)
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

# Function to extract climate at coordinates
extract_climate_at_point <- function(raster, lon, lat) {
  point <- vect(data.frame(x = lon, y = lat), geom = c("x", "y"), crs = "EPSG:4326")
  climate_value <- extract(raster, point)[1, 2]
  return(as.character(climate_value))
}

create_final_labeled_map <- function() {
  tryCatch({
    cat("Creating final labeled 1km resolution climate map...\n")
    
    # Load 1km data
    koppen_raster <- rast("high_res_koppen/1991_2020/koppen_geiger_0p00833333.tif")
    
    # Study locations
    study_locations <- data.frame(
      country = c("South Africa", "Zimbabwe", "Malawi"),
      city = c("Johannesburg", "Harare", "Lilongwe"),
      lon = c(28.034088, 31.0492, 33.7703),
      lat = c(-26.195246, -17.8292, -13.9626),
      gdp = c(6023, 2156, 520),
      stringsAsFactors = FALSE
    )
    
    # Extract climate zones for each location
    for (i in 1:nrow(study_locations)) {
      climate_code <- extract_climate_at_point(koppen_raster, 
                                              study_locations$lon[i], 
                                              study_locations$lat[i])
      study_locations$climate_code[i] <- climate_code
      study_locations$climate_label[i] <- climate_labels_traditional[climate_code]
      
      cat(sprintf("%s: %s\n", study_locations$city[i], study_locations$climate_label[i]))
    }
    
    # Process raster data
    sa_bbox <- ext(10, 42, -35, -8)
    koppen_sa <- crop(koppen_raster, sa_bbox)
    
    # Convert to smooth polygons
    koppen_polygons <- as.polygons(koppen_sa, dissolve = TRUE)
    koppen_sf <- st_as_sf(koppen_polygons)
    
    koppen_sf <- koppen_sf %>%
      filter(!is.na(koppen_geiger_0p00833333)) %>%
      mutate(climate_code = as.character(koppen_geiger_0p00833333))
    
    cities_sf <- st_as_sf(study_locations, coords = c("lon", "lat"), crs = 4326)
    
    # Create final map with traditional colors and prominent labels
    p <- ggplot() +
      # Ultra-smooth 1km resolution climate zones
      geom_sf(data = koppen_sf, 
              aes(fill = climate_code), 
              color = NA,
              alpha = 0.9) +
      # Study cities
      geom_sf(data = cities_sf, 
              aes(size = gdp),
              color = "#E3120B", 
              fill = "white",
              shape = 21,
              stroke = 3) +
      # City labels with enhanced visibility
      annotate("text", x = 28.034088 + 4, y = -26.195246 + 2.5, 
               label = "Johannesburg\nSouth Africa", 
               size = 4, fontface = "bold", hjust = 0, color = "black") +
      annotate("text", x = 31.0492 + 4, y = -17.8292 + 2.5, 
               label = "Harare\nZimbabwe", 
               size = 4, fontface = "bold", hjust = 0, color = "black") +
      annotate("text", x = 33.7703 + 4, y = -13.9626 + 2.5, 
               label = "Lilongwe\nMalawi", 
               size = 4, fontface = "bold", hjust = 0, color = "black") +
      # Climate zone callouts for each location
      annotate("rect", xmin = 28.034088 + 3.5, xmax = 28.034088 + 8, 
               ymin = -26.195246 - 0.5, ymax = -26.195246 + 0.5,
               fill = "white", color = "black", alpha = 0.9) +
      annotate("text", x = 28.034088 + 5.75, y = -26.195246, 
               label = "Cwb - Subtropical highland", 
               size = 3, fontface = "bold", color = "#5288bd") +
      
      annotate("rect", xmin = 31.0492 + 3.5, xmax = 31.0492 + 8, 
               ymin = -17.8292 - 0.5, ymax = -17.8292 + 0.5,
               fill = "white", color = "black", alpha = 0.9) +
      annotate("text", x = 31.0492 + 5.75, y = -17.8292, 
               label = "Cwb - Subtropical highland", 
               size = 3, fontface = "bold", color = "#5288bd") +
      
      annotate("rect", xmin = 33.7703 + 3.5, xmax = 33.7703 + 8, 
               ymin = -13.9626 - 0.5, ymax = -13.9626 + 0.5,
               fill = "white", color = "black", alpha = 0.9) +
      annotate("text", x = 33.7703 + 5.75, y = -13.9626, 
               label = "Cwa - Humid subtropical", 
               size = 3, fontface = "bold", color = "#2166ac") +
      
      # Traditional color scheme
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
      scale_size_continuous(
        name = "GDP per capita (USD)",
        range = c(5, 10),
        labels = scales::dollar_format(),
        guide = guide_legend(
          override.aes = list(color = "#E3120B", fill = "white", stroke = 3)
        )
      ) +
      coord_sf(xlim = c(12, 42), ylim = c(-35, -8), expand = FALSE) +
      labs(
        title = "Southern Africa: 1km Climate Zones with Traditional Colors",
        subtitle = "Köppen-Geiger classification (Beck et al. 2023) - Study location climate zones highlighted",
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

# Create final labeled map
final_map <- create_final_labeled_map()

if (!is.null(final_map)) {
  ggsave("southern_africa_final_1km_labeled.png", 
         plot = final_map,
         width = 18, height = 12, 
         dpi = 600,
         bg = "white")
  
  ggsave("southern_africa_final_1km_labeled.svg", 
         plot = final_map,
         width = 18, height = 12, 
         bg = "white")
  
  cat("✅ FINAL MAP CREATED with traditional colors and climate labels!\n")
  cat("- southern_africa_final_1km_labeled.png\n")
  cat("- southern_africa_final_1km_labeled.svg\n")
  
} else {
  cat("❌ Failed to create final labeled map\n")
}