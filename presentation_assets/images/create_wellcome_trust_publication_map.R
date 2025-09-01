#!/usr/bin/env Rscript
# Wellcome Trust Publication-Quality Southern Africa Climate Map
# Enhanced with comprehensive data from table + publication styling

suppressPackageStartupMessages({
  library(sf)
  library(ggplot2)
  library(dplyr)
  library(scales)
  library(terra)
  library(grid)
  library(gridExtra)
})

# Enhanced publication theme
theme_wellcome_publication <- function() {
  theme_minimal() +
    theme(
      text = element_text(size = 11, family = "Arial"),
      plot.title = element_text(size = 16, hjust = 0.5, face = "bold", margin = margin(b = 10)),
      plot.subtitle = element_text(size = 13, hjust = 0.5, color = "gray20", margin = margin(b = 15)),
      axis.text = element_text(size = 10, color = "gray30"),
      axis.title = element_text(size = 11, face = "bold"),
      legend.title = element_text(size = 11, face = "bold"),
      legend.text = element_text(size = 9),
      legend.position = "bottom",
      legend.key.size = unit(0.4, "cm"),
      legend.margin = margin(t = 20),
      panel.grid.major = element_line(color = "gray92", linewidth = 0.2),
      panel.grid.minor = element_line(color = "gray96", linewidth = 0.1),
      panel.background = element_rect(fill = "white", color = NA),
      plot.background = element_rect(fill = "white", color = NA),
      plot.margin = margin(20, 20, 20, 20)
    )
}

# Traditional Köppen-Geiger colors (scientifically standard)
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
  "1" = "Af - Tropical rainforest", "2" = "Am - Tropical monsoon", "3" = "Aw - Tropical savannah",
  "4" = "BWh - Hot desert", "5" = "BWk - Cold desert", "6" = "BSh - Hot semi-arid",
  "7" = "BSk - Cold semi-arid", "8" = "Csa - Mediterranean hot", "9" = "Csb - Mediterranean warm",
  "10" = "Csc - Mediterranean cold", "11" = "Cwa - Humid subtropical", "12" = "Cwb - Subtropical highland",
  "13" = "Cwc - Subtropical cold", "14" = "Cfa - Humid temperate", "15" = "Cfb - Oceanic", "16" = "Cfc - Subpolar oceanic"
)

extract_climate_at_point <- function(raster, lon, lat) {
  point <- vect(data.frame(x = lon, y = lat), geom = c("x", "y"), crs = "EPSG:4326")
  climate_value <- extract(raster, point)[1, 2]
  return(as.character(climate_value))
}

