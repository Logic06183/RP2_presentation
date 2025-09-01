#!/usr/bin/env Rscript
# Enhanced warming progression diagram with city labels, climate zone annotations, and data sources
# Professional quality for presentation and Figma editing

suppressPackageStartupMessages({
  library(sf)
  library(ggplot2)
  library(dplyr)
  library(terra)
  library(patchwork)
})

theme_enhanced <- function() {
  theme_minimal() +
    theme(
      text = element_text(family = "Arial", size = 10),
      plot.title = element_text(size = 13, hjust = 0.5, face = "bold", margin = margin(b = 8)),
      plot.subtitle = element_text(size = 10, hjust = 0.5, color = "gray30", margin = margin(b = 12)),
      axis.text = element_text(size = 8, color = "gray40"),
      axis.title = element_text(size = 9, color = "gray30"),
      legend.position = "none",
      panel.grid = element_line(color = "gray92", linewidth = 0.2),
      panel.background = element_rect(fill = "white", color = NA),
      plot.background = element_rect(fill = "white", color = NA),
      plot.margin = margin(15, 15, 15, 15),
      axis.ticks = element_line(color = "gray80", linewidth = 0.3),
      axis.ticks.length = unit(3, "pt")
    )
}

# Enhanced Köppen-Geiger colors with better contrast
enhanced_koppen_colors <- c(
  "2" = "#2E8B57", "3" = "#90EE90", "4" = "#FFD700", "5" = "#FF8C00", 
  "6" = "#FF6347", "7" = "#DC143C", "8" = "#8B008B", "9" = "#32CD32",
  "11" = "#1E90FF", "12" = "#4169E1", "13" = "#00CED1", "14" = "#87CEEB", 
  "15" = "#B0E0E6", "23" = "#20B2AA", "26" = "#E0E0E0", "29" = "#696969"
)

koppen_names <- c(
  "2" = "Am", "3" = "Aw", "4" = "BWh", "5" = "BWk",
  "6" = "BSh", "7" = "BSk", "8" = "Csa", "9" = "Csb",
  "11" = "Cwa", "12" = "Cwb", "13" = "Cwc", "14" = "Cfa",
  "15" = "Cfb", "23" = "Dwc", "26" = "Dfb", "29" = "ET"
)

# Major cities with coordinates
cities <- data.frame(
  city = c("Lilongwe", "Harare", "Johannesburg", "Cape Town"),
  country = c("Malawi", "Zimbabwe", "South Africa", "South Africa"),
  lon = c(33.7703, 31.0492, 28.0341, 18.4241),
  lat = c(-13.9626, -17.8292, -26.1952, -33.9249),
  stringsAsFactors = FALSE
)

# Function to extract climate at coordinates
extract_climate_at_point <- function(raster, lon, lat) {
  point <- vect(data.frame(x = lon, y = lat), geom = c("x", "y"), crs = "EPSG:4326")
  climate_value <- extract(raster, point)[1, 2]
  return(as.character(climate_value))
}

create_enhanced_map <- function(raster_path, title, subtitle, warming_color, scenario_label) {
  # Load and process raster
  koppen_raster <- rast(raster_path)
  sa_bbox <- ext(10, 42, -35, -8)
  koppen_sa <- crop(koppen_raster, sa_bbox)
  koppen_sa_agg <- aggregate(koppen_sa, fact = 4, fun = "modal")
  
  # Convert to polygons
  koppen_polygons <- as.polygons(koppen_sa_agg, dissolve = TRUE)
  koppen_sf <- st_as_sf(koppen_polygons)
  
  # Prepare data
  data_col <- names(koppen_sf)[1]
  koppen_sf <- koppen_sf %>%
    filter(!is.na(.data[[data_col]])) %>%
    mutate(climate_code = as.character(.data[[data_col]]))
  
  # Extract climate zones for each city
  city_climates <- data.frame()
  for (i in 1:nrow(cities)) {
    climate_code <- extract_climate_at_point(koppen_raster, cities$lon[i], cities$lat[i])
    city_climates <- rbind(city_climates, data.frame(
      city = cities$city[i],
      country = cities$country[i],
      lon = cities$lon[i],
      lat = cities$lat[i],
      climate_code = climate_code,
      climate_zone = koppen_names[climate_code]
    ))
  }
  
  # Filter colors to present codes
  present_codes <- unique(koppen_sf$climate_code)
  present_colors <- enhanced_koppen_colors[present_codes]
  present_colors <- present_colors[!is.na(present_colors)]
  
  # Create map
  p <- ggplot() +
    geom_sf(data = koppen_sf, 
            aes(fill = climate_code), 
            color = "white", 
            linewidth = 0.1,
            alpha = 0.85) +
    scale_fill_manual(values = present_colors, na.value = "transparent") +
    
    # Add city points
    geom_point(data = city_climates, 
               aes(x = lon, y = lat), 
               size = 4, color = "white", fill = "#E31A1C", 
               shape = 21, stroke = 2) +
    
    # City labels with climate zones
    geom_text(data = city_climates,
              aes(x = lon + 1.5, y = lat + 1.2, 
                  label = paste0(city, "\n", country, "\n(", climate_zone, ")")),
              size = 2.8, fontface = "bold", hjust = 0,
              color = "black", bg = "white") +
    
    coord_sf(xlim = c(12, 42), ylim = c(-35, -8), expand = FALSE) +
    labs(title = title, subtitle = subtitle, 
         x = "Longitude (°E)", y = "Latitude (°S)") +
    theme_enhanced() +
    
    # Scenario indicator with enhanced styling
    annotate("rect", xmin = 38.5, xmax = 41.5, ymin = -34.5, ymax = -31.5,
             fill = warming_color, color = "white", alpha = 0.9, linewidth = 1) +
    annotate("text", x = 40, y = -33, 
             label = scenario_label, 
             size = 4, fontface = "bold", color = "white") +
    
    # Add country borders for context
    geom_sf(data = koppen_sf, fill = NA, color = "gray60", linewidth = 0.3)
  
  return(p)
}

