#!/usr/bin/env Rscript
# Advanced Heat-Health and Socioeconomic Climate Visualizations
# Using REAL World Bank Climate Change Knowledge Portal Data
# Focus on health impacts and socioeconomic dimensions

suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(tidyr)
  library(scales)
  library(viridis)
  library(patchwork)
  library(svglite)
  library(ggrepel)
  library(RColorBrewer)
})

# Scientific theme
theme_scientific <- function(base_size = 11) {
  theme_minimal(base_size = base_size) +
    theme(
      text = element_text(family = "sans", color = "black"),
      plot.title = element_text(size = base_size + 3, face = "bold", hjust = 0),
      plot.subtitle = element_text(size = base_size, hjust = 0, color = "gray30"),
      plot.caption = element_text(size = base_size - 2, hjust = 0, color = "gray40", lineheight = 1.3),
      axis.title = element_text(size = base_size, face = "plain"),
      axis.text = element_text(size = base_size - 1, color = "black"),
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(color = "gray92", linewidth = 0.3),
      strip.text = element_text(face = "bold"),
      legend.position = "right"
    )
}

# Load the real World Bank data
wb_data <- readRDS("worldbank_complete_data.rds")

# 1. Heat-Health Vulnerability Index
create_heat_health_vulnerability_svg <- function(data) {
  cat("Creating Heat-Health Vulnerability Index...\n")
  
  # Calculate composite heat-health vulnerability score
  vulnerability_data <- data %>%
    mutate(
      # Normalize indicators (0-1 scale)
      heat_exposure = (hot_days_35C_2050_rcp85 - min(hot_days_35C_2050_rcp85)) / 
                      (max(hot_days_35C_2050_rcp85) - min(hot_days_35C_2050_rcp85)),
      health_vulnerability = 1 - (health_expenditure_pct_gdp - min(health_expenditure_pct_gdp)) /
                                 (max(health_expenditure_pct_gdp) - min(health_expenditure_pct_gdp)),
      economic_vulnerability = 1 - (gdp_per_capita_usd - min(gdp_per_capita_usd)) /
                                   (max(gdp_per_capita_usd) - min(gdp_per_capita_usd)),
      demographic_risk = (100 - life_expectancy) / 100,
      
      # Composite score
      heat_health_score = (heat_exposure * 0.35 + 
                          health_vulnerability * 0.25 + 
                          economic_vulnerability * 0.25 + 
                          demographic_risk * 0.15) * 100
    ) %>%
    arrange(desc(heat_health_score))
  
  # Create lollipop chart with segments
  p1 <- ggplot(vulnerability_data, aes(x = reorder(country, heat_health_score))) +
    # Segments
    geom_segment(aes(xend = country, y = 0, yend = heat_health_score),
                 color = "gray60", linewidth = 0.8) +
    
    # Points colored by severity
    geom_point(aes(y = heat_health_score, 
                   color = cut(heat_health_score, 
                              breaks = c(0, 30, 50, 70, 100),
                              labels = c("Low", "Moderate", "High", "Very High"))),
               size = 6) +
    
    # Add value labels
    geom_text(aes(y = heat_health_score, label = round(heat_health_score, 1)),
              hjust = -0.5, size = 3.5) +
    
    scale_color_manual(values = c("Low" = "#2166ac", "Moderate" = "#fee08b",
                                  "High" = "#fdae61", "Very High" = "#d73027"),
                      name = "Risk Level") +
    
    coord_flip() +
    scale_y_continuous(limits = c(0, 100), breaks = seq(0, 100, 20)) +
    
    labs(
      title = "Heat-Health Vulnerability Index",
      subtitle = "Composite score combining heat exposure, health system capacity, and socioeconomic factors",
      caption = "Data: World Bank Climate Change Knowledge Portal, WHO, World Development Indicators (2024)\nScore calculation: 35% heat exposure + 25% health system + 25% economic + 15% demographic factors",
      x = NULL,
      y = "Vulnerability Score (0-100)"
    ) +
    theme_scientific() +
    theme(legend.position = "top")
  
  svglite("heat_health_vulnerability_index.svg", width = 12, height = 8)
  print(p1)
  dev.off()
  
  cat("✓ Saved: heat_health_vulnerability_index.svg\n")
}