create_wellcome_publication_map <- function() {
  tryCatch({
    cat("Creating Wellcome Trust publication-quality climate map...\n")
    
    # Load 1km resolution data
    koppen_raster <- rast("high_res_koppen/1991_2020/koppen_geiger_0p00833333.tif")
    
    # Comprehensive study location data from table
    study_locations <- data.frame(
      country = c("South Africa", "Zimbabwe", "Malawi"),
      city = c("Johannesburg", "Harare", "Lilongwe"),
      lon = c(28.034088, 31.0492, 33.7703),
      lat = c(-26.195246, -17.8292, -13.9626),
      
      # Economic indicators
      gdp_per_capita = c(6023, 2156, 520),
      world_bank_class = c("Upper middle income", "Lower middle income", "Low income"),
      urban_percent = c(68.8, 32.0, 18.3),
      
      # Health indicators
      life_expectancy = c(64, 62, 66.4),
      hiv_prevalence = c(17.2, 9.8, 6.2),
      
      # Climate vulnerability
      vulnerability_rank = c(117, 51, 26),
      temp_increase = c(1.2, 1.0, 1.0),
      
      stringsAsFactors = FALSE
    )
    
    # Extract climate zones
    for (i in 1:nrow(study_locations)) {
      climate_code <- extract_climate_at_point(koppen_raster, 
                                              study_locations$lon[i], 
                                              study_locations$lat[i])
      study_locations$climate_code[i] <- climate_code
      study_locations$climate_label[i] <- climate_labels_traditional[climate_code]
    }
    
    # Process climate raster
    sa_bbox <- ext(10, 42, -35, -8)
    koppen_sa <- crop(koppen_raster, sa_bbox)
    koppen_polygons <- as.polygons(koppen_sa, dissolve = TRUE)
    koppen_sf <- st_as_sf(koppen_polygons)
    
    koppen_sf <- koppen_sf %>%
      filter(!is.na(koppen_geiger_0p00833333)) %>%
      mutate(climate_code = as.character(koppen_geiger_0p00833333))
    
    cities_sf <- st_as_sf(study_locations, coords = c("lon", "lat"), crs = 4326)
    
    # Create publication-quality map
    p <- ggplot() +
      # Ultra-smooth climate zones with subtle shadow effect
      geom_sf(data = koppen_sf, 
              aes(fill = climate_code), 
              color = "white",
              linewidth = 0.05,
              alpha = 0.92) +
      # Add subtle country boundaries for context
      geom_rect(aes(xmin = 10, xmax = 42, ymin = -35, ymax = -8), 
               fill = NA, color = "gray80", linewidth = 0.3, alpha = 0.5) +
      # Study cities with vulnerability-based border colors
      geom_sf(data = cities_sf, 
              aes(size = gdp_per_capita, color = factor(vulnerability_rank < 100)),
              fill = "white",
              shape = 21,
              stroke = 3,
              alpha = 0.95) +
      # Enhanced city labels
      annotate("text", x = 28.034088 + 5, y = -26.195246 + 3, 
               label = "Johannesburg\nSouth Africa", 
               size = 4.2, fontface = "bold", hjust = 0, color = "black") +
      annotate("text", x = 31.0492 + 5, y = -17.8292 + 3, 
               label = "Harare\nZimbabwe", 
               size = 4.2, fontface = "bold", hjust = 0, color = "black") +
      annotate("text", x = 33.7703 + 5, y = -13.9626 + 3, 
               label = "Lilongwe\nMalawi", 
               size = 4.2, fontface = "bold", hjust = 0, color = "black") +
      
      # Comprehensive data boxes for each location
      # Johannesburg info box
      annotate("rect", xmin = 28.034088 + 4.5, xmax = 28.034088 + 12, 
               ymin = -26.195246 - 2.5, ymax = -26.195246 + 1,
               fill = "white", color = "black", alpha = 0.95, linewidth = 0.8) +
      annotate("text", x = 28.034088 + 8.25, y = -26.195246 - 0.75, 
               label = paste0("Climate: Cwb - Subtropical highland\n",
                             "GDP: $6,023 | Life exp: 64 years\n",
                             "Urban: 68.8% | HIV: 17.2%\n",
                             "Vulnerability rank: #117 globally"), 
               size = 2.8, hjust = 0.5, color = "black") +
      
      # Harare info box  
      annotate("rect", xmin = 31.0492 + 4.5, xmax = 31.0492 + 12, 
               ymin = -17.8292 - 2.5, ymax = -17.8292 + 1,
               fill = "white", color = "black", alpha = 0.95, linewidth = 0.8) +
      annotate("text", x = 31.0492 + 8.25, y = -17.8292 - 0.75, 
               label = paste0("Climate: Cwb - Subtropical highland\n",
                             "GDP: $2,156 | Life exp: 62 years\n",
                             "Urban: 32% | HIV: 9.8%\n",
                             "Vulnerability rank: #51 globally"), 
               size = 2.8, hjust = 0.5, color = "black") +
      
      # Lilongwe info box
      annotate("rect", xmin = 33.7703 + 4.5, xmax = 33.7703 + 12, 
               ymin = -13.9626 - 2.5, ymax = -13.9626 + 1,
               fill = "white", color = "black", alpha = 0.95, linewidth = 0.8) +
      annotate("text", x = 33.7703 + 8.25, y = -13.9626 - 0.75, 
               label = paste0("Climate: Cwa - Humid subtropical\n",
                             "GDP: $520 | Life exp: 66.4 years\n",
                             "Urban: 18.3% | HIV: 6.2%\n",
                             "Vulnerability rank: #26 globally"), 
               size = 2.8, hjust = 0.5, color = "black") +
      
      # Add temperature change indicators
      annotate("text", x = 15, y = -10, 
               label = "Temperature increases since 1980s:\n+1.2°C (South Africa) | +1.0°C (Zimbabwe & Malawi)", 
               size = 3.2, hjust = 0, color = "red4", fontface = "bold",
               fill = "white", alpha = 0.9) +
      
      # Enhanced color schemes
      scale_fill_manual(
        name = "Köppen-Geiger Climate Zones (1km resolution)",
        values = traditional_koppen_colors,
        labels = function(x) climate_labels_traditional[x],
        na.value = "transparent",
        guide = guide_legend(
          override.aes = list(alpha = 1, color = "white", linewidth = 0.3),
          ncol = 4,
          title.position = "top"
        )
      ) +
      scale_color_manual(
        name = "Climate Vulnerability",
        values = c("TRUE" = "#d73027", "FALSE" = "#1a9850"),
        labels = c("TRUE" = "High vulnerability (Top 100)", "FALSE" = "Lower vulnerability"),
        guide = guide_legend(
          override.aes = list(size = 6, fill = "white", stroke = 3),
          title.position = "top"
        )
      ) +
      scale_size_continuous(
        name = "GDP per capita (USD)",
        range = c(4, 10),
        labels = scales::dollar_format(),
        guide = guide_legend(
          override.aes = list(color = "black", fill = "white", stroke = 3),
          title.position = "top"
        )
      ) +
      coord_sf(xlim = c(10, 44), ylim = c(-35, -8), expand = FALSE) +
      labs(
        title = "Southern Africa Climate-Health Study Context",
        subtitle = "Köppen-Geiger climate zones with socioeconomic and health indicators | Wellcome Trust Climate-Health Initiative",
        x = "Longitude (°E)",
        y = "Latitude (°S)",
        caption = "Data: Beck et al. (2023) 1km Köppen-Geiger classification | World Bank Development Indicators | ND-GAIN Climate Vulnerability Index"
      ) +
      theme_wellcome_publication() +
      theme(
        legend.box = "horizontal",
        legend.box.just = "center",
        legend.spacing.x = unit(1, "cm"),
        plot.caption = element_text(size = 8, color = "gray40", hjust = 1, margin = margin(t = 10))
      )
    
    return(p)
    
  }, error = function(e) {
    cat(sprintf("Error: %s\n", e$message))
    return(NULL)
  })
}

