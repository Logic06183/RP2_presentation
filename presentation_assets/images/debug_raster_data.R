#!/usr/bin/env Rscript
# Debug raster data loading issues

suppressPackageStartupMessages({
  library(terra)
})

# Test baseline raster
cat("Testing baseline raster (1991-2020)...\n")
baseline_path <- "high_res_koppen/1991_2020/koppen_geiger_0p00833333.tif"

if (file.exists(baseline_path)) {
  baseline_raster <- rast(baseline_path)
  cat("✅ Baseline raster loaded successfully\n")
  cat("Dimensions:", dim(baseline_raster), "\n")
  cat("Extent:", as.vector(ext(baseline_raster)), "\n")
  cat("CRS:", crs(baseline_raster), "\n")
  
  # Test values
  sample_values <- values(baseline_raster)[1:100]
  cat("Sample values (first 100):", sample_values[!is.na(sample_values)][1:10], "\n")
  cat("Unique values:", length(unique(values(baseline_raster, na.rm = TRUE))), "\n")
  cat("Value range:", range(values(baseline_raster), na.rm = TRUE), "\n")
} else {
  cat("❌ Baseline raster file not found at:", baseline_path, "\n")
}

# Test future projection raster
cat("\nTesting future projection raster (2071-2099)...\n")
future_path <- "high_res_koppen/2071_2099/ssp245/koppen_geiger_0p00833333.tif"

if (file.exists(future_path)) {
  future_raster <- rast(future_path)
  cat("✅ Future raster loaded successfully\n")
  cat("Dimensions:", dim(future_raster), "\n")
  cat("Extent:", as.vector(ext(future_raster)), "\n")
  
  # Test crop to southern Africa
  africa_bounds <- ext(15, 35, -36, -20)
  future_cropped <- crop(future_raster, africa_bounds)
  cat("Cropped dimensions:", dim(future_cropped), "\n")
  
  # Test conversion to dataframe
  future_df <- as.data.frame(future_cropped, xy = TRUE)
  cat("Dataframe rows:", nrow(future_df), "\n")
  cat("Non-NA rows:", sum(!is.na(future_df[,3])), "\n")
  
} else {
  cat("❌ Future raster file not found at:", future_path, "\n")
}