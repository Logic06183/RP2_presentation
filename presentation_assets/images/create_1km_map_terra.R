#!/usr/bin/env Rscript
# Ultra High-Resolution Climate Map using terra package
# 1km resolution Beck et al. (2023) data

suppressPackageStartupMessages({
  library(sf)
  library(ggplot2)
  library(dplyr)
  library(scales)
  library(rnaturalearth)
  library(rnaturalearthdata)
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

# Köppen climate colors (Beck et al. 2023 official colors)
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

create_1km_climate_map <- function() {
  tryCatch({
    cat("Processing 1km resolution Köppen-Geiger data...\n")
    
    # Load the ultra high-resolution data
    koppen_raster <- rast("high_res_koppen/1991_2020/koppen_geiger_0p00833333.tif")
    
    cat(sprintf("Original raster: %d x %d pixels, resolution: %.6f°\n", 
                ncol(koppen_raster), nrow(koppen_raster), res(koppen_raster)[1]))
    
    # Define southern Africa bounds with some padding
    sa_bbox <- ext(8, 44, -37, -6)
    
    # Crop to southern Africa
    koppen_sa <- crop(koppen_raster, sa_bbox)
    
    cat(sprintf("Southern Africa subset: %d x %d pixels\n", 
                ncol(koppen_sa), nrow(koppen_sa)))
    
    # Convert to vector polygons for smooth rendering
    cat("Converting raster to smooth vector polygons...\n")
    koppen_polygons <- as.polygons(koppen_sa, dissolve = TRUE)
    koppen_sf <- st_as_sf(koppen_polygons)
    
    # Clean and prepare data
    koppen_sf <- koppen_sf %>%
      filter(!is.na(koppen_geiger_0p00833333)) %>%
      rename(climate_code = koppen_geiger_0p00833333) %>%
      mutate(climate_code = as.character(climate_code))
    
    cat(sprintf("Created %d climate polygons\n", nrow(koppen_sf)))
    cat(sprintf("Climate codes found: %s\n", paste(sort(unique(koppen_sf$climate_code)), collapse = ", ")))
    
    # Get country boundaries
    countries <- ne_countries(scale = "large", returnclass = "sf")
    
    # Country data
    country_data <- data.frame(
      name = c("South Africa", "Zimbabwe", "Malawi"),
      gdp_per_capita = c(6023, 2156, 520),
      capital_lon = c(28.034088, 31.0492, 33.7703),
      capital_lat = c(-26.195246, -17.8292, -13.9626),
      capital_name = c("Johannesburg", "Harare", "Lilongwe"),
      stringsAsFactors = FALSE
    )
    
    # Filter countries
    target_countries_sf <- countries %>%
      filter(name %in% country_data$name) %>%
      left_join(country_data, by = "name")
    
    southern_africa_countries <- c("South Africa", "Zimbabwe", "Malawi", 
                                 "Botswana", "Namibia", "Zambia", 
                                 "Mozambique", "Lesotho", "Eswatini")
    
    southern_africa <- countries %>%
      filter(name %in% southern_africa_countries)
    
    capitals_sf <- st_as_sf(country_data, coords = c("capital_lon", "capital_lat"), crs = 4326)
    
    # Create the ultra-smooth 1km resolution map
    p <- ggplot() +
      # Ultra high-resolution climate zones (no borders for smoothness)
      geom_sf(data = koppen_sf, 
              aes(fill = climate_code), 
              color = NA,
              alpha = 0.95) +
      # Minimal country boundaries
      geom_sf(data = southern_africa, 
              fill = NA, 
              color = "white", 
              linewidth = 0.1,
              alpha = 0.9) +
      # Target countries with distinct borders
      geom_sf(data = target_countries_sf, 
              fill = NA, 
              aes(color = factor(name)), 
              linewidth = 2.5) +
      # Capital cities
      geom_sf(data = capitals_sf, 
              aes(size = gdp_per_capita),
              color = "#E3120B", 
              fill = "white",
              shape = 21,
              stroke = 2.5) +
      # Clean labels
      annotate("text", x = 28.034088 + 4, y = -26.195246 + 2, 
               label = "Johannesburg\nSouth Africa", size = 3.8, fontface = "bold", 
               hjust = 0, color = "black") +
      annotate("text", x = 31.0492 + 4, y = -17.8292 + 2, 
               label = "Harare\nZimbabwe", size = 3.8, fontface = "bold", 
               hjust = 0, color = "black") +
      annotate("text", x = 33.7703 + 4, y = -13.9626 + 2, 
               label = "Lilongwe\nMalawi", size = 3.8, fontface = "bold", 
               hjust = 0, color = "black") +
      # Color scales
      scale_fill_manual(
        name = "Köppen-Geiger Climate (1km)",
        values = koppen_colors_new,
        na.value = "transparent",
        guide = guide_legend(
          override.aes = list(alpha = 1, color = "white", linewidth = 0.1),
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
        title = "Southern Africa: 1km Resolution Climate Zones",
        subtitle = "Beck et al. (2023) ultra high-resolution Köppen-Geiger classification",
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

# Create the 1km resolution map
ultra_high_res_map <- create_1km_climate_map()

if (!is.null(ultra_high_res_map)) {
  # Save ultra high-quality versions
  ggsave("southern_africa_1km_smooth_climate_map.png", 
         plot = ultra_high_res_map,
         width = 16, height = 12, 
         dpi = 600,
         bg = "white")
  
  ggsave("southern_africa_1km_smooth_climate_map.svg", 
         plot = ultra_high_res_map,
         width = 16, height = 12, 
         bg = "white")
  
  cat("✅ Ultra high-resolution smooth maps created:\n")
  cat("- southern_africa_1km_smooth_climate_map.png (600 DPI)\n")
  cat("- southern_africa_1km_smooth_climate_map.svg\n")
  
} else {
  cat("❌ Failed to create 1km resolution map\n")
}