# Create Wellcome Trust publication map
cat("Creating Wellcome Trust publication-quality map...\n")
wellcome_map <- create_wellcome_publication_map()

if (!is.null(wellcome_map)) {
  # Save publication-quality versions
  ggsave("southern_africa_wellcome_trust_publication.png", 
         plot = wellcome_map,
         width = 20, height = 14, 
         dpi = 600,
         bg = "white")
  
  ggsave("southern_africa_wellcome_trust_publication.svg", 
         plot = wellcome_map,
         width = 20, height = 14, 
         bg = "white")
  
  ggsave("southern_africa_wellcome_trust_publication.pdf", 
         plot = wellcome_map,
         width = 20, height = 14, 
         bg = "white")
  
  cat("✅ WELLCOME TRUST PUBLICATION MAP CREATED!\n")
  cat("Enhanced features:\n")
  cat("• Traditional Köppen-Geiger scientific color scheme\n")
  cat("• 1km resolution ultra-smooth boundaries\n")
  cat("• Comprehensive data boxes (GDP, life expectancy, urbanization, HIV, vulnerability)\n")
  cat("• Climate change temperature indicators\n")
  cat("• Publication-quality typography and layout\n")
  cat("• Multiple formats: PNG (600 DPI), SVG, PDF\n\n")
  
  cat("Files created:\n")
  cat("- southern_africa_wellcome_trust_publication.png\n")
  cat("- southern_africa_wellcome_trust_publication.svg\n") 
  cat("- southern_africa_wellcome_trust_publication.pdf\n")
  
} else {
  cat("❌ Failed to create Wellcome Trust publication map\n")
}