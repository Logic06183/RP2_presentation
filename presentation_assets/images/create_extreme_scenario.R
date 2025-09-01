#!/usr/bin/env Rscript
# Create extreme warming scenario (SSP5-8.5) for additional comparison

suppressPackageStartupMessages({
  library(sf)
  library(ggplot2)
  library(dplyr)
  library(terra)
})

# Use same functions from successful script
source("create_comparison_svg.R")

# Create extreme warming scenario map
cat("Creating extreme warming scenario map (SSP5-8.5)...\n")
extreme_map <- create_climate_map_final(
  "high_res_koppen/2071_2099/ssp585/koppen_geiger_0p00833333.tif",
  "Extreme Warming Scenario (2071-2099)",
  "SSP5-8.5 high warming scenario"
)

ggsave("southern_africa_future_2071_2099_ssp585_extreme.svg", extreme_map, 
       width = 14, height = 10, bg = "white")

cat("✅ Extreme scenario map saved: southern_africa_future_2071_2099_ssp585_extreme.svg\n")