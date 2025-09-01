#!/usr/bin/env Rscript
# Ultra-smooth Southern Africa Climate Map
# Advanced smoothing techniques to eliminate pixelation

suppressPackageStartupMessages({
  library(sf)
  library(ggplot2)
  library(dplyr)
  library(scales)
  library(rnaturalearth)
  library(rnaturalearthdata)
})

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

# Advanced smoothing function using multiple techniques
ultra_smooth_polygons <- function(climate_data) {
  cat("Applying ultra-smooth processing to climate polygons...\n")
  
  # Transform to equal-area projection for Africa
  africa_proj <- st_transform(climate_data, crs = "+proj=aea +lat_1=20 +lat_2=-23 +lat_0=0 +lon_0=25 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs")
  
  # Method 1: Dissolve by climate type to create larger, smoother polygons
  dissolved <- africa_proj %>%
    group_by(koppen_code, koppen_label) %>%
    summarise(geometry = st_union(geometry), .groups = "drop")
  
  # Method 2: Apply progressive smoothing with multiple buffer iterations
  buffer_distances <- c(2000, -1800, 1500, -1300, 1000, -800)  # Progressive smoothing
  
  smoothed <- dissolved
  for (i in seq_along(buffer_distances)) {
    smoothed <- st_buffer(smoothed, dist = buffer_distances[i])
    cat(sprintf("Applied buffer step %d of %d\n", i, length(buffer_distances)))
  }
  
  # Method 3: Final simplification to remove small artifacts
  smoothed <- st_simplify(smoothed, dTolerance = 500)  # 500m tolerance
  
  # Remove any invalid geometries
  smoothed <- smoothed[st_is_valid(smoothed), ]
  
  # Transform back to WGS84
  final_smooth <- st_transform(smoothed, crs = 4326)
  
  cat("Ultra-smoothing complete\n")
  return(final_smooth)
}

create_ultra_smooth_map <- function() {
  tryCatch({
    cat("Creating ultra-smooth southern Africa climate map...\n")
    
    # Load climate data
    climate_data <- st_read("koppen_africa_with_labels.geojson", quiet = TRUE)
    
    # Get country boundaries
    countries <- ne_countries(scale = "medium", returnclass = "sf")
    
    # Country data
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
    
    # Southern Africa context
    southern_africa_countries <- c("South Africa", "Zimbabwe", "Malawi", 
                                 "Botswana", "Namibia", "Zambia", 
                                 "Mozambique", "Lesotho", "Eswatini")
    
    southern_africa <- countries %>%
      filter(name %in% southern_africa_countries)
    
    # Filter climate to southern Africa
    bbox <- st_bbox(c(xmin = 10, ymin = -35, xmax = 42, ymax = -8), crs = st_crs(4326))
    bbox_poly <- st_as_sfc(bbox)
    climate_southern <- st_filter(climate_data, bbox_poly)
    
    # Apply ultra-smoothing
    climate_ultra_smooth <- ultra_smooth_polygons(climate_southern)
    
    # Create capitals
    capitals_sf <- st_as_sf(country_data, coords = c("capital_lon", "capital_lat"), crs = 4326)
    
    # Create ultra-smooth map
    p <- ggplot() +
      # Ultra-smooth climate zones with gradient-like appearance
      geom_sf(data = climate_ultra_smooth, 
              aes(fill = koppen_code), 
              color = "white",
              linewidth = 0.02,  # Extremely thin borders
              alpha = 0.95) +
      # Subtle country context
      geom_sf(data = southern_africa, 
              fill = NA, 
              color = "white", 
              linewidth = 0.2,
              alpha = 0.6) +
      # Target countries with clean borders
      geom_sf(data = target_countries_sf, 
              fill = NA, 
              aes(color = factor(name)), 
              linewidth = 2.5,
              linetype = "solid") +
      # Capitals with clean styling
      geom_sf(data = capitals_sf, 
              aes(size = gdp_per_capita),
              color = "#E3120B", 
              fill = "white",
              shape = 21,
              stroke = 2.5) +
      # Clean text labels with better contrast
      annotate("text", x = 28.034088 + 4, y = -26.195246 + 2, 
               label = "Johannesburg\nSouth Africa", size = 3.8, fontface = "bold", 
               hjust = 0, color = "black", 
               fill = "white", alpha = 0.8) +
      annotate("text", x = 31.0492 + 4, y = -17.8292 + 2, 
               label = "Harare\nZimbabwe", size = 3.8, fontface = "bold", 
               hjust = 0, color = "black",
               fill = "white", alpha = 0.8) +
      annotate("text", x = 33.7703 + 4, y = -13.9626 + 2, 
               label = "Lilongwe\nMalawi", size = 3.8, fontface = "bold", 
               hjust = 0, color = "black",
               fill = "white", alpha = 0.8) +
      # Enhanced color schemes
      scale_fill_manual(
        name = "Köppen-Geiger Climate Zones",
        values = koppen_colors,
        labels = function(x) {
          ifelse(x %in% names(climate_labels), 
                 paste0(x, " - ", climate_labels[x]), 
                 x)
        },
        guide = guide_legend(
          override.aes = list(alpha = 1, color = "white", linewidth = 0.5),
          ncol = 2
        )
      ) +
      scale_color_manual(
        name = "Study Countries",
        values = c("South Africa" = "#1f77b4", "Zimbabwe" = "#ff7f0e", "Malawi" = "#2ca02c"),
        guide = guide_legend(
          override.aes = list(fill = NA, linewidth = 2.5)
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
        title = "Southern Africa: Ultra-Smooth Climate Zones & Development Context",
        subtitle = "High-fidelity Köppen-Geiger classification for Wellcome Trust climate-health study",
        x = "Longitude (°E)",
        y = "Latitude (°S)"
      ) +
      theme_publication() +
      theme(
        legend.box = "horizontal",
        legend.box.just = "center",
        legend.margin = margin(t = 15),
        plot.margin = margin(20, 20, 20, 20)
      )
    
    return(p)
    
  }, error = function(e) {
    cat(sprintf("Error: %s\n", e$message))
    return(NULL)
  })
}

# Create ultra-smooth map
cat("Creating ultra-smooth climate map...\n")
ultra_map <- create_ultra_smooth_map()

if (!is.null(ultra_map)) {
  # Save ultra-high quality versions
  ggsave("southern_africa_ultra_smooth_climate_map.png", 
         plot = ultra_map,
         width = 16, height = 12, 
         dpi = 400,  # Higher DPI for smoother appearance
         bg = "white")
  
  ggsave("southern_africa_ultra_smooth_climate_map.svg", 
         plot = ultra_map,
         width = 16, height = 12, 
         bg = "white")
  
  cat("Ultra-smooth maps saved:\n")
  cat("- southern_africa_ultra_smooth_climate_map.png (400 DPI)\n")
  cat("- southern_africa_ultra_climate_map.svg\n")
  
} else {
  cat("Failed to create ultra-smooth map\n")
}