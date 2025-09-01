#!/usr/bin/env Rscript
# Debug future projection data structure differences

suppressPackageStartupMessages({
  library(terra)
  library(sf)
})

# Test baseline data structure (working)
cat("=== BASELINE DATA (WORKING) ===\n")
baseline_raster <- rast("high_res_koppen/1991_2020/koppen_geiger_0p00833333.tif")
sa_bbox <- ext(10, 42, -35, -8)
baseline_cropped <- crop(baseline_raster, sa_bbox)

cat("Baseline - Unique values:", length(unique(values(baseline_cropped, na.rm = TRUE))), "\n")
cat("Baseline - Value range:", range(values(baseline_cropped), na.rm = TRUE), "\n")
cat("Baseline - Sample non-NA values:", head(values(baseline_cropped)[!is.na(values(baseline_cropped))], 10), "\n")

# Try polygon conversion
tryCatch({
  baseline_polygons <- as.polygons(baseline_cropped, dissolve = TRUE)
  baseline_sf <- st_as_sf(baseline_polygons)
  cat("Baseline - Polygon conversion: SUCCESS\n")
  cat("Baseline - Column names:", names(baseline_sf), "\n")
  cat("Baseline - SF rows:", nrow(baseline_sf), "\n")
}, error = function(e) {
  cat("Baseline - Polygon conversion FAILED:", e$message, "\n")
})

# Test future data structure
cat("\n=== FUTURE DATA (PROBLEMATIC) ===\n")
future_raster <- rast("high_res_koppen/2071_2099/ssp245/koppen_geiger_0p00833333.tif")
future_cropped <- crop(future_raster, sa_bbox)

cat("Future - Unique values:", length(unique(values(future_cropped, na.rm = TRUE))), "\n")
cat("Future - Value range:", range(values(future_cropped), na.rm = TRUE), "\n")
cat("Future - Sample non-NA values:", head(values(future_cropped)[!is.na(values(future_cropped))], 10), "\n")

# Try polygon conversion
tryCatch({
  future_polygons <- as.polygons(future_cropped, dissolve = TRUE)
  future_sf <- st_as_sf(future_polygons)
  cat("Future - Polygon conversion: SUCCESS\n")
  cat("Future - Column names:", names(future_sf), "\n")
  cat("Future - SF rows:", nrow(future_sf), "\n")
}, error = function(e) {
  cat("Future - Polygon conversion FAILED:", e$message, "\n")
})

# Test different aggregation levels for future data
cat("\n=== TESTING AGGREGATION ===\n")
for (agg_factor in c(2, 4, 8)) {
  tryCatch({
    future_agg <- aggregate(future_cropped, fact = agg_factor, fun = "modal")
    cat(sprintf("Aggregation factor %d: %d x %d cells\n", 
                agg_factor, nrow(future_agg), ncol(future_agg)))
    
    future_agg_polygons <- as.polygons(future_agg, dissolve = TRUE)
    cat(sprintf("Aggregation factor %d: polygon conversion SUCCESS\n", agg_factor))
    
  }, error = function(e) {
    cat(sprintf("Aggregation factor %d: FAILED - %s\n", agg_factor, e$message))
  })
}