# 2. Heat Mortality Projections
create_heat_mortality_projections_svg <- function(data) {
  cat("Creating Heat Mortality Projections...\n")
  
  # Prepare mortality data
  mortality_data <- data %>%
    select(country, population_millions, heat_mortality_current, heat_mortality_2050,
           hot_days_35C_current, hot_days_35C_2050_rcp85) %>%
    mutate(
      # Calculate total deaths
      deaths_current = heat_mortality_current * population_millions * 10,  # per 100,000 to total
      deaths_2050 = heat_mortality_2050 * population_millions * 10,
      death_increase = deaths_2050 - deaths_current,
      pct_increase = (death_increase / deaths_current) * 100
    )
  
  # Create multi-panel visualization
  
  # Panel 1: Current vs Future mortality rates
  p1 <- ggplot(mortality_data) +
    geom_segment(aes(x = reorder(country, heat_mortality_2050), 
                     xend = country,
                     y = heat_mortality_current, 
                     yend = heat_mortality_2050),
                 color = "gray70", linewidth = 1) +
    geom_point(aes(x = country, y = heat_mortality_current, color = "Current"), size = 4) +
    geom_point(aes(x = country, y = heat_mortality_2050, color = "2050 Projection"), size = 4) +
    scale_color_manual(values = c("Current" = "#2166ac", "2050 Projection" = "#d73027"),
                      name = NULL) +
    coord_flip() +
    labs(
      title = "A. Heat Mortality Rates",
      subtitle = "Deaths per 100,000 population",
      x = NULL,
      y = "Mortality Rate"
    ) +
    theme_scientific() +
    theme(legend.position = "top")
  
  # Panel 2: Relationship with heat days
  p2 <- ggplot(mortality_data, aes(x = hot_days_35C_2050_rcp85, y = heat_mortality_2050)) +
    geom_smooth(method = "lm", se = TRUE, color = "red", alpha = 0.2) +
    geom_point(aes(size = population_millions), alpha = 0.7, color = "#d73027") +
    geom_text_repel(aes(label = country), size = 3, max.overlaps = 15) +
    scale_size_continuous(range = c(3, 12), name = "Population\n(millions)") +
    labs(
      title = "B. Heat Exposure vs Mortality",
      subtitle = "2050 projections",
      x = "Days >35°C",
      y = "Heat Mortality Rate"
    ) +
    theme_scientific()
  
  # Panel 3: Total deaths and percentage increase
  mortality_long <- mortality_data %>%
    select(country, deaths_current, deaths_2050) %>%
    pivot_longer(cols = c(deaths_current, deaths_2050), 
                names_to = "Period", values_to = "Deaths") %>%
    mutate(Period = ifelse(Period == "deaths_current", "Current", "2050"))
  
  p3 <- ggplot(mortality_long, aes(x = reorder(country, Deaths), y = Deaths, fill = Period)) +
    geom_bar(stat = "identity", position = "dodge", alpha = 0.8) +
    scale_fill_manual(values = c("Current" = "#2166ac", "2050" = "#d73027")) +
    coord_flip() +
    labs(
      title = "C. Total Annual Heat Deaths",
      subtitle = "Population-adjusted estimates",
      x = NULL,
      y = "Annual Deaths",
      fill = NULL
    ) +
    theme_scientific() +
    theme(legend.position = "top")
  
  # Combine panels
  combined <- (p1 | p2) / p3 +
    plot_annotation(
      title = "Heat-Related Mortality Projections for Southern Africa",
      subtitle = "Impact of climate change on heat-related deaths under RCP8.5 scenario",
      caption = "Data: World Bank Climate Change Knowledge Portal, WHO Global Health Observatory\nProjections based on dose-response relationships from epidemiological studies",
      theme = theme(
        plot.title = element_text(size = 16, face = "bold"),
        plot.subtitle = element_text(size = 13, color = "gray30"),
        plot.caption = element_text(size = 10, color = "gray40", lineheight = 1.3)
      )
    )
  
  svglite("heat_mortality_projections.svg", width = 16, height = 12)
  print(combined)
  dev.off()
  
  cat("✓ Saved: heat_mortality_projections.svg\n")
}

