#!/usr/bin/env Rscript
# 1km Resolution Map with Traditional Köppen-Geiger Colors
# Using standard scientific color scheme + climate zone labels

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

# Traditional Köppen-Geiger colors (Peel et al. standard scientific scheme)
# These avoid blue tones that could be confused with ocean
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
  "11" = "#2166ac",  # Cwa - Humid subtropical (blue - but darker, less ocean-like)
  "12" = "#5288bd",  # Cwb - Subtropical highland (medium blue)
  "13" = "#7fcdbb",  # Cwc - Subtropical cold (teal)
  "14" = "#92c5de",  # Cfa - Humid temperate (light blue)
  "15" = "#c7eae5",  # Cfb - Oceanic (very light blue-green)
  "16" = "#d1e5f0",  # Cfc - Subpolar oceanic (pale blue)
  "17" = "#8e0152",  # Dsa - Continental hot dry (dark purple)
  "18" = "#c51b8a",  # Dsb - Continental warm dry (magenta)
  "19" = "#de77ae",  # Dsc - Continental cold dry (pink)
  "20" = "#f1b6da",  # Dsd - Continental very cold dry (light pink)
  "21" = "#4575b4",  # Dwa - Continental hot (dark blue)
  "22" = "#74add1",  # Dwb - Continental warm (medium blue)
  "23" = "#abd9e9",  # Dwc - Continental cold (light blue)
  "24" = "#e0f3f8",  # Dwd - Continental very cold (very light blue)
  "25" = "#313695",  # Dfa - Continental humid hot (very dark blue)
  "26" = "#4575b4",  # Dfb - Continental humid warm (dark blue)
  "27" = "#74add1",  # Dfc - Continental humid cold (medium blue)
  "28" = "#abd9e9",  # Dfd - Continental humid very cold (light blue)
  "29" = "#d9d9d9",  # ET - Tundra (light gray)
  "30" = "#969696"   # EF - Ice cap (gray)
)

# Climate zone labels with codes
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

# Function to extract climate zone at specific coordinates
extract_climate_at_point <- function(raster, lon, lat) {
  point <- vect(data.frame(x = lon, y = lat), geom = c("x", "y"), crs = "EPSG:4326")
  climate_value <- extract(raster, point)[1, 2]
  return(as.character(climate_value))
}

create_traditional_1km_map <- function() {
  tryCatch({
    cat("Creating 1km map with traditional Köppen-Geiger colors...\n")
    
    # Load 1km resolution data
    koppen_raster <- rast("high_res_koppen/1991_2020/koppen_geiger_0p00833333.tif")
    
    # Define study locations
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
      
      cat(sprintf("%s (%s): Climate zone %s - %s\n", 
                  study_locations$city[i], 
                  study_locations$country[i],
                  climate_code,
                  climate_labels_traditional[climate_code]))
    }
    
    # Crop raster to southern Africa
    sa_bbox <- ext(10, 42, -35, -8)
    koppen_sa <- crop(koppen_raster, sa_bbox)
    
    # Convert to smooth polygons
    cat("Converting to smooth polygons...\n")
    koppen_polygons <- as.polygons(koppen_sa, dissolve = TRUE)
    koppen_sf <- st_as_sf(koppen_polygons)
    
    koppen_sf <- koppen_sf %>%
      filter(!is.na(koppen_geiger_0p00833333)) %>%
      mutate(climate_code = as.character(koppen_geiger_0p00833333))
    
    # Create sf objects for locations
    cities_sf <- st_as_sf(study_locations, coords = c("lon", "lat"), crs = 4326)
    
    # Create the map with traditional colors
    p <- ggplot() +
      # Ultra-smooth climate zones with traditional colors
      geom_sf(data = koppen_sf, 
              aes(fill = climate_code), 
              color = NA,  # No borders for maximum smoothness
              alpha = 0.9) +
      # Study locations with GDP-based sizing
      geom_sf(data = cities_sf, 
              aes(size = gdp),
              color = "#E3120B", 
              fill = "white",
              shape = 21,
              stroke = 2.5) +
      # City and country labels
      geom_sf_text(data = cities_sf,
                   aes(label = paste0(city, "\n", country)),
                   nudge_x = 3.5, nudge_y = 1.5,
                   size = 3.5, fontface = "bold",
                   color = "black") +
      # Climate zone labels for each location
      geom_sf_text(data = cities_sf,
                   aes(label = paste0("Climate: ", substr(climate_label, 1, 3))),
                   nudge_x = 3.5, nudge_y = 0.5,
                   size = 2.8, fontface = "italic",
                   color = "gray20") +
      # Traditional Köppen-Geiger color scheme
      scale_fill_manual(
        name = "Köppen-Geiger Climate Zones (Traditional Colors)",
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
        range = c(4, 9),
        labels = scales::dollar_format(),
        guide = guide_legend(
          override.aes = list(color = "#E3120B", fill = "white", stroke = 2.5)
        )
      ) +
      coord_sf(xlim = c(12, 40), ylim = c(-35, -8), expand = FALSE) +
      labs(
        title = "Southern Africa: Climate Zones with Traditional Scientific Colors",
        subtitle = "1km resolution Köppen-Geiger classification (Beck et al. 2023) - Standard color scheme",
        x = "Longitude (°E)",
        y = "Latitude (°S)"
      ) +
      theme_publication() +
      theme(
        legend.box = "horizontal",
        legend.box.just = "center"
      )
    
    return(list(map = p, locations = study_locations))
    
  }, error = function(e) {
    cat(sprintf("Error: %s\n", e$message))
    return(NULL)
  })
}

# Create the map with traditional colors
result <- create_traditional_1km_map()

if (!is.null(result)) {
  map_traditional <- result$map
  locations_data <- result$locations
  
  # Save with traditional colors
  ggsave("southern_africa_1km_traditional_colors.png", 
         plot = map_traditional,
         width = 16, height = 12, 
         dpi = 600,
         bg = "white")
  
  ggsave("southern_africa_1km_traditional_colors.svg", 
         plot = map_traditional,
         width = 16, height = 12, 
         bg = "white")
  
  # Save location climate data
  write.csv(locations_data, "study_locations_climate_zones.csv", row.names = FALSE)
  
  cat("\n✅ SUCCESS: Traditional color maps created!\n")
  cat("- southern_africa_1km_traditional_colors.png\n")
  cat("- southern_africa_1km_traditional_colors.svg\n")
  cat("- study_locations_climate_zones.csv\n")
  
  cat("\n📍 Climate zones for study locations:\n")
  for (i in 1:nrow(locations_data)) {
    cat(sprintf("• %s, %s: %s\n", 
                locations_data$city[i], 
                locations_data$country[i], 
                locations_data$climate_label[i]))
  }
  
} else {
  cat("❌ Failed to create traditional color map\n")
}