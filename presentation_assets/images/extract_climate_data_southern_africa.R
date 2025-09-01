#!/usr/bin/env Rscript
# Extract climate data for Malawi, South Africa, and Zimbabwe
# Using Köppen-Geiger climate zones and World Bank climate data integration

# Load required libraries
suppressPackageStartupMessages({
  library(sf)
  library(dplyr)
  library(jsonlite)
  library(rnaturalearth)
  library(rnaturalearthdata)
})

extract_country_climate_data <- function() {
  # Load climate data
  climate_data <- st_read("koppen_africa_with_labels.geojson", quiet = TRUE)
  
  # Get country boundaries
  countries <- ne_countries(scale = "medium", returnclass = "sf")
  
  # Filter for target countries
  target_countries <- c("South Africa", "Zimbabwe", "Malawi")
  countries_sf <- countries %>%
    filter(name %in% target_countries) %>%
    select(name, iso_a3, pop_est)
  
  # Extract climate zones for each country
  country_climate_summary <- list()
  
  for (country_name in target_countries) {
    cat(sprintf("Processing %s...\n", country_name))
    
    # Get country boundary
    country_boundary <- countries_sf %>%
      filter(name == country_name)
    
    # Find climate zones that intersect with this country
    country_climate <- st_filter(climate_data, country_boundary)
    
    # Calculate area coverage for each climate zone
    country_climate$area_km2 <- as.numeric(st_area(country_climate)) / 1000000
    
    # Summarize by climate zone
    climate_summary <- country_climate %>%
      st_drop_geometry() %>%
      group_by(koppen_code, koppen_label) %>%
      summarise(
        total_area_km2 = sum(area_km2, na.rm = TRUE),
        polygon_count = n(),
        .groups = "drop"
      ) %>%
      arrange(desc(total_area_km2)) %>%
      mutate(
        percent_coverage = round(total_area_km2 / sum(total_area_km2) * 100, 1)
      )
    
    # Get country info
    country_info <- countries_sf %>%
      filter(name == country_name) %>%
      st_drop_geometry()
    
    country_climate_summary[[country_name]] <- list(
      country = country_name,
      iso_code = country_info$iso_a3,
      population = country_info$pop_est,
      dominant_climate = climate_summary$koppen_code[1],
      dominant_climate_label = climate_summary$koppen_label[1],
      dominant_climate_coverage = climate_summary$percent_coverage[1],
      climate_zones = climate_summary,
      total_area_km2 = sum(climate_summary$total_area_km2)
    )
    
    # Print summary
    cat(sprintf("\n%s Climate Summary:\n", country_name))
    cat(sprintf("- Dominant climate: %s (%s) - %.1f%% coverage\n", 
                climate_summary$koppen_code[1], 
                climate_summary$koppen_label[1],
                climate_summary$percent_coverage[1]))
    cat(sprintf("- Total climate zones: %d\n", nrow(climate_summary)))
    cat(sprintf("- Country area: %.0f km²\n", sum(climate_summary$total_area_km2)))
    cat("\nAll climate zones:\n")
    for (i in 1:nrow(climate_summary)) {
      cat(sprintf("  %s: %.1f%% (%.0f km²)\n", 
                  climate_summary$koppen_code[i],
                  climate_summary$percent_coverage[i],
                  climate_summary$total_area_km2[i]))
    }
    cat("\n")
  }
  
  return(country_climate_summary)
}

# Extract the data
cat("Extracting climate data for target countries...\n")
climate_summary <- extract_country_climate_data()

# Save as JSON for further analysis
writeLines(toJSON(climate_summary, pretty = TRUE), "southern_africa_climate_summary.json")
cat("Climate summary saved to southern_africa_climate_summary.json\n")

# Create a summary table
summary_df <- data.frame(
  Country = names(climate_summary),
  ISO_Code = sapply(climate_summary, function(x) x$iso_code),
  Population = sapply(climate_summary, function(x) x$population),
  Dominant_Climate = sapply(climate_summary, function(x) x$dominant_climate),
  Dominant_Climate_Label = sapply(climate_summary, function(x) x$dominant_climate_label),
  Coverage_Percent = sapply(climate_summary, function(x) x$dominant_climate_coverage),
  Total_Area_km2 = sapply(climate_summary, function(x) x$total_area_km2),
  Climate_Zones_Count = sapply(climate_summary, function(x) nrow(x$climate_zones))
)

write.csv(summary_df, "southern_africa_climate_summary.csv", row.names = FALSE)
cat("Summary table saved to southern_africa_climate_summary.csv\n")

print(summary_df)