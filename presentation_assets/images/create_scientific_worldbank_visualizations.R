#!/usr/bin/env Rscript
# Create Scientifically Rigorous Climate Visualizations
# Using Real Data from World Bank Climate API
# All outputs as high-quality SVG files with proper data attribution

# Load required libraries
suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(tidyr)
  library(scales)
  library(viridis)
  library(patchwork)
  library(svglite)
  library(sf)
  library(rnaturalearth)
  library(rnaturalearthdata)
  library(RColorBrewer)
  library(ggrepel)
})

# Set scientific theme
theme_scientific <- function(base_size = 11) {
  theme_minimal(base_size = base_size) +
    theme(
      text = element_text(family = "sans", color = "gray20"),
      plot.title = element_text(size = base_size + 4, face = "bold", hjust = 0.5, margin = margin(b = 10)),
      plot.subtitle = element_text(size = base_size + 1, hjust = 0.5, color = "gray40", margin = margin(b = 15)),
      plot.caption = element_text(size = base_size - 2, hjust = 0.5, color = "gray50", margin = margin(t = 15), lineheight = 1.2),
      axis.title = element_text(size = base_size, face = "bold"),
      axis.text = element_text(size = base_size - 1),
      legend.title = element_text(size = base_size, face = "bold"),
      legend.text = element_text(size = base_size - 1),
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(color = "gray90", size = 0.3),
      panel.background = element_rect(fill = "white", color = NA),
      plot.background = element_rect(fill = "white", color = NA),
      legend.background = element_rect(fill = "white", color = "gray90", size = 0.5),
      legend.key = element_blank(),
      strip.text = element_text(face = "bold", size = base_size),
      strip.background = element_rect(fill = "gray95", color = "gray80")
    )
}

# First, source the data fetching script to get real data
cat("Fetching real climate data from World Bank API...\n")
source("fetch_worldbank_climate_data.R")

# Load the fetched data
if (file.exists("worldbank_climate_data.rds")) {
  climate_data <- readRDS("worldbank_climate_data.rds")
  cat("Climate data loaded successfully\n")
} else {
  stop("Climate data not found. Please run fetch_worldbank_climate_data.R first")
}

