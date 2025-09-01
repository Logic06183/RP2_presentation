#!/usr/bin/env Rscript
# Create standalone legend box SVG for easy Figma integration
# Comprehensive Köppen-Geiger climate zone key + data sources

suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(gridExtra)
  library(grid)
})

# Climate zones and colors (all zones present in southern Africa)
climate_zones <- data.frame(
  code = c("Am", "Aw", "BWh", "BWk", "BSh", "BSk", "Csa", "Csb", 
           "Cwa", "Cwb", "Cwc", "Cfa", "Cfb", "Dwc", "Dfb", "ET"),
  description = c(
    "Tropical monsoon", "Tropical savannah", "Hot desert", "Cold desert",
    "Hot semi-arid", "Cold semi-arid", "Mediterranean hot summer", "Mediterranean warm summer",
    "Humid subtropical", "Subtropical highland", "Subtropical cold", "Humid temperate",
    "Oceanic", "Cold, dry winter", "Cold, no dry season", "Tundra"
  ),
  color = c("#228B22", "#90EE90", "#FFD700", "#FF8C00", "#FF6347", "#DC143C", 
            "#8B008B", "#32CD32", "#1E90FF", "#4169E1", "#00CED1", "#87CEEB", 
            "#B0E0E6", "#20B2AA", "#D3D3D3", "#696969"),
  stringsAsFactors = FALSE
)

# Create legend box
create_legend_box <- function() {
  # Calculate positions for legend items
  n_cols <- 4
  n_rows <- ceiling(nrow(climate_zones) / n_cols)
  
  legend_plot <- ggplot() +
    xlim(0, 10) + ylim(0, 8) +
    
    # Title
    annotate("text", x = 5, y = 7.5, 
             label = "Köppen-Geiger Climate Classification Key", 
             size = 6, fontface = "bold", hjust = 0.5) +
    
    # Create legend grid manually
    {
      legend_elements <- list()
      for (i in 1:nrow(climate_zones)) {
        row <- ceiling(i / n_cols)
        col <- ((i - 1) %% n_cols) + 1
        
        x_pos <- 0.5 + (col - 1) * 2.3
        y_pos <- 6.5 - (row - 1) * 0.4
        
        # Color square
        legend_elements <- c(legend_elements, list(
          annotate("rect", xmin = x_pos, xmax = x_pos + 0.3, 
                   ymin = y_pos - 0.1, ymax = y_pos + 0.1,
                   fill = climate_zones$color[i], color = "black", linewidth = 0.3)
        ))
        
        # Zone code and description
        legend_elements <- c(legend_elements, list(
          annotate("text", x = x_pos + 0.4, y = y_pos, 
                   label = paste0(climate_zones$code[i], " - ", climate_zones$description[i]),
                   size = 2.8, hjust = 0, fontface = "bold")
        ))
      }
      legend_elements
    } +
    
    # Data source section
    annotate("text", x = 5, y = 2.8, 
             label = "Data Source", 
             size = 5, fontface = "bold", hjust = 0.5) +
    
    annotate("text", x = 5, y = 2.3, 
             label = paste(
               "Beck, H.E., T.R. McVicar, N. Vergopolan, A. Berg, N.J. Lutsko, A. Dufour, Z. Zeng,",
               "X. Jiang, A.I.J.M. van Dijk, and D.G. Miralles (2023)."
             ), 
             size = 3.2, hjust = 0.5, lineheight = 1.1) +
    
    annotate("text", x = 5, y = 1.8, 
             label = paste(
               "High-resolution (1 km) Köppen-Geiger maps for 1901–2099 based on",
               "constrained CMIP6 projections. Scientific Data 10, 724."
             ), 
             size = 3.2, hjust = 0.5, lineheight = 1.1) +
    
    annotate("text", x = 5, y = 1.3, 
             label = "DOI: 10.1038/s41597-023-02549-6", 
             size = 3.5, hjust = 0.5, fontface = "bold", color = "#0066CC") +
    
    annotate("text", x = 5, y = 0.9, 
             label = "Available: https://figshare.com/articles/dataset/21789074", 
             size = 3.2, hjust = 0.5, color = "#0066CC") +
    
    annotate("text", x = 5, y = 0.4, 
             label = "Baseline: 1991-2020 (30-year climate normal) | Projections: 2071-2099 CMIP6 scenarios", 
             size = 3, hjust = 0.5, color = "gray40", fontface = "italic") +
    
    # Border around entire box
    annotate("rect", xmin = 0.1, xmax = 9.9, ymin = 0.1, ymax = 7.9,
             fill = NA, color = "black", linewidth = 1) +
    
    theme_void() +
    theme(
      plot.background = element_rect(fill = "white", color = NA),
      panel.background = element_rect(fill = "white", color = NA)
    )
  
  return(legend_plot)
}

# Create the standalone legend box
legend_box <- create_legend_box()

# Save as separate SVG
ggsave("climate_zone_legend_box.svg", legend_box, 
       width = 12, height = 8, bg = "white", device = "svg")

cat("✅ Standalone legend box created!\n")
cat("File: climate_zone_legend_box.svg\n")
cat("Perfect for adding to your main diagram in Figma!\n")