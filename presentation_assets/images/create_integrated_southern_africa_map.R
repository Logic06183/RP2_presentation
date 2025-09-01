#!/usr/bin/env Rscript
# Integrated Southern Africa Climate & Socioeconomic Map
# Combines Köppen-Geiger climate zones with table data for Wellcome Trust grant
# Shows climate context with socioeconomic and health indicators

# Load required libraries
suppressPackageStartupMessages({
  library(sf)
  library(ggplot2)
  library(dplyr)
  library(scales)
  library(rnaturalearth)
  library(rnaturalearthdata)
  library(gridExtra)
  library(grid)
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

# Define Köppen climate colors (same as original)
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

create_integrated_southern_africa_map <- function() {
  tryCatch({
    cat("Loading data for integrated southern Africa climate map...\n")
    
    # Load climate data
    climate_data <- st_read("koppen_africa_with_labels.geojson", quiet = TRUE)
    
    # Get country boundaries
    countries <- ne_countries(scale = "medium", returnclass = "sf")
    
    # Define comprehensive country data from the table
    country_data <- data.frame(
      name = c("South Africa", "Zimbabwe", "Malawi"),
      iso_a3 = c("ZAF", "ZWE", "MWI"),
      
      # Economic indicators
      world_bank_class = c("Upper middle income", "Lower middle income", "Low income"),
      gdp_per_capita = c(6023, 2156, 520),
      health_expenditure = c(16.89, 2.79, 7.41),
      urban_percent = c(68.82, 32, 18.3),
      
      # Health indicators
      life_expectancy = c(64, 62, 66.4),
      hiv_prevalence = c(17.2, 9.8, 6.2),
      fertility_rate = c(2.2, 3.6, 3.8),
      maternal_mortality = c(117.57, 357.6, 225),
      
      # Climate vulnerability
      ndgain_vulnerability_rank = c(117, 51, 26),
      ndgain_readiness_rank = c(122, 186, 158),
      temp_increase_since_1980s = c(1.2, 1.0, 1.0),
      
      # Dominant climate from our analysis
      dominant_climate = c("BWk", "Aw", "Aw"),
      climate_zones_count = c(11, 3, 2),
      
      # Capital cities for labeling
      capital_lon = c(28.034088, 31.0492, 33.7703),
      capital_lat = c(-26.195246, -17.8292, -13.9626),
      capital_name = c("Johannesburg", "Harare", "Lilongwe"),
      
      stringsAsFactors = FALSE
    )
    
    # Filter countries and merge with data
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
    
    # Create capitals as sf points
    capitals_sf <- st_as_sf(country_data, coords = c("capital_lon", "capital_lat"), crs = 4326)
    
    # Create the main map
    main_map <- ggplot() +
      # Plot climate zones
      geom_sf(data = climate_southern, 
              aes(fill = koppen_code), 
              color = "white", 
              linewidth = 0.1, 
              alpha = 0.7) +
      # Add all southern Africa countries for context
      geom_sf(data = southern_africa, 
              fill = NA, 
              color = "gray50", 
              linewidth = 0.3) +
      # Highlight target countries with different border styles by vulnerability
      geom_sf(data = target_countries_sf, 
              fill = NA, 
              aes(color = factor(name)), 
              linewidth = 1.2,
              linetype = "solid") +
      # Add capitals with size based on GDP per capita
      geom_sf(data = capitals_sf, 
              aes(size = gdp_per_capita),
              color = "#E3120B", 
              fill = "white",
              shape = 21,
              stroke = 1.5) +
      # Add capital labels using annotate for better control
      annotate("text", x = 28.034088 + 2, y = -26.195246 + 1, 
               label = "Johannesburg\nSouth Africa", size = 3, fontface = "bold", hjust = 0) +
      annotate("text", x = 31.0492 + 2, y = -17.8292 + 1, 
               label = "Harare\nZimbabwe", size = 3, fontface = "bold", hjust = 0) +
      annotate("text", x = 33.7703 + 2, y = -13.9626 + 1, 
               label = "Lilongwe\nMalawi", size = 3, fontface = "bold", hjust = 0) +
      # Set colors
      scale_fill_manual(
        name = "Köppen-Geiger Climate Zones",
        values = koppen_colors,
        labels = function(x) {
          ifelse(x %in% names(climate_labels), 
                 paste0(x, " - ", climate_labels[x]), 
                 x)
        },
        guide = guide_legend(
          override.aes = list(alpha = 1, color = "white"),
          ncol = 3
        )
      ) +
      scale_color_manual(
        name = "Target Countries",
        values = c("South Africa" = "#1f77b4", "Zimbabwe" = "#ff7f0e", "Malawi" = "#2ca02c"),
        guide = guide_legend(
          override.aes = list(fill = NA, linewidth = 1.2)
        )
      ) +
      scale_size_continuous(
        name = "GDP per capita (USD)",
        range = c(3, 7),
        labels = scales::dollar_format(),
        guide = guide_legend(
          override.aes = list(color = "#E3120B", fill = "white", stroke = 1.5)
        )
      ) +
      # Set coordinate system
      coord_sf(xlim = c(10, 42), ylim = c(-35, -8), expand = FALSE) +
      # Labels and title
      labs(
        title = "Southern Africa: Climate Zones & Development Context",
        subtitle = "Köppen-Geiger climate classification with socioeconomic indicators for Wellcome Trust study",
        x = "Longitude (°E)",
        y = "Latitude (°S)"
      ) +
      theme_publication()
    
    return(list(map = main_map, data = target_countries_sf))
    
  }, error = function(e) {
    cat(sprintf("Error creating integrated map: %s\n", e$message))
    return(NULL)
  })
}

# Create summary table plot
create_summary_table <- function(country_data) {
  # Prepare data for table visualization
  table_data <- country_data %>%
    st_drop_geometry() %>%
    select(name, world_bank_class, gdp_per_capita, life_expectancy, 
           hiv_prevalence, ndgain_vulnerability_rank, temp_increase_since_1980s,
           dominant_climate) %>%
    mutate(
      gdp_formatted = paste0("$", format(gdp_per_capita, big.mark = ",")),
      vulnerability = paste0("#", ndgain_vulnerability_rank, " most vulnerable"),
      temp_change = paste0("+", temp_increase_since_1980s, "°C since 1980s"),
      climate_zone = paste0(dominant_climate, " (dominant)")
    ) %>%
    select(Country = name, 
           `Income Level` = world_bank_class,
           `GDP per capita` = gdp_formatted,
           `Life Expectancy` = life_expectancy,
           `HIV Prevalence (%)` = hiv_prevalence,
           `Climate Vulnerability` = vulnerability,
           `Temperature Rise` = temp_change,
           `Dominant Climate` = climate_zone)
  
  # Create table plot
  table_plot <- tableGrob(table_data, 
                         theme = ttheme_minimal(
                           core = list(fg_params = list(fontsize = 9)),
                           colhead = list(fg_params = list(fontsize = 10, fontface = "bold"))
                         ))
  
  return(table_plot)
}

# Create the integrated visualization
cat("Creating integrated southern Africa climate and development map...\n")
result <- create_integrated_southern_africa_map()

if (!is.null(result)) {
  main_map <- result$map
  country_data <- result$data
  
  # Create summary table
  summary_table <- create_summary_table(country_data)
  
  # Combine map and table
  combined_plot <- grid.arrange(
    main_map, 
    summary_table,
    heights = c(3, 1),
    top = textGrob("Southern Africa Climate & Development Context", 
                   gp = gpar(fontsize = 16, fontface = "bold"))
  )
  
  # Save the integrated visualization
  ggsave("southern_africa_integrated_climate_development_map.png", 
         plot = combined_plot,
         width = 14, height = 12, 
         dpi = 300, 
         bg = "white")
  
  ggsave("southern_africa_integrated_climate_development_map.pdf", 
         plot = combined_plot,
         width = 14, height = 12, 
         bg = "white")
  
  # Also save just the map component
  ggsave("southern_africa_enhanced_climate_map.png", 
         plot = main_map,
         width = 12, height = 9, 
         dpi = 300, 
         bg = "white")
  
  ggsave("southern_africa_enhanced_climate_map.svg", 
         plot = main_map,
         width = 12, height = 9, 
         bg = "white")
  
  cat("Integrated maps saved:\n")
  cat("- southern_africa_integrated_climate_development_map.png/pdf (map + table)\n")
  cat("- southern_africa_enhanced_climate_map.png/svg (map only)\n")
  
} else {
  cat("Failed to create integrated map\n")
}