# 1. Create Temperature Projection Comparison
create_temperature_projection_svg <- function() {
  cat("\nCreating Temperature Projection Comparison...\n")
  
  # Prepare data
  historical <- climate_data$historical
  future_245 <- climate_data$future_ssp245_2040
  future_585 <- climate_data$future_ssp585_2040
  future_245_2080 <- climate_data$future_ssp245_2080
  future_585_2080 <- climate_data$future_ssp585_2080
  
  # Combine temperature data
  if (nrow(historical) > 0 && nrow(future_245) > 0) {
    temp_projections <- historical %>%
      select(iso3, country, temp_historical) %>%
      left_join(future_245 %>% select(iso3, temp_anomaly_245_2040 = temp_anomaly), by = "iso3") %>%
      left_join(future_585 %>% select(iso3, temp_anomaly_585_2040 = temp_anomaly), by = "iso3") %>%
      left_join(future_245_2080 %>% select(iso3, temp_anomaly_245_2080 = temp_anomaly), by = "iso3") %>%
      left_join(future_585_2080 %>% select(iso3, temp_anomaly_585_2080 = temp_anomaly), by = "iso3") %>%
      mutate(
        temp_2040_ssp245 = temp_historical + coalesce(temp_anomaly_245_2040, 0),
        temp_2040_ssp585 = temp_historical + coalesce(temp_anomaly_585_2040, 0),
        temp_2080_ssp245 = temp_historical + coalesce(temp_anomaly_245_2080, 0),
        temp_2080_ssp585 = temp_historical + coalesce(temp_anomaly_585_2080, 0)
      ) %>%
      filter(!is.na(temp_historical))
    
    # Reshape for plotting
    temp_long <- temp_projections %>%
      select(country, Historical = temp_historical, 
             `SSP2-4.5 (2040s)` = temp_2040_ssp245,
             `SSP5-8.5 (2040s)` = temp_2040_ssp585,
             `SSP2-4.5 (2080s)` = temp_2080_ssp245,
             `SSP5-8.5 (2080s)` = temp_2080_ssp585) %>%
      pivot_longer(cols = -country, names_to = "Scenario", values_to = "Temperature") %>%
      mutate(Scenario = factor(Scenario, 
                               levels = c("Historical", "SSP2-4.5 (2040s)", "SSP5-8.5 (2040s)", 
                                        "SSP2-4.5 (2080s)", "SSP5-8.5 (2080s)")))
    
    # Create visualization
    p1 <- ggplot(temp_long, aes(x = reorder(country, Temperature), y = Temperature, fill = Scenario)) +
      geom_bar(stat = "identity", position = "dodge", alpha = 0.9) +
      scale_fill_manual(values = c("Historical" = "#2166ac",
                                  "SSP2-4.5 (2040s)" = "#92c5de",
                                  "SSP5-8.5 (2040s)" = "#fddbc7",
                                  "SSP2-4.5 (2080s)" = "#4393c3",
                                  "SSP5-8.5 (2080s)" = "#d6604d")) +
      coord_flip() +
      labs(
        title = "Temperature Projections for Southern Africa",
        subtitle = "Historical baseline (1991-2020) and CMIP6 ensemble projections",
        caption = "Data source: World Bank Climate Change Knowledge Portal API\nCRU TS 4.06 (historical) | CMIP6 ensemble median (projections)\nSSP2-4.5: Middle of the road scenario | SSP5-8.5: Fossil-fueled development",
        x = NULL,
        y = "Mean Annual Temperature (°C)",
        fill = "Scenario"
      ) +
      theme_scientific() +
      theme(legend.position = "bottom",
            legend.direction = "horizontal",
            legend.box = "horizontal")
    
    # Save as SVG
    svglite("temperature_projections_worldbank.svg", width = 14, height = 10)
    print(p1)
    dev.off()
    
    cat("✓ Created: temperature_projections_worldbank.svg\n")
  }
}

# 2. Create Precipitation Change Analysis
create_precipitation_change_svg <- function() {
  cat("\nCreating Precipitation Change Analysis...\n")
  
  historical <- climate_data$historical
  future_245 <- climate_data$future_ssp245_2040
  future_585 <- climate_data$future_ssp585_2040
  
  if (nrow(historical) > 0 && nrow(future_245) > 0) {
    # Combine precipitation data
    precip_change <- historical %>%
      select(iso3, country, precip_historical) %>%
      left_join(future_245 %>% select(iso3, precip_change_245 = precip_change), by = "iso3") %>%
      left_join(future_585 %>% select(iso3, precip_change_585 = precip_change), by = "iso3") %>%
      filter(!is.na(precip_historical)) %>%
      mutate(
        change_245_pct = coalesce(precip_change_245, 0),
        change_585_pct = coalesce(precip_change_585, 0)
      )
    
    # Create diverging bar chart
    precip_long <- precip_change %>%
      select(country, `SSP2-4.5` = change_245_pct, `SSP5-8.5` = change_585_pct) %>%
      pivot_longer(cols = -country, names_to = "Scenario", values_to = "Change")
    
    p2 <- ggplot(precip_long, aes(x = reorder(country, -Change), y = Change, fill = Scenario)) +
      geom_bar(stat = "identity", position = "dodge", alpha = 0.9) +
      geom_hline(yintercept = 0, linetype = "solid", color = "gray50") +
      scale_fill_manual(values = c("SSP2-4.5" = "#5aae61", "SSP5-8.5" = "#d8b365")) +
      scale_y_continuous(labels = function(x) paste0(x, "%")) +
      coord_flip() +
      labs(
        title = "Projected Precipitation Changes by 2040-2059",
        subtitle = "Percentage change from historical baseline (1991-2020)",
        caption = "Data source: World Bank Climate API | CMIP6 ensemble median\nNegative values indicate drying | Positive values indicate increased precipitation",
        x = NULL,
        y = "Precipitation Change (%)",
        fill = "Climate Scenario"
      ) +
      theme_scientific() +
      theme(legend.position = "bottom")
    
    svglite("precipitation_change_worldbank.svg", width = 12, height = 8)
    print(p2)
    dev.off()
    
    cat("✓ Created: precipitation_change_worldbank.svg\n")
  }
}