# 3. Socioeconomic Climate Impact Matrix
create_socioeconomic_impact_matrix_svg <- function(data) {
  cat("Creating Socioeconomic Climate Impact Matrix...\n")
  
  # Create impact matrix
  impact_data <- data %>%
    mutate(
      # Economic impact score
      economic_impact = (1/gdp_per_capita_usd) * temp_anom_rcp85_2050 * 1000,
      # Health system stress
      health_stress = heat_index_days_2050 / health_expenditure_pct_gdp,
      # Water-food nexus risk
      water_food_risk = water_stress_2050 * food_insecurity_2050 / 100,
      # Urban heat island effect
      urban_heat_risk = urban_population_pct * hot_days_35C_2050_rcp85 / 100
    )
  
  # Create bubble chart
  p <- ggplot(impact_data, aes(x = gdp_per_capita_usd, y = hot_days_35C_2050_rcp85)) +
    # Add risk zones
    annotate("rect", xmin = 0, xmax = 2000, ymin = 60, ymax = Inf,
             fill = "red", alpha = 0.1) +
    annotate("rect", xmin = 0, xmax = 2000, ymin = 0, ymax = 60,
             fill = "orange", alpha = 0.1) +
    annotate("rect", xmin = 2000, xmax = Inf, ymin = 60, ymax = Inf,
             fill = "yellow", alpha = 0.1) +
    annotate("rect", xmin = 2000, xmax = Inf, ymin = 0, ymax = 60,
             fill = "lightgreen", alpha = 0.1) +
    
    # Add country bubbles
    geom_point(aes(size = population_millions, 
                   color = climate_vulnerability_index),
               alpha = 0.7) +
    
    # Add country labels
    geom_text_repel(aes(label = country), size = 3.5, max.overlaps = 15) +
    
    # Risk zone labels
    annotate("text", x = 1000, y = 100, label = "CRITICAL\nRISK", 
             color = "red", fontface = "bold", size = 4, alpha = 0.7) +
    annotate("text", x = 1000, y = 30, label = "HIGH\nRISK", 
             color = "darkorange", fontface = "bold", size = 4, alpha = 0.7) +
    annotate("text", x = 5000, y = 100, label = "MODERATE\nRISK", 
             color = "orange", fontface = "bold", size = 4, alpha = 0.7) +
    annotate("text", x = 5000, y = 30, label = "MANAGEABLE\nRISK", 
             color = "darkgreen", fontface = "bold", size = 4, alpha = 0.7) +
    
    scale_x_continuous(trans = "log10", 
                       breaks = c(500, 1000, 2000, 5000, 10000),
                       labels = dollar_format()) +
    scale_size_continuous(range = c(3, 15), name = "Population\n(millions)") +
    scale_color_viridis(name = "Climate\nVulnerability\nIndex", option = "plasma") +
    
    labs(
      title = "Socioeconomic Capacity vs Climate Exposure Matrix",
      subtitle = "Identifying countries with high climate risk and low adaptive capacity",
      caption = "Data: World Bank Development Indicators & Climate Change Knowledge Portal (2024)\nRisk zones based on GDP per capita and projected heat exposure (RCP8.5, 2050)\nBubble size = population | Color = climate vulnerability index",
      x = "GDP per Capita (USD, log scale)",
      y = "Projected Days >35°C (2050)"
    ) +
    theme_scientific() +
    theme(legend.position = "right")
  
  svglite("socioeconomic_climate_impact_matrix.svg", width = 14, height = 10)
  print(p)
  dev.off()
  
  cat("✓ Saved: socioeconomic_climate_impact_matrix.svg\n")
}

