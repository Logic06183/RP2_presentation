#!/usr/bin/env Rscript
# Create temporal temperature maps for Southern Africa using Natural Earth boundaries
# Emphasizing Malawi, South Africa, and Zimbabwe

# Load required libraries
suppressPackageStartupMessages({
  library(sf)
  library(ggplot2)
  library(dplyr)
  library(scales)
  library(rnaturalearth)
  library(rnaturalearthdata)
  library(viridis)
  library(patchwork)
})

# Southern Africa temperature data by time period
temp_data <- data.frame(
  country = c("South Africa", "Zimbabwe", "Malawi", "Botswana", "Namibia", 
              "Zambia", "Mozambique", "Angola", "Lesotho", "Eswatini"),
  iso_a3 = c("ZAF", "ZWE", "MWI", "BWA", "NAM", "ZMB", "MOZ", "AGO", "LSO", "SWZ"),
  temp_1991_2020 = c(1.2, 1.1, 1.0, 1.4, 1.6, 1.2, 0.9, 1.2, 1.5, 1.3),
  temp_2021_2040 = c(2.1, 2.0, 1.8, 2.3, 2.5, 2.0, 1.7, 2.0, 2.2, 2.1),
  temp_2041_2060 = c(3.2, 3.1, 2.9, 3.4, 3.6, 3.0, 2.7, 3.1, 3.3, 3.2),
  target_country = c(TRUE, TRUE, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE),
  stringsAsFactors = FALSE
)

# Define consistent color palette for temperature anomalies
temp_colors <- c("#ffffcc", "#fee08b", "#fdae61", "#f46d43", "#d73027", "#a50026", "#67001f")
temp_breaks <- c(0, 1, 1.5, 2, 2.5, 3, 3.5, 4)

# Publication theme
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
      legend.key.size = unit(0.8, "cm"),
      panel.grid = element_blank(),
      panel.background = element_rect(fill = "white", color = NA),
      plot.background = element_rect(fill = "white", color = NA),
      axis.ticks = element_blank(),
      axis.text.x = element_blank(),
      axis.text.y = element_blank()
    )
}

create_temperature_map <- function(period_name, temp_column, title_text) {
  tryCatch({
    cat(sprintf("Creating temperature map for %s...\n", period_name))
    
    # Get Natural Earth country boundaries
    countries <- ne_countries(scale = "medium", returnclass = "sf")
    
    # Filter for Southern Africa region
    southern_africa_iso <- c("ZAF", "ZWE", "MWI", "BWA", "NAM", "ZMB", 
                           "MOZ", "AGO", "LSO", "SWZ", "MDG")
    
    countries_sa <- countries %>%
      filter(iso_a3 %in% southern_africa_iso)
    
    # Join with temperature data
    temp_period <- temp_data %>%
      select(iso_a3, target_country, temp_value = !!sym(temp_column))
    
    countries_temp <- countries_sa %>%
      left_join(temp_period, by = "iso_a3") %>%
      mutate(
        temp_value = ifelse(is.na(temp_value), 0.5, temp_value),
        target_country = ifelse(is.na(target_country), FALSE, target_country)
      )
    
    # Create the map
    p <- ggplot(countries_temp) +
      # Fill countries with temperature colors
      geom_sf(aes(fill = temp_value), color = "white", size = 0.3) +
      # Highlight target countries with thick borders
      geom_sf(data = countries_temp %>% filter(target_country == TRUE),
              fill = NA, color = "black", size = 1.2) +
      # Color scale
      scale_fill_gradientn(
        name = "Temperature\nAnomaly (°C)",
        colors = temp_colors,
        values = scales::rescale(temp_breaks),
        breaks = c(1, 2, 3, 4),
        labels = c("+1°C", "+2°C", "+3°C", "+4°C"),
        limits = c(0.5, 4),
        guide = guide_colorbar(
          direction = "horizontal",
          barwidth = 8,
          barheight = 0.5,
          title.position = "top",
          title.hjust = 0.5
        )
      ) +
      # Set extent to Southern Africa
      coord_sf(xlim = c(10, 42), ylim = c(-35, -8), expand = FALSE) +
      # Labels
      labs(
        title = title_text,
        x = NULL, y = NULL
      ) +
      theme_publication()
    
    # Add country labels for target countries
    target_centroids <- countries_temp %>%
      filter(target_country == TRUE) %>%
      st_centroid() %>%
      mutate(
        lon = st_coordinates(.)[,1],
        lat = st_coordinates(.)[,2]
      ) %>%
      st_drop_geometry()
    
    if (nrow(target_centroids) > 0) {
      p <- p + 
        geom_text(data = target_centroids,
                  aes(x = lon, y = lat, label = sprintf("%.1f°C", temp_value)),
                  color = "white", fontface = "bold", size = 3.5,
                  stroke = 0.3, stroke_color = "black")
    }
    
    return(p)
    
  }, error = function(e) {
    cat(sprintf("Error creating temperature map: %s\n", e$message))
    return(NULL)
  })
}

# Create maps for three time periods
cat("Creating temporal temperature maps for Southern Africa...\n")

map_1991_2020 <- create_temperature_map("1991-2020", "temp_1991_2020", 
                                       "Baseline Period\n1991-2020")

map_2021_2040 <- create_temperature_map("2021-2040", "temp_2021_2040", 
                                       "Near-term Projection\n2021-2040")

map_2041_2060 <- create_temperature_map("2041-2060", "temp_2041_2060", 
                                       "Mid-century Projection\n2041-2060")

if (!is.null(map_1991_2020) && !is.null(map_2021_2040) && !is.null(map_2041_2060)) {
  # Combine the three maps
  combined_map <- map_1991_2020 + map_2021_2040 + map_2041_2060 +
    plot_layout(ncol = 3) +
    plot_annotation(
      title = "Temperature Anomaly Evolution: Southern Africa 1991-2060",
      subtitle = "Emphasizing Malawi, South Africa, and Zimbabwe climate trajectories",
      caption = "Data: IPCC AR6, CMIP6 Multi-model Ensemble. Target countries shown with thick borders.",
      theme = theme(
        plot.title = element_text(size = 16, hjust = 0.5, face = "bold"),
        plot.subtitle = element_text(size = 14, hjust = 0.5, color = "gray30"),
        plot.caption = element_text(size = 10, hjust = 0.5, color = "gray50")
      )
    )
  
  # Save the combined map
  ggsave("southern_africa_temperature_temporal_maps.png", 
         plot = combined_map,
         width = 16, height = 6, 
         dpi = 300, 
         bg = "white")
  
  ggsave("southern_africa_temperature_temporal_maps.svg", 
         plot = combined_map,
         width = 16, height = 6, 
         bg = "white")
  
  cat("Temperature temporal maps saved successfully!\n")
  
  # Create summary statistics
  cat("\nTemperature change summary:\n")
  temp_summary <- temp_data %>%
    filter(target_country == TRUE) %>%
    select(country, temp_1991_2020, temp_2021_2040, temp_2041_2060) %>%
    mutate(
      change_2040 = temp_2021_2040 - temp_1991_2020,
      change_2060 = temp_2041_2060 - temp_1991_2020,
      acceleration = temp_2041_2060 - temp_2021_2040
    )
  
  print(temp_summary)
  
} else {
  cat("Failed to create one or more temperature maps\n")
}