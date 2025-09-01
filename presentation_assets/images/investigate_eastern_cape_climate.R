#!/usr/bin/env Rscript
# Investigate Eastern Cape climate zones - check for subpolar oceanic (Cfc)
# Verify climate classification accuracy for South Africa

suppressPackageStartupMessages({
  library(sf)
  library(terra)
  library(dplyr)
})

# Load the 1991-2020 Köppen-Geiger data
koppen_raster <- rast("high_res_koppen/1991_2020/koppen_geiger_0p00833333.tif")

# Define South Africa approximate bounds
sa_bounds <- ext(16, 33, -35, -22)  # Eastern Cape is roughly 22-28°E, -35 to -30°N

# Crop to South Africa region
koppen_sa <- crop(koppen_raster, sa_bounds)

# Get unique values in South Africa
unique_values <- unique(values(koppen_sa, na.rm = TRUE))
cat("Unique Köppen-Geiger codes found in South Africa region:\n")
print(sort(unique_values))

# Focus on Eastern Cape specifically (approximate bounds)
ec_bounds <- ext(22, 28, -35, -30)  # Eastern Cape region
koppen_ec <- crop(koppen_raster, ec_bounds)

ec_values <- unique(values(koppen_ec, na.rm = TRUE))
cat("\nUnique Köppen-Geiger codes in Eastern Cape region:\n")
print(sort(ec_values))

# Check if code 16 (Cfc - Subpolar oceanic) is present
if (16 %in% ec_values) {
  cat("\n⚠️  WARNING: Code 16 (Cfc - Subpolar oceanic) found in Eastern Cape!\n")
  cat("This is highly unusual for South Africa's latitude (~30-35°S)\n")
  cat("Subpolar oceanic climate typically occurs at latitudes >50°\n")
  
  # Count pixels with this classification
  ec_16_count <- sum(values(koppen_ec) == 16, na.rm = TRUE)
  total_ec_pixels <- sum(!is.na(values(koppen_ec)))
  percentage <- (ec_16_count / total_ec_pixels) * 100
  
  cat(sprintf("Extent: %.1f%% of Eastern Cape pixels (%d out of %d)\n", 
              percentage, ec_16_count, total_ec_pixels))
} else {
  cat("\n✓ No subpolar oceanic climate (code 16) found in Eastern Cape\n")
}

# Load legend to decode all present climate types
legend_file <- "high_res_koppen/legend.txt"
if (file.exists(legend_file)) {
  cat("\nDecoding all climate types found in Eastern Cape:\n")
  # This will help us understand what climate zones are actually present
  cat("Codes found:", paste(sort(ec_values), collapse = ", "), "\n")
}