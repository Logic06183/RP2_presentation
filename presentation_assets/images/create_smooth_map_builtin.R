#!/usr/bin/env Rscript
# Smooth Southern Africa Climate Map using built-in methods
# Uses st_buffer and st_simplify for geometric smoothing

suppressPackageStartupMessages({
  library(sf)
  library(ggplot2)
  library(dplyr)
  library(scales)
  library(rnaturalearth)
  library(rnaturalearthdata)
})

# Set up publication theme
theme_publication <- function() {
  theme_minimal() +
    theme(
      text = element_text(size = 10),
      plot.title = element_text(size = 13, hjust = 0.5, face = "bold"),
      plot.subtitle = element_text(size = 11, hjust = 0.5, color = "gray30"),
      axis.text = element_text(size = 9),
      axis.title = element_text(size = 10),
      legend.title = element_text(size = 10, face = "bold"),
      legend.text = element_text(size = 9),
      legend.position = "bottom",
      legend.key.size = unit(0.4, "cm"),
      panel.grid = element_line(color = "gray90", linewidth = 0.25),
      panel.background = element_rect(fill = "white", color = NA),
      plot.background = element_rect(fill = "white", color = NA)
    )
}

# Define Köppen climate colors
koppen_colors <- c(
  "Af" = "#006837", "Am" = "#31a354", "Aw" = "#74c476", "As" = "#a1d99b",
  "BWh" = "#fee08b", "BWk" = "#fdae61", "BSh" = "#f46d43", "BSk" = "#a50026",
  "BSh/BSk" = "#d73027", "Csa" = "#762a83", "Csb" = "#5aae61", 
  "Cwa" = "#2166ac", "Cwb" = "#5288bd", "Cfa" = "#92c5de", "Cfb" = "#c7eae5"
)

climate_labels <- c(
  "Af" = "Tropical rainforest", "Am" = "Tropical monsoon", "Aw" = "Tropical wet savanna",
  "As" = "Tropical dry savanna", "BWh" = "Hot desert", "BWk" = "Cold desert",
  "BSh" = "Hot semi-arid", "BSk" = "Cold semi-arid", "BSh/BSK" = "Semi-arid variant",
  "Csa" = "Mediterranean hot summer", "Csb" = "Mediterranean warm summer",
  "Cwa" = "Humid subtropical", "Cwb" = "Subtropical highland", "Cfa" = "Humid subtropical", "Cfb" = "Oceanic"
)

smooth_climate_zones <- function(climate_data) {
  cat("Smoothing climate zone boundaries...\n")
  
  # Transform to projected coordinate system for accurate buffering
  climate_proj <- st_transform(climate_data, crs = 3857)  # Web Mercator
  
  # Apply buffer smoothing: small buffer out then in
  buffer_dist <- 500  # 500 meters
  
  smoothed_proj <- climate_proj %>%
    st_buffer(dist = buffer_dist) %>%
    st_buffer(dist = -buffer_dist) %>%
    st_simplify(dTolerance = 100)  # Simplify with 100m tolerance
  
  # Transform back to WGS84
  smoothed <- st_transform(smoothed_proj, crs = 4326)
  
  cat("Applied buffer smoothing with simplification\n")
  return(smoothed)
}

