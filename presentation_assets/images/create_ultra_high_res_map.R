#!/usr/bin/env Rscript
# Ultra High-Resolution Southern Africa Climate Map
# Using Beck et al. (2023) 1km resolution Köppen-Geiger data

suppressPackageStartupMessages({
  library(sf)
  library(ggplot2)
  library(dplyr)
  library(scales)
  library(rnaturalearth)
  library(rnaturalearthdata)
  library(terra)
  library(stars)
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
      panel.grid = element_line(color = "gray90", linewidth = 0.1),
      panel.background = element_rect(fill = "white", color = NA),
      plot.background = element_rect(fill = "white", color = NA)
    )
}

# Köppen climate colors (Beck et al. 2023 RGB values converted)
koppen_colors_new <- c(
  "1" = "#0000ff",   # Af - Tropical, rainforest
  "2" = "#0078ff",   # Am - Tropical, monsoon  
  "3" = "#46aafa",   # Aw - Tropical, savannah
  "4" = "#ff0000",   # BWh - Arid, desert, hot
  "5" = "#ff9696",   # BWk - Arid, desert, cold
  "6" = "#f5a500",   # BSh - Arid, steppe, hot
  "7" = "#ffdc64",   # BSk - Arid, steppe, cold
  "8" = "#ffff00",   # Csa - Temperate, dry summer, hot summer
  "9" = "#c8c800",   # Csb - Temperate, dry summer, warm summer
  "10" = "#969600",  # Csc - Temperate, dry summer, cold summer
  "11" = "#96ff96",  # Cwa - Temperate, dry winter, hot summer
  "12" = "#64c864",  # Cwb - Temperate, dry winter, warm summer
  "13" = "#329632",  # Cwc - Temperate, dry winter, cold summer
  "14" = "#c8ff50",  # Cfa - Temperate, no dry season, hot summer
  "15" = "#64ff50",  # Cfb - Temperate, no dry season, warm summer
  "16" = "#32c800",  # Cfc - Temperate, no dry season, cold summer
  "17" = "#ff00ff",  # Dsa - Cold, dry summer, hot summer
  "18" = "#c800c8",  # Dsb - Cold, dry summer, warm summer
  "19" = "#963296",  # Dsc - Cold, dry summer, cold summer
  "20" = "#966496",  # Dsd - Cold, dry summer, very cold winter
  "21" = "#aaaaff",  # Dwa - Cold, dry winter, hot summer
  "22" = "#5a78dc",  # Dwb - Cold, dry winter, warm summer
  "23" = "#4b50b4",  # Dwc - Cold, dry winter, cold summer
  "24" = "#320087",  # Dwd - Cold, dry winter, very cold winter
  "25" = "#00ffff",  # Dfa - Cold, no dry season, hot summer
  "26" = "#37c8ff",  # Dfb - Cold, no dry season, warm summer
  "27" = "#007d7d",  # Dfc - Cold, no dry season, cold summer
  "28" = "#00465f",  # Dfd - Cold, no dry season, very cold winter
  "29" = "#b2b2b2",  # ET - Polar, tundra
  "30" = "#666666"   # EF - Polar, frost
)

# Köppen labels from legend
koppen_labels_new <- c(
  "1" = "Af - Tropical rainforest",
  "2" = "Am - Tropical monsoon", 
  "3" = "Aw - Tropical savannah",
  "4" = "BWh - Hot desert",
  "5" = "BWk - Cold desert",
  "6" = "BSh - Hot steppe",
  "7" = "BSk - Cold steppe",
  "8" = "Csa - Mediterranean hot",
  "9" = "Csb - Mediterranean warm",
  "10" = "Csc - Mediterranean cold",
  "11" = "Cwa - Humid subtropical hot",
  "12" = "Cwb - Subtropical highland",
  "13" = "Cwc - Subtropical cold",
  "14" = "Cfa - Humid subtropical",
  "15" = "Cfb - Oceanic",
  "16" = "Cfc - Subpolar oceanic",
  "17" = "Dsa - Continental hot dry",
  "18" = "Dsb - Continental warm dry",
  "19" = "Dsc - Continental cold dry",
  "20" = "Dsd - Continental very cold dry",
  "21" = "Dwa - Continental hot",
  "22" = "Dwb - Continental warm",
  "23" = "Dwc - Continental cold",
  "24" = "Dwd - Continental very cold",
  "25" = "Dfa - Continental humid hot",
  "26" = "Dfb - Continental humid warm",
  "27" = "Dfc - Continental humid cold",
  "28" = "Dfd - Continental humid very cold",
  "29" = "ET - Tundra",
  "30" = "EF - Ice cap"
)

