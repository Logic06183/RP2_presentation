#!/usr/bin/env Rscript
# Southern Africa Köppen-Geiger climate zones for Wellcome Trust grant
# Focus on Malawi, South Africa, and Zimbabwe
# Built on existing africa_climate_study_locations_r.svg methodology

# Load required libraries
suppressPackageStartupMessages({
  library(sf)
  library(ggplot2)
  library(dplyr)
  library(scales)
  library(rnaturalearth)
  library(rnaturalearthdata)
})

# Set up publication theme (same as original)
theme_publication <- function() {
  theme_minimal() +
    theme(
      text = element_text(size = 12),
      plot.title = element_text(size = 14, hjust = 0.5, face = "bold"),
      plot.subtitle = element_text(size = 12, hjust = 0.5, color = "gray30"),
      axis.text = element_text(size = 10),
      axis.title = element_text(size = 11),
      legend.title = element_text(size = 11, face = "bold"),
      legend.text = element_text(size = 10),
      legend.position = "bottom",
      legend.key.size = unit(0.5, "cm"),
      panel.grid = element_line(color = "gray90", linewidth = 0.25),
      panel.background = element_rect(fill = "white", color = NA),
      plot.background = element_rect(fill = "white", color = NA),
      legend.background = element_rect(fill = "white", color = "gray70", linewidth = 0.5)
    )
}

# Define Köppen climate colors (same as original)
koppen_colors <- c(
  "Af" = "#006837",      # Tropical rainforest - dark green
  "Am" = "#31a354",      # Tropical monsoon - medium green
  "Aw" = "#74c476",      # Tropical wet savanna - light green
  "As" = "#a1d99b",      # Tropical dry savanna - very light green
  "BWh" = "#fee08b",     # Hot desert - yellow
  "BWk" = "#fdae61",     # Cold desert - orange
  "BSh" = "#f46d43",     # Hot semi-arid - red-orange
  "BSk" = "#a50026",     # Cold semi-arid - dark red
  "BSh/BSk" = "#d73027", # Semi-arid variant - red
  "Csa" = "#762a83",     # Mediterranean hot summer - purple
  "Csb" = "#5aae61",     # Mediterranean warm summer - green
  "Cwa" = "#2166ac",     # Humid subtropical - blue
  "Cwb" = "#5288bd",     # Subtropical highland - medium blue
  "Cfa" = "#92c5de",     # Humid subtropical - light blue
  "Cfb" = "#c7eae5",     # Oceanic - very light blue
  "Dfb" = "#4575b4",     # Continental warm summer - dark blue
  "Dsa" = "#313695"      # Continental hot dry summer - very dark blue
)

# Define climate zone descriptions (same as original)
climate_labels <- c(
  "Af" = "Tropical rainforest",
  "Am" = "Tropical monsoon",
  "Aw" = "Tropical wet savanna",
  "As" = "Tropical dry savanna",
  "BWh" = "Hot desert",
  "BWk" = "Cold desert",
  "BSh" = "Hot semi-arid",
  "BSk" = "Cold semi-arid",
  "BSh/BSK" = "Semi-arid variant",
  "Csa" = "Mediterranean hot summer",
  "Csb" = "Mediterranean warm summer",
  "Cwa" = "Humid subtropical",
  "Cwb" = "Subtropical highland",
  "Cfa" = "Humid subtropical",
  "Cfb" = "Oceanic",
  "Dfb" = "Continental warm summer",
  "Dsa" = "Continental hot dry summer"
)

