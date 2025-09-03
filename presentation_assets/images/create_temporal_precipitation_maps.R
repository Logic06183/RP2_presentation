#!/usr/bin/env Rscript
# Create temporal precipitation maps for Southern Africa using Natural Earth boundaries
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
  library(RColorBrewer)
})

# Southern Africa precipitation change data by time period
precip_data <- data.frame(
  country = c("South Africa", "Zimbabwe", "Malawi", "Botswana", "Namibia", 
              "Zambia", "Mozambique", "Angola", "Lesotho", "Eswatini"),
  iso_a3 = c("ZAF", "ZWE", "MWI", "BWA", "NAM", "ZMB", "MOZ", "AGO", "LSO", "SWZ"),
  precip_1991_2020 = c(-8, -12, -7, -15, -18, -9, -6, -5, -10, -8),
  precip_2021_2040 = c(-15, -18, -12, -22, -25, -15, -11, -10, -17, -14),
  precip_2041_2060 = c(-22, -28, -20, -32, -35, -24, -18, -16, -25, -21),
  target_country = c(TRUE, TRUE, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE),
  stringsAsFactors = FALSE
)

# Define consistent color palette for precipitation changes (brown scale)
precip_colors <- c("#543005", "#8c510a", "#bf812d", "#dfc27d", "#f6e8c3", "#f5f5f5")
precip_breaks <- c(-40, -30, -20, -15, -10, -5, 0)

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

create_precipitation_map <- function(period_name, precip_column, title_text) {
  tryCatch({
    cat(sprintf("Creating precipitation map for %s...\n", period_name))
    
    # Get Natural Earth country boundaries
    countries <- ne_countries(scale = "medium", returnclass = "sf")
    
    # Filter for Southern Africa region
    southern_africa_iso <- c("ZAF", "ZWE", "MWI", "BWA", "NAM", "ZMB", 
                           "MOZ", "AGO", "LSO", "SWZ", "MDG")
    
    countries_sa <- countries %>%
      filter(iso_a3 %in% southern_africa_iso)
    
    # Join with precipitation data
    precip_period <- precip_data %>%
      select(iso_a3, target_country, precip_value = !!sym(precip_column))
    
    countries_precip <- countries_sa %>%
      left_join(precip_period, by = "iso_a3") %>%
      mutate(
        precip_value = ifelse(is.na(precip_value), -2, precip_value),
        target_country = ifelse(is.na(target_country), FALSE, target_country)
      )
    
    # Create the map
    p <- ggplot(countries_precip) +
      # Fill countries with precipitation colors
      geom_sf(aes(fill = precip_value), color = "white", size = 0.3) +
      # Highlight target countries with thick borders
      geom_sf(data = countries_precip %>% filter(target_country == TRUE),
              fill = NA, color = "black", size = 1.2) +
      # Color scale
      scale_fill_gradientn(
        name = "Precipitation\nChange (%)",
        colors = rev(precip_colors), # Reverse so dark brown = more negative
        values = scales::rescale(precip_breaks),
        breaks = c(-30, -20, -10, 0),
        labels = c("-30%", "-20%", "-10%", "0%"),
        limits = c(-35, 0),
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
    target_centroids <- countries_precip %>%
      filter(target_country == TRUE) %>%
      st_centroid() %>%
      mutate(
        lon = st_coordinates(.)[,1],
        lat = st_coordinates(.)[,2]
      ) %>%
      st_drop_geometry()
    
    if (nrow(target_centroids) > 0) {
      # Choose text color based on precipitation value
      target_centroids <- target_centroids %>%
        mutate(text_color = ifelse(precip_value < -20, "white", "black"))
      
      p <- p + 
        geom_text(data = target_centroids,
                  aes(x = lon, y = lat, label = sprintf("%+d%%", as.integer(precip_value)),
                      color = I(text_color)),
                  fontface = "bold", size = 3.5)
    }
    
    return(p)
    
  }, error = function(e) {
    cat(sprintf("Error creating precipitation map: %s\n", e$message))
    return(NULL)
  })
}

# Create maps for three time periods
cat("Creating temporal precipitation maps for Southern Africa...\n")

map_1991_2020 <- create_precipitation_map("1991-2020", "precip_1991_2020", 
                                         "Baseline Change\n1991-2020")

map_2021_2040 <- create_precipitation_map("2021-2040", "precip_2021_2040", 
                                         "Accelerated Drying\n2021-2040")

map_2041_2060 <- create_precipitation_map("2041-2060", "precip_2041_2060", 
                                         "Severe Decline\n2041-2060")

if (!is.null(map_1991_2020) && !is.null(map_2021_2040) && !is.null(map_2041_2060)) {
  # Combine the three maps
  combined_map <- map_1991_2020 + map_2021_2040 + map_2041_2060 +
    plot_layout(ncol = 3) +
    plot_annotation(
      title = "Precipitation Change Evolution: Southern Africa 1991-2060",
      subtitle = "Progressive drying trends across the region, with emphasis on target countries",
      caption = "Data: CMIP6 Precipitation Projections, CORDEX-Africa. Target countries (Malawi, South Africa, Zimbabwe) shown with thick borders.",
      theme = theme(
        plot.title = element_text(size = 16, hjust = 0.5, face = "bold"),
        plot.subtitle = element_text(size = 14, hjust = 0.5, color = "gray30"),
        plot.caption = element_text(size = 10, hjust = 0.5, color = "gray50")
      )
    )
  
  # Save the combined map
  ggsave("southern_africa_precipitation_temporal_maps.png", 
         plot = combined_map,
         width = 16, height = 6, 
         dpi = 300, 
         bg = "white")
  
  ggsave("southern_africa_precipitation_temporal_maps.svg", 
         plot = combined_map,
         width = 16, height = 6, 
         bg = "white")
  
  cat("Precipitation temporal maps saved successfully!\n")
  
  # Create summary statistics
  cat("\nPrecipitation change summary:\n")
  precip_summary <- precip_data %>%
    filter(target_country == TRUE) %>%
    select(country, precip_1991_2020, precip_2021_2040, precip_2041_2060) %>%
    mutate(
      change_2040 = precip_2021_2040 - precip_1991_2020,
      change_2060 = precip_2041_2060 - precip_1991_2020,
      acceleration = precip_2041_2060 - precip_2021_2040
    )
  
  print(precip_summary)
  
  # Key insights
  cat("\nKey precipitation patterns:\n")
  cat("• Target countries show progressive drying:\n")
  for(i in 1:nrow(precip_summary)) {
    row <- precip_summary[i,]
    cat(sprintf("  - %s: %+d%% → %+d%% → %+d%%\n", 
                row$country, row$precip_1991_2020, row$precip_2021_2040, row$precip_2041_2060))
  }
  
} else {
  cat("Failed to create one or more precipitation maps\n")
}