create_ultra_high_res_map <- function() {
  tryCatch({
    cat("Loading ultra high-resolution Köppen-Geiger data (1km)...\n")
    
    # Load the finest resolution data for current period (1991-2020)
    koppen_raster <- rast("high_res_koppen/1991_2020/koppen_geiger_0p00833333.tif")
    
    cat(sprintf("Loaded raster: %d x %d pixels\n", ncol(koppen_raster), nrow(koppen_raster)))
    cat(sprintf("Resolution: %.6f degrees\n", res(koppen_raster)[1]))
    
    # Define southern Africa bounding box
    southern_africa_bbox <- c(xmin = 10, ymin = -35, xmax = 42, ymax = -8)
    
    # Crop to southern Africa region
    koppen_cropped <- crop(koppen_raster, southern_africa_bbox)
    
    # Convert to stars object for ggplot
    koppen_stars <- st_as_stars(koppen_cropped)
    
    # Convert values to character for proper mapping
    koppen_stars[[1]] <- as.character(koppen_stars[[1]])
    
    cat(sprintf("Cropped to southern Africa: %d x %d pixels\n", 
                dim(koppen_stars)[1], dim(koppen_stars)[2]))
    
    # Get country boundaries
    countries <- ne_countries(scale = "large", returnclass = "sf")  # Use large scale for detail
    
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
    
    # Create capitals sf
    capitals_sf <- st_as_sf(country_data, coords = c("capital_lon", "capital_lat"), crs = 4326)
    
    # Get unique climate values in the region
    climate_values <- unique(as.vector(koppen_stars[[1]]))
    climate_values <- climate_values[!is.na(climate_values)]
    
    cat(sprintf("Climate zones found: %s\n", paste(sort(climate_values), collapse = ", ")))
    
    # Create the ultra high-res map
    p <- ggplot() +
      # Plot ultra high-resolution climate raster
      geom_stars(data = koppen_stars, alpha = 0.9) +
      # Add country boundaries with minimal weight
      geom_sf(data = southern_africa, 
              fill = NA, 
              color = "white", 
              linewidth = 0.15,
              alpha = 0.7) +
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
      # Add clean labels
      annotate("text", x = 28.034088 + 3.5, y = -26.195246 + 1.8, 
               label = "Johannesburg\nSouth Africa", size = 3.5, fontface = "bold", 
               hjust = 0, color = "black") +
      annotate("text", x = 31.0492 + 3.5, y = -17.8292 + 1.8, 
               label = "Harare\nZimbabwe", size = 3.5, fontface = "bold", 
               hjust = 0, color = "black") +
      annotate("text", x = 33.7703 + 3.5, y = -13.9626 + 1.8, 
               label = "Lilongwe\nMalawi", size = 3.5, fontface = "bold", 
               hjust = 0, color = "black") +
      # Set climate colors using the new legend
      scale_fill_manual(
        name = "Köppen-Geiger Climate (1km resolution)",
        values = koppen_colors_new,
        labels = koppen_labels_new,
        na.value = "transparent",
        guide = guide_legend(
          override.aes = list(alpha = 1),
          ncol = 2
        )
      ) +
      # Country border colors
      scale_color_manual(
        name = "Study Countries",
        values = c("South Africa" = "#1f77b4", "Zimbabwe" = "#ff7f0e", "Malawi" = "#2ca02c"),
        guide = guide_legend(
          override.aes = list(fill = NA, linewidth = 2)
        )
      ) +
      # GDP marker sizes  
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
        title = "Southern Africa: Ultra High-Resolution Climate Zones (1km)",
        subtitle = "Beck et al. (2023) Köppen-Geiger classification for Wellcome Trust study",
        x = "Longitude (°E)",
        y = "Latitude (°S)"
      ) +
      theme_publication() +
      theme(
        legend.box = "horizontal",
        legend.box.just = "center",
        legend.margin = margin(t = 15)
      )
    
    return(p)
    
  }, error = function(e) {
    cat(sprintf("Error creating ultra high-res map: %s\n", e$message))
    cat("Trying alternative approach...\n")
    
    # Alternative: Convert to vector first
    tryCatch({
      # Read as raster and convert to polygons
      koppen_raster <- rast("high_res_koppen/1991_2020/koppen_geiger_0p00833333.tif")
      
      # Crop to region
      southern_africa_bbox <- c(xmin = 10, ymin = -35, xmax = 42, ymax = -8)
      koppen_cropped <- crop(koppen_raster, southern_africa_bbox)
      
      # Convert to polygons (this will be smooth)
      koppen_polygons <- as.polygons(koppen_cropped)
      koppen_sf <- st_as_sf(koppen_polygons)
      
      # Clean up the data
      koppen_sf <- koppen_sf %>%
        filter(!is.na(koppen_geiger_0p00833333)) %>%
        mutate(climate_code = as.character(koppen_geiger_0p00833333))
      
      cat("Successfully converted raster to smooth polygons\n")
      
      # Get countries
      countries <- ne_countries(scale = "large", returnclass = "sf")
      country_data <- data.frame(
        name = c("South Africa", "Zimbabwe", "Malawi"),
        gdp_per_capita = c(6023, 2156, 520),
        capital_lon = c(28.034088, 31.0492, 33.7703),
        capital_lat = c(-26.195246, -17.8292, -13.9626),
        capital_name = c("Johannesburg", "Harare", "Lilongwe"),
        stringsAsFactors = FALSE
      )
      
      target_countries_sf <- countries %>%
        filter(name %in% country_data$name) %>%
        left_join(country_data, by = "name")
      
      southern_africa_countries <- c("South Africa", "Zimbabwe", "Malawi", 
                                   "Botswana", "Namibia", "Zambia", 
                                   "Mozambique", "Lesotho", "Eswatini")
      
      southern_africa <- countries %>%
        filter(name %in% southern_africa_countries)
      
      capitals_sf <- st_as_sf(country_data, coords = c("capital_lon", "capital_lat"), crs = 4326)
      
      # Create ultra high-res map with polygons
      p <- ggplot() +
        # Plot high-resolution climate polygons
        geom_sf(data = koppen_sf, 
                aes(fill = climate_code), 
                color = NA,  # No borders for smoothest appearance
                alpha = 0.9) +
        # Country boundaries
        geom_sf(data = southern_africa, 
                fill = NA, 
                color = "white", 
                linewidth = 0.2,
                alpha = 0.8) +
        # Target countries
        geom_sf(data = target_countries_sf, 
                fill = NA, 
                aes(color = factor(name)), 
                linewidth = 2.5) +
        # Capitals
        geom_sf(data = capitals_sf, 
                aes(size = gdp_per_capita),
                color = "#E3120B", 
                fill = "white",
                shape = 21,
                stroke = 2) +
        # Labels
        annotate("text", x = 28.034088 + 3.5, y = -26.195246 + 1.8, 
                 label = "Johannesburg\nSouth Africa", size = 3.5, fontface = "bold", 
                 hjust = 0, color = "black") +
        annotate("text", x = 31.0492 + 3.5, y = -17.8292 + 1.8, 
                 label = "Harare\nZimbabwe", size = 3.5, fontface = "bold", 
                 hjust = 0, color = "black") +
        annotate("text", x = 33.7703 + 3.5, y = -13.9626 + 1.8, 
                 label = "Lilongwe\nMalawi", size = 3.5, fontface = "bold", 
                 hjust = 0, color = "black") +
        # Climate colors
        scale_fill_manual(
          name = "Köppen-Geiger (1km resolution)",
          values = koppen_colors_new,
          labels = koppen_labels_new,
          na.value = "transparent",
          guide = guide_legend(
            override.aes = list(alpha = 1),
            ncol = 2
          )
        ) +
        scale_color_manual(
          name = "Study Countries",
          values = c("South Africa" = "#1f77b4", "Zimbabwe" = "#ff7f0e", "Malawi" = "#2ca02c")
        ) +
        scale_size_continuous(
          name = "GDP per capita (USD)",
          range = c(4, 8),
          labels = scales::dollar_format()
        ) +
        coord_sf(xlim = c(12, 40), ylim = c(-35, -8), expand = FALSE) +
        labs(
          title = "Southern Africa: Ultra High-Resolution Climate Zones",
          subtitle = "Beck et al. (2023) 1km Köppen-Geiger classification",
          x = "Longitude (°E)",
          y = "Latitude (°S)"
        ) +
        theme_publication()
      
      return(p)
      
    }, error = function(e2) {
      cat(sprintf("Alternative approach failed: %s\n", e2$message))
      return(NULL)
    })
  })
}

# Create the ultra high-resolution map
cat("Creating ultra high-resolution southern Africa climate map...\n")
ultra_map <- create_ultra_high_res_map()

if (!is.null(ultra_map)) {
  # Save ultra high-quality versions
  ggsave("southern_africa_1km_climate_map.png", 
         plot = ultra_map,
         width = 16, height = 12, 
         dpi = 600,  # Ultra high DPI
         bg = "white")
  
  ggsave("southern_africa_1km_climate_map.svg", 
         plot = ultra_map,
         width = 16, height = 12, 
         bg = "white")
  
  ggsave("southern_africa_1km_climate_map.pdf", 
         plot = ultra_map,
         width = 16, height = 12, 
         bg = "white")
  
  cat("Ultra high-resolution maps saved:\n")
  cat("- southern_africa_1km_climate_map.png (600 DPI, 1km resolution)\n")
  cat("- southern_africa_1km_climate_map.svg\n")
  cat("- southern_africa_1km_climate_map.pdf\n")
  
} else {
  cat("Failed to create ultra high-resolution map\n")
}