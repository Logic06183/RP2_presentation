#!/usr/bin/env Rscript
# Smooth Southern Africa Climate Map with refined boundaries
# Applies geometric smoothing to reduce pixelation in climate zones

# Load required libraries
suppressPackageStartupMessages({
  library(sf)
  library(ggplot2)
  library(dplyr)
  library(scales)
  library(rnaturalearth)
  library(rnaturalearthdata)
  library(smoothr)
  library(rmapshaper)
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

# Define climate zone descriptions
climate_labels <- c(
  "Af" = "Tropical rainforest", "Am" = "Tropical monsoon", "Aw" = "Tropical wet savanna",
  "As" = "Tropical dry savanna", "BWh" = "Hot desert", "BWk" = "Cold desert",
  "BSh" = "Hot semi-arid", "BSk" = "Cold semi-arid", "BSh/BSK" = "Semi-arid variant",
  "Csa" = "Mediterranean hot summer", "Csb" = "Mediterranean warm summer",
  "Cwa" = "Humid subtropical", "Cwb" = "Subtropical highland", "Cfa" = "Humid subtropical", "Cfb" = "Oceanic"
)

smooth_climate_polygons <- function(climate_data, smooth_factor = 1000) {
  cat("Applying geometric smoothing to climate polygons...\n")
  
  # Method 1: Simplify first, then smooth
  tryCatch({
    # Simplify to reduce complexity
    simplified <- ms_simplify(climate_data, keep = 0.3, keep_shapes = TRUE)
    
    # Apply smoothing
    smoothed <- smooth(simplified, method = "chaikin", refinements = 2)
    
    cat("Successfully applied Chaikin smoothing\n")
    return(smoothed)
    
  }, error = function(e1) {
    cat("Chaikin smoothing failed, trying buffer smoothing...\n")
    
    # Method 2: Buffer smoothing (creates rounded corners)
    tryCatch({
      # Small buffer out and in to smooth edges
      buffered_out <- st_buffer(climate_data, dist = smooth_factor)
      buffered_smooth <- st_buffer(buffered_out, dist = -smooth_factor)
      
      cat("Successfully applied buffer smoothing\n")
      return(buffered_smooth)
      
    }, error = function(e2) {
      cat("Buffer smoothing failed, using simplified polygons...\n")
      
      # Method 3: Just simplify
      simplified <- ms_simplify(climate_data, keep = 0.5, keep_shapes = TRUE)
      return(simplified)
    })
  })
}

create_smooth_southern_africa_map <- function() {
  tryCatch({
    cat("Loading Köppen-Geiger climate data...\n")
    
    # Load climate data
    climate_data <- st_read("koppen_africa_with_labels.geojson", quiet = TRUE)
    
    # Get country boundaries
    countries <- ne_countries(scale = "medium", returnclass = "sf")
    
    # Define comprehensive country data
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
    
    # Get southern Africa region for context
    southern_africa_countries <- c("South Africa", "Zimbabwe", "Malawi", 
                                 "Botswana", "Namibia", "Zambia", 
                                 "Mozambique", "Lesotho", "Eswatini")
    
    southern_africa <- countries %>%
      filter(name %in% southern_africa_countries)
    
    # Filter climate data to southern Africa region
    bbox <- st_bbox(c(xmin = 10, ymin = -35, xmax = 42, ymax = -8), crs = st_crs(4326))
    bbox_poly <- st_as_sfc(bbox)
    climate_southern <- st_filter(climate_data, bbox_poly)
    
    # Apply smoothing to climate polygons
    climate_smooth <- smooth_climate_polygons(climate_southern)
    
    # Create capitals as sf points
    capitals_sf <- st_as_sf(country_data, coords = c("capital_lon", "capital_lat"), crs = 4326)
    
    # Create the smoothed map
    p <- ggplot() +
      # Plot smoothed climate zones with no borders for smoother appearance
      geom_sf(data = climate_smooth, 
              aes(fill = koppen_code), 
              color = NA,  # Remove borders between climate zones
              alpha = 0.85) +
      # Add subtle country boundaries for context
      geom_sf(data = southern_africa, 
              fill = NA, 
              color = "white", 
              linewidth = 0.2,
              alpha = 0.7) +
      # Highlight target countries with distinct colors
      geom_sf(data = target_countries_sf, 
              fill = NA, 
              aes(color = factor(name)), 
              linewidth = 1.5,
              linetype = "solid") +
      # Add capitals with size based on GDP per capita
      geom_sf(data = capitals_sf, 
              aes(size = gdp_per_capita),
              color = "#E3120B", 
              fill = "white",
              shape = 21,
              stroke = 2) +
      # Add capital labels with better positioning
      annotate("text", x = 28.034088 + 3, y = -26.195246 + 1.5, 
               label = "Johannesburg\nSouth Africa", size = 3.2, fontface = "bold", 
               hjust = 0, color = "black") +
      annotate("text", x = 31.0492 + 3, y = -17.8292 + 1.5, 
               label = "Harare\nZimbabwe", size = 3.2, fontface = "bold", 
               hjust = 0, color = "black") +
      annotate("text", x = 33.7703 + 3, y = -13.9626 + 1.5, 
               label = "Lilongwe\nMalawi", size = 3.2, fontface = "bold", 
               hjust = 0, color = "black") +
      # Set climate zone colors
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
          ncol = 2,
          title.position = "top"
        )
      ) +
      # Set country border colors
      scale_color_manual(
        name = "Study Countries",
        values = c("South Africa" = "#1f77b4", "Zimbabwe" = "#ff7f0e", "Malawi" = "#2ca02c"),
        guide = guide_legend(
          override.aes = list(fill = NA, linewidth = 1.5),
          title.position = "top"
        )
      ) +
      # Set GDP marker sizes
      scale_size_continuous(
        name = "GDP per capita (USD)",
        range = c(4, 8),
        labels = scales::dollar_format(),
        guide = guide_legend(
          override.aes = list(color = "#E3120B", fill = "white", stroke = 2),
          title.position = "top"
        )
      ) +
      # Set coordinate system with tight bounds
      coord_sf(xlim = c(12, 40), ylim = c(-35, -8), expand = FALSE) +
      # Labels and title
      labs(
        title = "Southern Africa: Climate Zones & Development Context",
        subtitle = "Smooth Köppen-Geiger climate classification for Wellcome Trust climate-health study",
        x = "Longitude (°E)",
        y = "Latitude (°S)"
      ) +
      theme_publication() +
      # Position legends side by side at bottom
      theme(
        legend.box = "horizontal",
        legend.box.just = "center"
      )
    
    return(p)
    
  }, error = function(e) {
    cat(sprintf("Error creating smooth map: %s\n", e$message))
    return(NULL)
  })
}

# Install required packages if missing
required_packages <- c("smoothr", "rmapshaper")
missing_packages <- required_packages[!required_packages %in% installed.packages()[,"Package"]]

if(length(missing_packages) > 0) {
  cat("Installing required packages for smoothing:", paste(missing_packages, collapse = ", "), "\n")
  install.packages(missing_packages, repos = "https://cran.r-project.org")
}

# Create the smooth map
cat("Creating smooth southern Africa climate map...\n")
smooth_map <- create_smooth_southern_africa_map()

if (!is.null(smooth_map)) {
  # Save high-quality versions
  ggsave("southern_africa_smooth_climate_map.png", 
         plot = smooth_map,
         width = 14, height = 10, 
         dpi = 300, 
         bg = "white")
  
  ggsave("southern_africa_smooth_climate_map.svg", 
         plot = smooth_map,
         width = 14, height = 10, 
         bg = "white")
  
  ggsave("southern_africa_smooth_climate_map.pdf", 
         plot = smooth_map,
         width = 14, height = 10, 
         bg = "white")
  
  cat("Smooth climate maps saved:\n")
  cat("- southern_africa_smooth_climate_map.png/svg/pdf\n")
  
} else {
  cat("Failed to create smooth map\n")
}