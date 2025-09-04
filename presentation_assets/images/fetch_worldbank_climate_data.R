#!/usr/bin/env Rscript
# Fetch Real Climate Data from World Bank Climate API
# For scientifically rigorous visualizations
# All data properly sourced and documented

# Load required libraries
suppressPackageStartupMessages({
  library(httr)
  library(jsonlite)
  library(dplyr)
  library(tidyr)
  library(ggplot2)
  library(sf)
  library(rnaturalearth)
  library(rnaturalearthdata)
  library(scales)
  library(viridis)
  library(patchwork)
  library(svglite)
})

# World Bank Climate API base URL
BASE_URL <- "https://cckpapi.worldbank.org/cckp/v1"

# Target countries for Wellcome Grant
TARGET_COUNTRIES <- list(
  "ZAF" = "South Africa",
  "ZWE" = "Zimbabwe", 
  "MWI" = "Malawi",
  "BWA" = "Botswana",
  "NAM" = "Namibia",
  "ZMB" = "Zambia",
  "MOZ" = "Mozambique",
  "AGO" = "Angola",
  "LSO" = "Lesotho",
  "SWZ" = "Eswatini"
)

# Function to fetch data from World Bank API
fetch_climate_data <- function(endpoint, format = "json") {
  url <- paste0(endpoint, "?_format=", format)
  cat("Fetching:", url, "\n")
  
  tryCatch({
    response <- GET(url, timeout(30))
    
    if (status_code(response) == 200) {
      data <- content(response, "parsed", encoding = "UTF-8")
      return(data)
    } else {
      cat("Error: HTTP", status_code(response), "\n")
      return(NULL)
    }
  }, error = function(e) {
    cat("Error fetching data:", e$message, "\n")
    return(NULL)
  })
}

# Fetch historical temperature data for all countries
fetch_temperature_data <- function() {
  cat("=== Fetching Historical Temperature Data (CRU TS 1991-2020) ===\n")
  
  temp_data <- data.frame()
  
  for (code in names(TARGET_COUNTRIES)) {
    cat(sprintf("Fetching data for %s (%s)...\n", TARGET_COUNTRIES[[code]], code))
    
    # Historical temperature endpoint (CRU TS dataset, 0.5° resolution)
    endpoint <- sprintf("%s/cru-x0.5_climatology_tas_climatology_annual_1991-2020_mean_historical_mean/all/%s",
                       BASE_URL, code)
    
    data <- fetch_climate_data(endpoint)
    
    if (!is.null(data) && !is.null(data$data)) {
      # Extract temperature value
      if (length(data$data) > 0 && !is.null(data$data[[1]]$value)) {
        temp_value <- data$data[[1]]$value
        
        temp_data <- rbind(temp_data, data.frame(
          iso3 = code,
          country = TARGET_COUNTRIES[[code]],
          temp_historical = temp_value,
          data_source = "CRU TS 4.06",
          period = "1991-2020",
          stringsAsFactors = FALSE
        ))
      }
    }
    
    Sys.sleep(1)  # Be nice to the API
  }
  
  return(temp_data)
}

# Fetch precipitation data
fetch_precipitation_data <- function() {
  cat("\n=== Fetching Historical Precipitation Data (CRU TS 1991-2020) ===\n")
  
  precip_data <- data.frame()
  
  for (code in names(TARGET_COUNTRIES)) {
    cat(sprintf("Fetching precipitation for %s...\n", TARGET_COUNTRIES[[code]]))
    
    # Historical precipitation endpoint
    endpoint <- sprintf("%s/cru-x0.5_climatology_pr_climatology_annual_1991-2020_mean_historical_mean/all/%s",
                       BASE_URL, code)
    
    data <- fetch_climate_data(endpoint)
    
    if (!is.null(data) && !is.null(data$data)) {
      if (length(data$data) > 0 && !is.null(data$data[[1]]$value)) {
        precip_value <- data$data[[1]]$value
        
        precip_data <- rbind(precip_data, data.frame(
          iso3 = code,
          country = TARGET_COUNTRIES[[code]],
          precip_historical = precip_value,
          data_source = "CRU TS 4.06",
          period = "1991-2020",
          stringsAsFactors = FALSE
        ))
      }
    }
    
    Sys.sleep(1)
  }
  
  return(precip_data)
}

# Fetch future projections (CMIP6)
fetch_future_projections <- function(scenario = "ssp245", period = "2040-2059") {
  cat(sprintf("\n=== Fetching CMIP6 Projections (%s, %s) ===\n", scenario, period))
  
  future_data <- data.frame()
  
  for (code in names(TARGET_COUNTRIES)) {
    cat(sprintf("Fetching %s projections for %s...\n", scenario, TARGET_COUNTRIES[[code]]))
    
    # CMIP6 temperature anomaly endpoint (0.25° resolution)
    temp_endpoint <- sprintf("%s/cmip6-x0.25_climatology_tas_anomaly_annual_%s_median_%s_ensemble_all_mean/%s",
                            BASE_URL, period, scenario, code)
    
    temp_data <- fetch_climate_data(temp_endpoint)
    
    # CMIP6 precipitation change endpoint
    precip_endpoint <- sprintf("%s/cmip6-x0.25_climatology_pr_anomaly_annual_%s_median_%s_ensemble_all_mean/%s",
                              BASE_URL, period, scenario, code)
    
    precip_data <- fetch_climate_data(precip_endpoint)
    
    temp_anomaly <- NA
    precip_change <- NA
    
    if (!is.null(temp_data) && !is.null(temp_data$data)) {
      if (length(temp_data$data) > 0 && !is.null(temp_data$data[[1]]$value)) {
        temp_anomaly <- temp_data$data[[1]]$value
      }
    }
    
    if (!is.null(precip_data) && !is.null(precip_data$data)) {
      if (length(precip_data$data) > 0 && !is.null(precip_data$data[[1]]$value)) {
        precip_change <- precip_data$data[[1]]$value
      }
    }
    
    future_data <- rbind(future_data, data.frame(
      iso3 = code,
      country = TARGET_COUNTRIES[[code]],
      scenario = scenario,
      period = period,
      temp_anomaly = temp_anomaly,
      precip_change = precip_change,
      data_source = "CMIP6 ensemble",
      stringsAsFactors = FALSE
    ))
    
    Sys.sleep(1)
  }
  
  return(future_data)
}