# Extract climate data for all scenarios
scenarios <- list(
  baseline = list(
    path = "high_res_koppen/1991_2020/koppen_geiger_0p00833333.tif",
    title = "Current Climate",
    subtitle = "1991-2020 baseline",
    color = "#2E8B57",
    label = "BASELINE\n1991-2020"
  ),
  moderate = list(
    path = "high_res_koppen/2071_2099/ssp245/koppen_geiger_0p00833333.tif",
    title = "Moderate Warming",
    subtitle = "SSP2-4.5 (+2.5°C)",
    color = "#FF8C00",
    label = "MODERATE\n+2.5°C\n2071-2099"
  ),
  extreme = list(
    path = "high_res_koppen/2071_2099/ssp585/koppen_geiger_0p00833333.tif",
    title = "Extreme Warming",
    subtitle = "SSP5-8.5 (+4.5°C)",
    color = "#DC143C",
    label = "EXTREME\n+4.5°C\n2071-2099"
  )
)

# Create all maps
maps <- list()
cat("Creating enhanced progression maps...\n")

for (scenario_name in names(scenarios)) {
  scenario <- scenarios[[scenario_name]]
  maps[[scenario_name]] <- create_enhanced_map(
    scenario$path, scenario$title, scenario$subtitle, 
    scenario$color, scenario$label
  )
}

# Create shared legend with enhanced styling
legend_data <- data.frame(
  code = names(enhanced_koppen_colors),
  zone = koppen_names[names(enhanced_koppen_colors)],
  color = unname(enhanced_koppen_colors)
)
legend_data <- legend_data[!is.na(legend_data$zone), ]

legend_plot <- ggplot(legend_data, aes(x = 1, y = code, fill = code)) +
  geom_point(alpha = 0) +
  scale_fill_manual(
    name = "Köppen-Geiger Climate Zones",
    values = enhanced_koppen_colors,
    labels = koppen_names,
    na.value = "transparent"
  ) +
  theme_void() +
  theme(
    legend.position = "bottom",
    legend.title = element_text(family = "Arial", size = 12, face = "bold"),
    legend.text = element_text(family = "Arial", size = 9),
    legend.key.size = unit(0.5, "cm"),
    legend.margin = margin(t = 20)
  ) +
  guides(fill = guide_legend(ncol = 8, byrow = TRUE))

# Enhanced final diagram with data sources
final_diagram <- maps$baseline + maps$moderate + maps$extreme + 
  plot_layout(nrow = 1) +
  plot_annotation(
    title = "Southern Africa Climate Change Trajectory",
    subtitle = "Köppen-Geiger Climate Zones: Current Conditions → Future Warming Scenarios",
    caption = paste(
      "Data: Beck et al. (2023) High-resolution Köppen-Geiger maps | DOI: 10.1038/s41597-023-02549-6",
      "Source: https://figshare.com/articles/dataset/21789074 | 1km resolution",
      "Baseline: 1991-2020 (30-year climate normal) | Projections: 2071-2099 CMIP6 scenarios",
      sep = "\n"
    ),
    theme = theme(
      plot.title = element_text(family = "Arial", size = 20, face = "bold", hjust = 0.5, margin = margin(b = 8)),
      plot.subtitle = element_text(family = "Arial", size = 14, hjust = 0.5, color = "gray30", margin = margin(b = 15)),
      plot.caption = element_text(family = "Arial", size = 8, hjust = 0.5, color = "gray50", 
                                  lineheight = 1.2, margin = margin(t = 15))
    )
  )

# Add legend
final_with_legend <- final_diagram / legend_plot + 
  plot_layout(heights = c(1, 0.2))

# Save enhanced diagram
ggsave("southern_africa_climate_trajectory_enhanced_final.svg", final_with_legend, 
       width = 32, height = 20, bg = "white", device = "svg")

cat("\n🎯 Enhanced climate trajectory diagram created!\n")
cat("File: southern_africa_climate_trajectory_enhanced_final.svg\n")
cat("Features:\n")
cat("- Data sources and paper citation included\n")
cat("- Major cities labeled with climate zones for each scenario\n")
cat("- Enhanced styling for professional presentation\n")
cat("- Optimized for Figma editing (SVG format)\n")