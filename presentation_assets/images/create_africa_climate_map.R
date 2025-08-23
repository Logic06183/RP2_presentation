#!/usr/bin/env Rscript
# Scientific visualization of African Köppen-Geiger climate zones with study locations
# Created following publication standards for scientific journals

# Load required libraries
suppressPackageStartupMessages({
  library(sf)
  library(ggplot2)
  library(dplyr)
  library(scales)
})

# Set up publication theme
theme_publication <- function() {
  theme_minimal() +
    theme(
      text = element_text(family = "Arial", size = 10),
      plot.title = element_text(size = 12, hjust = 0.5, face = "bold"),
      plot.subtitle = element_text(size = 10, hjust = 0.5, color = "gray30"),
      axis.text = element_text(size = 9),
      axis.title = element_text(size = 10),
      legend.title = element_text(size = 10, face = "bold"),
      legend.text = element_text(size = 9),
      legend.position = "bottom",
      legend.key.size = unit(0.4, "cm"),
      panel.grid = element_line(color = "gray90", size = 0.25),
      panel.background = element_rect(fill = "white", color = NA),
      plot.background = element_rect(fill = "white", color = NA),
      legend.background = element_rect(fill = "white", color = "gray70", size = 0.5)
    )
}

# Define Köppen climate colors (scientifically accurate)
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

# Define climate zone descriptions
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

create_africa_climate_map <- function() {
  # Try to read the climate data
  tryCatch({
    cat("Loading Köppen-Geiger climate data...\n")
    climate_data <- st_read("koppen_africa_with_labels.geojson", quiet = TRUE)
    
    cat(sprintf("Loaded %d climate polygons\n", nrow(climate_data)))
    cat(sprintf("Climate zones found: %s\n", paste(sort(unique(climate_data$koppen_code)), collapse = ", ")))
    
    # Study locations
    study_locations <- data.frame(
      name = c("Abidjan", "Johannesburg"),
      lon = c(-4.024429, 28.034088),
      lat = c(5.345317, -26.195246),
      participants = c(9162, 11800),
      climate = c("Am", "Cwa"),
      stringsAsFactors = FALSE
    )
    
    # Convert to sf object for plotting
    study_sf <- st_as_sf(study_locations, coords = c("lon", "lat"), crs = 4326)
    
    # Get the most common climate zones for legend (max 8)
    climate_counts <- climate_data %>%
      st_drop_geometry() %>%
      count(koppen_code, sort = TRUE) %>%
      head(8)
    
    # Create the map
    p <- ggplot() +
      # Plot climate zones
      geom_sf(data = climate_data, 
              aes(fill = koppen_code), 
              color = "white", 
              size = 0.1, 
              alpha = 0.8) +
      # Add study locations
      geom_sf(data = study_sf, 
              aes(size = participants),
              color = "#E3120B", 
              fill = "#E3120B",
              shape = 21,
              stroke = 1.5) +
      # Add study location labels
      geom_sf_text(data = study_sf,
                   aes(label = name),
                   nudge_x = 2, nudge_y = 1,
                   size = 3.5, 
                   fontface = "bold",
                   color = "black") +
      # Set colors
      scale_fill_manual(
        name = "Köppen-Geiger Climate",
        values = koppen_colors,
        labels = function(x) paste(x, "-", climate_labels[x]),
        guide = guide_legend(
          override.aes = list(alpha = 1, color = "white"),
          ncol = 2
        )
      ) +
      scale_size_continuous(
        name = "Study Participants",
        range = c(3, 6),
        labels = scales::comma_format(),
        guide = guide_legend(
          override.aes = list(color = "#E3120B", fill = "#E3120B")
        )
      ) +
      # Set coordinate system and limits
      coord_sf(xlim = c(-20, 55), ylim = c(-35, 40), expand = FALSE) +
      # Labels and title
      labs(
        title = "Study locations in African climate context",
        subtitle = "Köppen-Geiger climate classification and participant distribution",
        x = "Longitude (°E)",
        y = "Latitude (°N)"
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
          title = "Study Participants",
          override.aes = list(color = "#E3120B", fill = "#E3120B", stroke = 1),
          ncol = 1
        )
      )
    
    return(p)
    
  }, error = function(e) {
    cat(sprintf("Error loading climate data: %s\n", e$message))
    cat("Creating simplified fallback map...\n")
    
    # Create a simple fallback map
    study_locations <- data.frame(
      name = c("Abidjan", "Johannesburg"),
      lon = c(-4.024429, 28.034088),
      lat = c(5.345317, -26.195246),
      participants = c(9162, 11800),
      climate = c("Am", "Cwa")
    )
    
    p <- ggplot(study_locations, aes(x = lon, y = lat)) +
      geom_point(aes(size = participants), color = "#E3120B", alpha = 0.8) +
      geom_text(aes(label = name), nudge_y = 2, fontface = "bold") +
      coord_fixed(xlim = c(-20, 55), ylim = c(-35, 40)) +
      labs(
        title = "Study locations in African context",
        subtitle = "Climate data not available - showing locations only",
        x = "Longitude (°E)",
        y = "Latitude (°N)"
      ) +
      theme_publication()
    
    return(p)
  })
}

# Create and save the map
cat("Creating African climate zone map with study locations...\n")
map_plot <- create_africa_climate_map()

# Save as high-resolution PNG
ggsave("africa_climate_study_locations_r.png", 
       plot = map_plot,
       width = 12, height = 9, 
       dpi = 300, 
       bg = "white")

# Save as PDF for publication
ggsave("africa_climate_study_locations_r.pdf", 
       plot = map_plot,
       width = 12, height = 9, 
       bg = "white")

cat("Maps saved as africa_climate_study_locations_r.png and .pdf\n")

# Display the plot
print(map_plot)