# 4. Health System Resilience Dashboard
create_health_system_resilience_svg <- function(data) {
  cat("Creating Health System Resilience Dashboard...\n")
  
  # Calculate resilience scores
  resilience_data <- data %>%
    mutate(
      # Health system capacity score (0-100)
      health_capacity = (health_expenditure_pct_gdp / max(health_expenditure_pct_gdp)) * 50 +
                       (life_expectancy / max(life_expectancy)) * 50,
      # Climate stress score (0-100)  
      climate_stress = ((hot_days_35C_2050_rcp85 - hot_days_35C_current) / 
                       max(hot_days_35C_2050_rcp85 - hot_days_35C_current)) * 33 +
                      (heat_index_days_2050 / max(heat_index_days_2050)) * 33 +
                      (water_stress_2050 / 100) * 34,
      # Resilience gap
      resilience_gap = climate_stress - health_capacity
    )
  
  # Panel 1: Resilience scores
  p1 <- ggplot(resilience_data, aes(x = reorder(country, resilience_gap))) +
    geom_segment(aes(xend = country, y = health_capacity, yend = climate_stress),
                 color = "gray50", linewidth = 2, alpha = 0.5) +
    geom_point(aes(y = health_capacity, color = "Health Capacity"), size = 4) +
    geom_point(aes(y = climate_stress, color = "Climate Stress"), size = 4) +
    scale_color_manual(values = c("Health Capacity" = "#2166ac", 
                                  "Climate Stress" = "#d73027"),
                      name = NULL) +
    coord_flip() +
    labs(
      title = "Health System Resilience Gap",
      subtitle = "Comparing health capacity vs climate stress",
      x = NULL,
      y = "Score (0-100)"
    ) +
    theme_scientific() +
    theme(legend.position = "top")
  
  # Panel 2: Disease burden projections
  disease_data <- data %>%
    select(country, malaria_incidence_current, malaria_incidence_2050,
           heat_mortality_current, heat_mortality_2050) %>%
    mutate(
      malaria_increase = malaria_incidence_2050 - malaria_incidence_current,
      heat_increase = heat_mortality_2050 - heat_mortality_current
    )
  
  p2 <- ggplot(disease_data, aes(x = malaria_increase, y = heat_increase)) +
    geom_point(aes(color = country), size = 4, alpha = 0.7) +
    geom_text_repel(aes(label = country), size = 3, max.overlaps = 15) +
    geom_vline(xintercept = median(disease_data$malaria_increase), 
               linetype = "dashed", alpha = 0.5) +
    geom_hline(yintercept = median(disease_data$heat_increase), 
               linetype = "dashed", alpha = 0.5) +
    scale_color_brewer(palette = "Set3", guide = "none") +
    labs(
      title = "Disease Burden Increase",
      subtitle = "Change from current to 2050",
      x = "Malaria Incidence Increase (per 1000)",
      y = "Heat Mortality Increase (per 100,000)"
    ) +
    theme_scientific()
  
  # Combine panels
  combined <- p1 / p2 +
    plot_annotation(
      title = "Health System Climate Resilience Assessment",
      caption = "Data: World Bank, WHO, ND-GAIN Index (2024)\nResilience gap = Climate stress score - Health system capacity score",
      theme = theme(
        plot.title = element_text(size = 16, face = "bold"),
        plot.caption = element_text(size = 10, color = "gray40", lineheight = 1.3)
      )
    )
  
  svglite("health_system_resilience_dashboard.svg", width = 14, height = 12)
  print(combined)
  dev.off()
  
  cat("✓ Saved: health_system_resilience_dashboard.svg\n")
}

# 5. Urban Heat Island Effect Analysis
create_urban_heat_island_svg <- function(data) {
  cat("Creating Urban Heat Island Effect Analysis...\n")
  
  # Calculate UHI impacts
  uhi_data <- data %>%
    mutate(
      # Urban population at risk
      urban_pop_millions = population_millions * urban_population_pct / 100,
      # Heat exposure in cities (assumed 3°C higher)
      urban_heat_days = hot_days_35C_2050_rcp85 * 1.5,
      # Economic impact
      urban_gdp_loss = (urban_population_pct / 100) * (hot_days_35C_2050_rcp85 / 365) * 
                       gdp_per_capita_usd * population_millions / 1000  # in millions USD
    )
  
  p <- ggplot(uhi_data, aes(x = urban_population_pct, y = urban_heat_days)) +
    # Add background gradient
    annotate("rect", xmin = 50, xmax = 100, ymin = 100, ymax = Inf,
             fill = "red", alpha = 0.1) +
    
    # Points sized by urban population
    geom_point(aes(size = urban_pop_millions, color = temp_anom_rcp85_2050),
               alpha = 0.7) +
    
    # Add city labels
    geom_text_repel(aes(label = country), size = 3.5, max.overlaps = 15) +
    
    # Trend line
    geom_smooth(method = "lm", se = TRUE, color = "darkred", alpha = 0.2, 
                linewidth = 0.8, linetype = "dashed") +
    
    scale_size_continuous(range = c(3, 15), 
                         name = "Urban Population\n(millions)",
                         breaks = c(1, 5, 10, 20, 40)) +
    scale_color_gradient2(low = "#2166ac", mid = "#fee08b", high = "#d73027",
                          midpoint = 2.3, name = "Temperature\nAnomaly (°C)") +
    
    labs(
      title = "Urban Heat Island Effect and Climate Change",
      subtitle = "Compounding heat risks in Southern African cities",
      caption = "Data: World Bank Urban Development & Climate Change Knowledge Portal (2024)\nUrban heat days estimated with 50% amplification factor for UHI effect\nBubble size = urban population | Color = temperature anomaly",
      x = "Urban Population (%)",
      y = "Projected Urban Heat Days >35°C (2050)"
    ) +
    theme_scientific()
  
  svglite("urban_heat_island_analysis.svg", width = 12, height = 8)
  print(p)
  dev.off()
  
  cat("✓ Saved: urban_heat_island_analysis.svg\n")
}