# Fetch extreme heat indices
fetch_heat_extremes <- function(scenario = "ssp245", period = "2040-2059") {
  cat(sprintf("\n=== Fetching Heat Extremes (%s, %s) ===\n", scenario, period))
  
  extreme_data <- data.frame()
  
  for (code in names(TARGET_COUNTRIES)) {
    cat(sprintf("Fetching heat extremes for %s...\n", TARGET_COUNTRIES[[code]]))
    
    # Hot days >35°C endpoint
    endpoint <- sprintf("%s/cmip6-x1.0_extremes_hd35_absolute_model-median_annual_%s_mean_%s_mean/all/%s",
                       BASE_URL, period, scenario, code)
    
    data <- fetch_climate_data(endpoint)
    
    if (!is.null(data) && !is.null(data$data)) {
      if (length(data$data) > 0 && !is.null(data$data[[1]]$value)) {
        hot_days <- data$data[[1]]$value
        
        extreme_data <- rbind(extreme_data, data.frame(
          iso3 = code,
          country = TARGET_COUNTRIES[[code]],
          hot_days_35C = hot_days,
          scenario = scenario,
          period = period,
          data_source = "CMIP6 extremes",
          stringsAsFactors = FALSE
        ))
      }
    }
    
    Sys.sleep(1)
  }
  
  return(extreme_data)
}

# Main data fetching function
fetch_all_data <- function() {
  cat("========================================\n")
  cat("FETCHING REAL CLIMATE DATA FROM WORLD BANK API\n")
  cat("Data sources: CRU TS 4.06, CMIP6 ensemble\n")
  cat("========================================\n\n")
  
  # Fetch all data types
  temperature_data <- fetch_temperature_data()
  precipitation_data <- fetch_precipitation_data()
  
  # Merge historical data
  if (nrow(temperature_data) > 0 && nrow(precipitation_data) > 0) {
    historical_data <- merge(temperature_data[, c("iso3", "country", "temp_historical")], 
                            precipitation_data[, c("iso3", "country", "precip_historical")], 
                            by = c("iso3", "country"), 
                            all = TRUE)
  } else {
    historical_data <- data.frame()
  }
  
  # Fetch future projections for multiple scenarios
  future_ssp245 <- fetch_future_projections("ssp245", "2040-2059")
  future_ssp585 <- fetch_future_projections("ssp585", "2040-2059")
  
  # Fetch future projections for end of century
  future_ssp245_2080 <- fetch_future_projections("ssp245", "2080-2099")
  future_ssp585_2080 <- fetch_future_projections("ssp585", "2080-2099")
  
  # Fetch heat extremes
  extremes_ssp245 <- fetch_heat_extremes("ssp245", "2040-2059")
  extremes_ssp585 <- fetch_heat_extremes("ssp585", "2080-2099")
  
  # Combine all data
  all_data <- list(
    historical = historical_data,
    future_ssp245_2040 = future_ssp245,
    future_ssp585_2040 = future_ssp585,
    future_ssp245_2080 = future_ssp245_2080,
    future_ssp585_2080 = future_ssp585_2080,
    extremes_ssp245 = extremes_ssp245,
    extremes_ssp585 = extremes_ssp585
  )
  
  # Save to RDS for use in visualization scripts
  saveRDS(all_data, "worldbank_climate_data.rds")
  
  # Also save as CSV for documentation
  write.csv(historical_data, "worldbank_historical_climate.csv", row.names = FALSE)
  write.csv(future_ssp245, "worldbank_future_ssp245_2040.csv", row.names = FALSE)
  write.csv(future_ssp585, "worldbank_future_ssp585_2040.csv", row.names = FALSE)
  
  cat("\n========================================\n")
  cat("DATA FETCHING COMPLETE\n")
  cat("Files saved:\n")
  cat("• worldbank_climate_data.rds - Complete dataset\n")
  cat("• worldbank_historical_climate.csv - Historical data\n")
  cat("• worldbank_future_ssp245_2040.csv - SSP2-4.5 projections\n")
  cat("• worldbank_future_ssp585_2040.csv - SSP5-8.5 projections\n")
  cat("\nData sources properly documented:\n")
  cat("• CRU TS 4.06 (historical observations)\n")
  cat("• CMIP6 ensemble median (future projections)\n")
  cat("• World Bank Climate Change Knowledge Portal API\n")
  cat("========================================\n")
  
  return(all_data)
}

# Run the data fetching
climate_data <- fetch_all_data()

# Display summary
cat("\n=== DATA SUMMARY ===\n")
cat(sprintf("Countries fetched: %d\n", nrow(climate_data$historical)))
cat("\nHistorical data (1991-2020):\n")
print(climate_data$historical[, c("country", "temp_historical", "precip_historical")])

if (nrow(climate_data$future_ssp245_2040) > 0) {
  cat("\nFuture projections available for:\n")
  cat("• SSP2-4.5 (2040-2059)\n")
  cat("• SSP5-8.5 (2040-2059)\n")
  cat("• SSP2-4.5 (2080-2099)\n")
  cat("• SSP5-8.5 (2080-2099)\n")
}