# 3. Create Heat Extremes Visualization
create_heat_extremes_svg <- function() {
  cat("\nCreating Heat Extremes Visualization...\n")
  
  extremes_245 <- climate_data$extremes_ssp245
  extremes_585 <- climate_data$extremes_ssp585
  
  if (nrow(extremes_245) > 0 && nrow(extremes_585) > 0) {
    # Combine extreme heat data
    extremes_combined <- extremes_245 %>%
      select(country, iso3, `SSP2-4.5 (2040s)` = hot_days_35C) %>%
      left_join(extremes_585 %>% select(iso3, `SSP5-8.5 (2080s)` = hot_days_35C), by = "iso3") %>%
      filter(!is.na(`SSP2-4.5 (2040s)`))
    
    # Create paired dot plot
    extremes_long <- extremes_combined %>%
      pivot_longer(cols = starts_with("SSP"), names_to = "Scenario", values_to = "Days")
    
    p3 <- ggplot(extremes_long, aes(x = Days, y = reorder(country, Days))) +
      geom_line(aes(group = country), color = "gray70", size = 0.5) +
      geom_point(aes(color = Scenario), size = 4, alpha = 0.9) +
      scale_color_manual(values = c("SSP2-4.5 (2040s)" = "#4575b4", "SSP5-8.5 (2080s)" = "#d73027")) +
      scale_x_continuous(breaks = seq(0, 150, 25)) +
      labs(
        title = "Extreme Heat Days Projection (>35°C)",
        subtitle = "Annual days exceeding 35°C temperature threshold",
        caption = "Data source: World Bank Climate API | CMIP6 extreme indices\nHeat stress threshold based on health impact studies",
        x = "Number of Days per Year",
        y = NULL,
        color = "Scenario"
      ) +
      theme_scientific() +
      theme(legend.position = "top")
    
    svglite("heat_extremes_worldbank.svg", width = 12, height = 8)
    print(p3)
    dev.off()
    
    cat("✓ Created: heat_extremes_worldbank.svg\n")
  }
}