create_southern_africa_climate_map <- function() {
  tryCatch({
    cat("Loading Köppen-Geiger climate data for southern Africa...\n")
    
    # Load the existing climate data
    climate_data <- st_read("koppen_africa_with_labels.geojson", quiet = TRUE)
    
    # Get country boundaries for southern Africa
    countries <- ne_countries(scale = "medium", returnclass = "sf")
    
    # Filter for southern Africa countries (including our target countries)
    southern_africa_countries <- c("South Africa", "Zimbabwe", "Malawi", 
                                 "Botswana", "Namibia", "Zambia", 
                                 "Mozambique", "Lesotho", "Eswatini")
    
    southern_africa <- countries %>%
      filter(name %in% southern_africa_countries)
    
    # Define target countries for highlighting
    target_countries <- c("South Africa", "Zimbabwe", "Malawi")
    target_countries_sf <- countries %>%
      filter(name %in% target_countries)
    
    # Crop climate data to southern Africa region
    # Define southern Africa bounding box
    bbox <- st_bbox(c(xmin = 10, ymin = -35, xmax = 42, ymax = -8), crs = st_crs(4326))
    bbox_poly <- st_as_sfc(bbox)
    
    # Filter climate data to southern Africa region
    climate_southern <- st_filter(climate_data, bbox_poly)
    
    cat(sprintf("Filtered to %d climate polygons in southern Africa\n", nrow(climate_southern)))
    cat(sprintf("Climate zones in region: %s\n", paste(sort(unique(climate_southern$koppen_code)), collapse = ", ")))
    
    # Major cities in target countries for reference
    cities <- data.frame(
      name = c("Cape Town", "Johannesburg", "Harare", "Lilongwe", "Durban", "Bulawayo", "Blantyre"),
      country = c("South Africa", "South Africa", "Zimbabwe", "Malawi", "South Africa", "Zimbabwe", "Malawi"),
      lon = c(18.4241, 28.0473, 31.0492, 33.7703, 31.0218, 28.5906, 35.0044),
      lat = c(-33.9249, -26.2041, -17.8292, -13.9626, -29.8587, -20.1501, -15.7861),
      size = c(4.6, 5.8, 1.6, 1.1, 3.9, 0.7, 1.0),  # Population in millions
      stringsAsFactors = FALSE
    )
    
    # Filter to target countries only
    target_cities <- cities %>%
      filter(country %in% target_countries)
    
    # Convert to sf object
    cities_sf <- st_as_sf(target_cities, coords = c("lon", "lat"), crs = 4326)
    
    # Get climate zones present in the region for legend
    region_climates <- climate_southern %>%
      st_drop_geometry() %>%
      count(koppen_code, sort = TRUE)
    
    # Create the map
    p <- ggplot() +
      # Plot climate zones
      geom_sf(data = climate_southern, 
              aes(fill = koppen_code), 
              color = "white", 
              linewidth = 0.1, 
              alpha = 0.8) +
      # Add country boundaries for context
      geom_sf(data = southern_africa, 
              fill = NA, 
              color = "gray40", 
              linewidth = 0.3) +
      # Highlight target countries
      geom_sf(data = target_countries_sf, 
              fill = NA, 
              color = "black", 
              linewidth = 0.8) +
      # Add major cities
      geom_sf(data = cities_sf, 
              aes(size = size),
              color = "#E3120B", 
              fill = "#E3120B",
              shape = 21,
              stroke = 1.2) +
      # Add city labels
      geom_sf_text(data = cities_sf, 
                   aes(label = name), 
                   nudge_y = 0.5, 
                   size = 3, 
                   fontface = "bold",
                   color = "black") +
      # Set colors
      scale_fill_manual(
        name = "Köppen-Geiger Climate",
        values = koppen_colors,
        labels = function(x) {
          ifelse(x %in% names(climate_labels), 
                 paste(x, "-", climate_labels[x]), 
                 x)
        },
        guide = guide_legend(
          override.aes = list(alpha = 1, color = "white"),
          ncol = 2
        )
      ) +
      scale_size_continuous(
        name = "Population (millions)",
        range = c(2, 5),
        labels = scales::comma_format(),
        guide = guide_legend(
          override.aes = list(color = "#E3120B", fill = "#E3120B")
        )
      ) +
      # Set coordinate system and limits for southern Africa
      coord_sf(xlim = c(10, 42), ylim = c(-35, -8), expand = FALSE) +
      # Labels and title
      labs(
        title = "Southern Africa Climate Zones: Malawi, South Africa & Zimbabwe",
        subtitle = "Köppen-Geiger climate classification for Wellcome Trust climate-health study",
        x = "Longitude (°E)",
        y = "Latitude (°S)"
      ) +
      # Apply publication theme
      theme_publication() +
      # Customize legend
      guides(
        fill = guide_legend(
          title = "Köppen-Geiger Climate",
          override.aes = list(alpha = 1, color = "white", size = 0.5),
          ncol = 2
        ),
        size = guide_legend(
          title = "Population (millions)",
          override.aes = list(color = "#E3120B", fill = "#E3120B", stroke = 1),
          ncol = 1
        )
      )
    
    return(p)
    
  }, error = function(e) {
    cat(sprintf("Error loading climate data: %s\n", e$message))
    return(NULL)
  })
}

# Create and save the southern Africa climate map
cat("Creating southern Africa climate map...\n")
map_plot <- create_southern_africa_climate_map()

if (!is.null(map_plot)) {
  # Save as high-resolution PNG
  ggsave("southern_africa_climate_map.png", 
         plot = map_plot,
         width = 12, height = 9, 
         dpi = 300, 
         bg = "white")
  
  # Save as SVG (vector format)
  ggsave("southern_africa_climate_map.svg", 
         plot = map_plot,
         width = 12, height = 9, 
         bg = "white")
  
  # Save as PDF for publication
  ggsave("southern_africa_climate_map.pdf", 
         plot = map_plot,
         width = 12, height = 9, 
         bg = "white")
  
  cat("Maps saved as southern_africa_climate_map.png, .svg and .pdf\n")
  
  # Display the plot
  print(map_plot)
} else {
  cat("Failed to create map\n")
}