create_smooth_southern_africa_map <- function() {
  tryCatch({
    cat("Creating smooth southern Africa climate map...\n")
    
    # Load climate data
    climate_data <- st_read("koppen_africa_with_labels.geojson", quiet = TRUE)
    
    # Get country boundaries
    countries <- ne_countries(scale = "medium", returnclass = "sf")
    
    # Country data from table
    country_data <- data.frame(
      name = c("South Africa", "Zimbabwe", "Malawi"),
      gdp_per_capita = c(6023, 2156, 520),
      capital_lon = c(28.034088, 31.0492, 33.7703),
      capital_lat = c(-26.195246, -17.8292, -13.9626),
      capital_name = c("Johannesburg", "Harare", "Lilongwe"),
      stringsAsFactors = FALSE
    )
    
    # Filter target countries
    target_countries_sf <- countries %>%
      filter(name %in% country_data$name) %>%
      left_join(country_data, by = "name")
    
    # Get southern Africa region
    southern_africa_countries <- c("South Africa", "Zimbabwe", "Malawi", 
                                 "Botswana", "Namibia", "Zambia", 
                                 "Mozambique", "Lesotho", "Eswatini")
    
    southern_africa <- countries %>%
      filter(name %in% southern_africa_countries)
    
    # Filter climate data to region
    bbox <- st_bbox(c(xmin = 10, ymin = -35, xmax = 42, ymax = -8), crs = st_crs(4326))
    bbox_poly <- st_as_sfc(bbox)
    climate_southern <- st_filter(climate_data, bbox_poly)
    
    # Apply smoothing
    climate_smooth <- smooth_climate_zones(climate_southern)
    
    # Create capitals sf
    capitals_sf <- st_as_sf(country_data, coords = c("capital_lon", "capital_lat"), crs = 4326)
    
    # Create the map with smooth styling
    p <- ggplot() +
      # Plot smoothed climate zones with no borders
      geom_sf(data = climate_smooth, 
              aes(fill = koppen_code), 
              color = "white",
              linewidth = 0.05,  # Very thin borders
              alpha = 0.9) +
      # Add context countries with subtle borders
      geom_sf(data = southern_africa, 
              fill = NA, 
              color = "white", 
              linewidth = 0.3,
              alpha = 0.8) +
      # Highlight target countries
      geom_sf(data = target_countries_sf, 
              fill = NA, 
              aes(color = factor(name)), 
              linewidth = 2,
              linetype = "solid") +
      # Add capitals
      geom_sf(data = capitals_sf, 
              aes(size = gdp_per_capita),
              color = "#E3120B", 
              fill = "white",
              shape = 21,
              stroke = 2) +
      # Add labels
      annotate("text", x = 28.034088 + 3, y = -26.195246 + 1.5, 
               label = "Johannesburg\nSouth Africa", size = 3.5, fontface = "bold", 
               hjust = 0, color = "black") +
      annotate("text", x = 31.0492 + 3, y = -17.8292 + 1.5, 
               label = "Harare\nZimbabwe", size = 3.5, fontface = "bold", 
               hjust = 0, color = "black") +
      annotate("text", x = 33.7703 + 3, y = -13.9626 + 1.5, 
               label = "Lilongwe\nMalawi", size = 3.5, fontface = "bold", 
               hjust = 0, color = "black") +
      # Set colors and styling
      scale_fill_manual(
        name = "Köppen-Geiger Climate Zones",
        values = koppen_colors,
        labels = function(x) {
          ifelse(x %in% names(climate_labels), 
                 paste0(x, " - ", climate_labels[x]), 
                 x)
        },
        guide = guide_legend(
          override.aes = list(alpha = 1, color = "white", linewidth = 0.3),
          ncol = 2
        )
      ) +
      scale_color_manual(
        name = "Study Countries",
        values = c("South Africa" = "#1f77b4", "Zimbabwe" = "#ff7f0e", "Malawi" = "#2ca02c"),
        guide = guide_legend(
          override.aes = list(fill = NA, linewidth = 2)
        )
      ) +
      scale_size_continuous(
        name = "GDP per capita (USD)",
        range = c(4, 8),
        labels = scales::dollar_format(),
        guide = guide_legend(
          override.aes = list(color = "#E3120B", fill = "white", stroke = 2)
        )
      ) +
      coord_sf(xlim = c(12, 40), ylim = c(-35, -8), expand = FALSE) +
      labs(
        title = "Southern Africa: Climate Zones & Development Context",
        subtitle = "Smoothed Köppen-Geiger classification with socioeconomic indicators",
        x = "Longitude (°E)",
        y = "Latitude (°S)"
      ) +
      theme_publication() +
      theme(
        legend.box = "horizontal",
        legend.box.just = "center",
        legend.margin = margin(t = 10)
      )
    
    return(p)
    
  }, error = function(e) {
    cat(sprintf("Error: %s\n", e$message))
    return(NULL)
  })
}

# Create the smooth map
map_smooth <- create_smooth_southern_africa_map()

if (!is.null(map_smooth)) {
  # Save high-quality smooth maps
  ggsave("southern_africa_smooth_climate_map.png", 
         plot = map_smooth,
         width = 14, height = 10, 
         dpi = 300, 
         bg = "white")
  
  ggsave("southern_africa_smooth_climate_map.svg", 
         plot = map_smooth,
         width = 14, height = 10, 
         bg = "white")
  
  cat("Smooth maps saved as southern_africa_smooth_climate_map.png and .svg\n")
  
} else {
  cat("Failed to create smooth map\n")
}