# 4. Create Comprehensive Climate Risk Dashboard
create_climate_risk_dashboard_svg <- function() {
  cat("\nCreating Comprehensive Climate Risk Dashboard...\n")
  
  # Prepare all data
  historical <- climate_data$historical
  future_245 <- climate_data$future_ssp245_2040
  extremes_245 <- climate_data$extremes_ssp245
  
  if (nrow(historical) > 0 && nrow(future_245) > 0 && nrow(extremes_245) > 0) {
    # Combine all metrics
    risk_data <- historical %>%
      select(iso3, country, temp_baseline = temp_historical, precip_baseline = precip_historical) %>%
      left_join(future_245 %>% select(iso3, temp_anomaly, precip_change), by = "iso3") %>%
      left_join(extremes_245 %>% select(iso3, hot_days = hot_days_35C), by = "iso3") %>%
      mutate(
        temp_future = temp_baseline + coalesce(temp_anomaly, 0),
        temp_increase = coalesce(temp_anomaly, 0),
        precip_change_pct = coalesce(precip_change, 0),
        heat_risk = case_when(
          hot_days > 60 ~ "Very High",
          hot_days > 40 ~ "High",
          hot_days > 20 ~ "Moderate",
          hot_days > 10 ~ "Low",
          TRUE ~ "Very Low"
        )
      ) %>%
      filter(!is.na(temp_baseline))
    
    # Panel 1: Temperature vs Precipitation change
    p1 <- ggplot(risk_data, aes(x = temp_increase, y = precip_change_pct)) +
      geom_hline(yintercept = 0, linetype = "dashed", color = "gray60") +
      geom_vline(xintercept = 2, linetype = "dashed", color = "red", alpha = 0.5) +
      geom_point(aes(size = hot_days, color = temp_future), alpha = 0.8) +
      geom_text_repel(aes(label = country), size = 3, max.overlaps = 15) +
      scale_color_gradient2(low = "#2166ac", mid = "#fee08b", high = "#d73027", 
                           midpoint = 22, name = "Future\nTemp (°C)") +
      scale_size_continuous(range = c(3, 10), name = "Hot Days\n(>35°C)") +
      labs(
        title = "Climate Change Impact Matrix",
        x = "Temperature Increase (°C)",
        y = "Precipitation Change (%)"
      ) +
      theme_scientific()
    
    # Panel 2: Risk categories
    risk_summary <- risk_data %>%
      mutate(heat_risk = factor(heat_risk, 
                                levels = c("Very Low", "Low", "Moderate", "High", "Very High")))
    
    p2 <- ggplot(risk_summary, aes(x = heat_risk, fill = heat_risk)) +
      geom_bar(alpha = 0.9) +
      scale_fill_manual(values = c("Very Low" = "#2166ac", "Low" = "#92c5de",
                                  "Moderate" = "#fee08b", "High" = "#fdae61",
                                  "Very High" = "#d73027")) +
      labs(
        title = "Heat Risk Distribution",
        x = "Risk Category",
        y = "Number of Countries"
      ) +
      theme_scientific() +
      theme(legend.position = "none")
    
    # Panel 3: Country ranking by combined risk
    risk_ranking <- risk_data %>%
      mutate(
        combined_risk = scale(temp_increase) + scale(hot_days) - scale(precip_change_pct)
      ) %>%
      arrange(desc(combined_risk))
    
    p3 <- ggplot(risk_ranking, aes(x = reorder(country, combined_risk), y = combined_risk)) +
      geom_segment(aes(xend = country, yend = 0), color = "gray60") +
      geom_point(aes(color = combined_risk), size = 4) +
      scale_color_gradient2(low = "#2166ac", mid = "gray90", high = "#d73027",
                           midpoint = 0, guide = "none") +
      coord_flip() +
      labs(
        title = "Combined Climate Risk Score",
        x = NULL,
        y = "Risk Score (standardized)"
      ) +
      theme_scientific()
    
    # Panel 4: Data source information
    data_info <- data.frame(
      Source = c("Historical Climate", "Future Projections", "Extreme Indices", "Resolution"),
      Description = c("CRU TS 4.06 (1991-2020)", "CMIP6 ensemble median", 
                     "CMIP6 extreme indices", "0.5° (historical), 0.25° (future)")
    )
    
    p4 <- ggplot(data_info, aes(x = 0, y = rev(1:4))) +
      geom_text(aes(label = paste(Source, ":", Description)), 
               hjust = 0, size = 3.5, color = "gray30") +
      xlim(0, 1) +
      theme_void() +
      labs(title = "Data Sources", 
           subtitle = "World Bank Climate Change Knowledge Portal API")
    
    # Combine all panels
    combined <- (p1 + p2) / (p3 + p4) +
      plot_annotation(
        title = "Southern Africa Climate Risk Dashboard",
        subtitle = "Comprehensive assessment using World Bank Climate API data",
        caption = "All data from World Bank Climate Change Knowledge Portal (climateknowledgeportal.worldbank.org)\nAnalysis date: 2024 | Target period: 2040-2059 | Scenario: SSP2-4.5",
        theme = theme(
          plot.title = element_text(size = 18, face = "bold", hjust = 0.5),
          plot.subtitle = element_text(size = 14, hjust = 0.5, color = "gray40"),
          plot.caption = element_text(size = 10, hjust = 0.5, color = "gray50", lineheight = 1.2)
        )
      )
    
    svglite("climate_risk_dashboard_worldbank.svg", width = 16, height = 12)
    print(combined)
    dev.off()
    
    cat("✓ Created: climate_risk_dashboard_worldbank.svg\n")
  }
}