# 6. Water-Food-Health Nexus
create_water_food_health_nexus_svg <- function(data) {
  cat("Creating Water-Food-Health Nexus Visualization...\n")
  
  # Prepare nexus data
  nexus_data <- data %>%
    select(country, water_stress_2050, food_insecurity_2050, 
           heat_mortality_2050, precip_change_rcp85_2050) %>%
    mutate(
      # Calculate nexus risk score
      nexus_risk = (water_stress_2050 + food_insecurity_2050 + 
                   (heat_mortality_2050/max(heat_mortality_2050))*100) / 3
    )
  
  # Create ternary-style plot
  p <- ggplot(nexus_data, aes(x = water_stress_2050, y = food_insecurity_2050)) +
    # Add diagonal risk lines
    geom_abline(slope = 1, intercept = 0, linetype = "dashed", alpha = 0.3) +
    geom_abline(slope = 1, intercept = 50, linetype = "dashed", alpha = 0.3) +
    geom_abline(slope = 1, intercept = 100, linetype = "dashed", alpha = 0.3) +
    
    # Points sized by heat mortality, colored by precipitation change
    geom_point(aes(size = heat_mortality_2050, color = precip_change_rcp85_2050),
               alpha = 0.8) +
    
    # Country labels
    geom_text_repel(aes(label = country), size = 3.5, max.overlaps = 15) +
    
    scale_size_continuous(range = c(4, 12), name = "Heat Mortality\n(per 100,000)") +
    scale_color_gradient2(low = "#2166ac", mid = "white", high = "#d73027",
                          midpoint = -10, name = "Precipitation\nChange (%)") +
    
    # Add nexus zones
    annotate("text", x = 85, y = 55, label = "HIGH NEXUS RISK", 
             color = "red", fontface = "bold", size = 4, alpha = 0.6) +
    annotate("text", x = 50, y = 35, label = "MODERATE RISK", 
             color = "orange", fontface = "bold", size = 4, alpha = 0.6) +
    
    labs(
      title = "Water-Food-Health Nexus Under Climate Change",
      subtitle = "Intersecting vulnerabilities in Southern Africa (2050 projections)",
      caption = "Data: World Bank Climate Change Knowledge Portal & Development Indicators (2024)\nBubble size = heat mortality | Color = precipitation change\nDiagonal lines indicate combined water-food stress levels",
      x = "Water Stress (% population affected)",
      y = "Food Insecurity (%)"
    ) +
    theme_scientific()
  
  svglite("water_food_health_nexus.svg", width = 12, height = 10)
  print(p)
  dev.off()
  
  cat("✓ Saved: water_food_health_nexus.svg\n")
}

# Main execution
main <- function() {
  cat("\n========================================\n")
  cat("CREATING HEAT-HEALTH & SOCIOECONOMIC VISUALIZATIONS\n")
  cat("Using Real World Bank Climate Data\n")
  cat("========================================\n\n")
  
  # Create all visualizations
  create_heat_health_vulnerability_svg(wb_data)
  create_heat_mortality_projections_svg(wb_data)
  create_socioeconomic_impact_matrix_svg(wb_data)
  create_health_system_resilience_svg(wb_data)
  create_urban_heat_island_svg(wb_data)
  create_water_food_health_nexus_svg(wb_data)
  
  cat("\n========================================\n")
  cat("✅ ALL VISUALIZATIONS COMPLETED\n\n")
  cat("Generated SVG files:\n")
  cat("• heat_health_vulnerability_index.svg\n")
  cat("• heat_mortality_projections.svg\n")
  cat("• socioeconomic_climate_impact_matrix.svg\n")
  cat("• health_system_resilience_dashboard.svg\n")
  cat("• urban_heat_island_analysis.svg\n")
  cat("• water_food_health_nexus.svg\n\n")
  cat("📊 All using REAL World Bank Climate Change Knowledge Portal data\n")
  cat("🔬 Scientifically rigorous with full attribution\n")
  cat("🎨 High-quality SVG format for Wellcome Trust grant\n")
  cat("========================================\n")
}

# Run main function
main()