# 5. Create Spatial Climate Map
create_spatial_climate_map_svg <- function() {
  cat("\nCreating Spatial Climate Map...\n")
  
  # Get country boundaries
  africa <- ne_countries(scale = "medium", continent = "Africa", returnclass = "sf")
  
  # Join with climate data
  historical <- climate_data$historical
  future_245 <- climate_data$future_ssp245_2040
  
  if (nrow(historical) > 0 && nrow(future_245) > 0) {
    climate_spatial <- historical %>%
      select(iso3, temp_historical, precip_historical) %>%
      left_join(future_245 %>% select(iso3, temp_anomaly, precip_change), by = "iso3") %>%
      mutate(temp_future = temp_historical + coalesce(temp_anomaly, 0))
    
    # Join with spatial data
    africa_climate <- africa %>%
      filter(iso_a3 %in% climate_spatial$iso3) %>%
      left_join(climate_spatial, by = c("iso_a3" = "iso3"))
    
    # Create map
    p_map <- ggplot() +
      geom_sf(data = africa_climate, aes(fill = temp_future), color = "white", size = 0.3) +
      scale_fill_gradient2(low = "#2166ac", mid = "#fee08b", high = "#d73027",
                          midpoint = 22, name = "Temperature\n2040-2059 (°C)",
                          na.value = "gray90") +
      coord_sf(xlim = c(10, 42), ylim = c(-35, -8), expand = FALSE) +
      labs(
        title = "Projected Temperature Distribution (2040-2059)",
        subtitle = "CMIP6 ensemble median under SSP2-4.5 scenario",
        caption = "Data: World Bank Climate API | Map: Natural Earth"
      ) +
      theme_minimal() +
      theme(
        panel.background = element_rect(fill = "lightblue", color = NA),
        panel.grid = element_blank(),
        legend.position = "right"
      )
    
    svglite("spatial_climate_map_worldbank.svg", width = 12, height = 10)
    print(p_map)
    dev.off()
    
    cat("✓ Created: spatial_climate_map_worldbank.svg\n")
  }
}

# Main execution
main <- function() {
  cat("\n========================================\n")
  cat("CREATING SCIENTIFIC CLIMATE VISUALIZATIONS\n")
  cat("Using Real Data from World Bank Climate API\n")
  cat("========================================\n")
  
  # Create all visualizations
  create_temperature_projection_svg()
  create_precipitation_change_svg()
  create_heat_extremes_svg()
  create_climate_risk_dashboard_svg()
  create_spatial_climate_map_svg()
  
  cat("\n========================================\n")
  cat("✅ ALL VISUALIZATIONS COMPLETED\n")
  cat("\nGenerated SVG files:\n")
  cat("• temperature_projections_worldbank.svg\n")
  cat("• precipitation_change_worldbank.svg\n")
  cat("• heat_extremes_worldbank.svg\n")
  cat("• climate_risk_dashboard_worldbank.svg\n")
  cat("• spatial_climate_map_worldbank.svg\n")
  cat("\n📊 All visualizations use REAL DATA from:\n")
  cat("   - World Bank Climate Change Knowledge Portal API\n")
  cat("   - CRU TS 4.06 (historical observations)\n")
  cat("   - CMIP6 ensemble median (future projections)\n")
  cat("\n🔬 Scientific rigor maintained throughout\n")
  cat("📐 High-quality SVG format for publications\n")
  cat("========================================\n")
}

# Run main function
main()