#!/usr/bin/env Rscript
# Create organized Köppen-Geiger legend following paper structure
# Main groups (A, B, C, D, E) horizontal, subcategories vertical

suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
})

# Köppen-Geiger classification structure (only zones present in southern Africa)
koppen_structure <- list(
  A = list(
    title = "A - Tropical",
    zones = data.frame(
      code = c("Am", "Aw"),
      name = c("Tropical monsoon", "Tropical savannah"),
      color = c("#228B22", "#90EE90"),
      stringsAsFactors = FALSE
    )
  ),
  B = list(
    title = "B - Arid",
    zones = data.frame(
      code = c("BWh", "BWk", "BSh", "BSk"),
      name = c("Hot desert", "Cold desert", "Hot semi-arid", "Cold semi-arid"),
      color = c("#FFD700", "#FF8C00", "#FF6347", "#DC143C"),
      stringsAsFactors = FALSE
    )
  ),
  C = list(
    title = "C - Temperate",
    zones = data.frame(
      code = c("Csa", "Csb", "Cwa", "Cwb", "Cwc", "Cfa", "Cfb"),
      name = c("Mediterranean hot", "Mediterranean warm", "Humid subtropical", 
               "Subtropical highland", "Subtropical cold", "Humid temperate", "Oceanic"),
      color = c("#8B008B", "#32CD32", "#1E90FF", "#4169E1", "#00CED1", "#87CEEB", "#B0E0E6"),
      stringsAsFactors = FALSE
    )
  ),
  D = list(
    title = "D - Cold",
    zones = data.frame(
      code = c("Dwc", "Dfb"),
      name = c("Cold, dry winter", "Cold, no dry season"),
      color = c("#20B2AA", "#D3D3D3"),
      stringsAsFactors = FALSE
    )
  ),
  E = list(
    title = "E - Polar",
    zones = data.frame(
      code = c("ET"),
      name = c("Tundra"),
      color = c("#696969"),
      stringsAsFactors = FALSE
    )
  )
)

create_structured_legend <- function() {
  # Set up plot dimensions
  group_width <- 2.4
  total_width <- length(koppen_structure) * group_width
  max_zones <- max(sapply(koppen_structure, function(x) nrow(x$zones)))
  
  p <- ggplot() +
    xlim(0, total_width) + ylim(0, max_zones + 3.5) +
    
    # Main title
    annotate("text", x = total_width/2, y = max_zones + 3, 
             label = "Köppen-Geiger Climate Classification", 
             size = 7, fontface = "bold", hjust = 0.5) +
    
    theme_void() +
    theme(
      plot.background = element_rect(fill = "white", color = NA),
      panel.background = element_rect(fill = "white", color = NA),
      plot.margin = margin(20, 20, 20, 20)
    )
  
  # Add each climate group
  for (i in 1:length(koppen_structure)) {
    group_name <- names(koppen_structure)[i]
    group_data <- koppen_structure[[group_name]]
    
    x_start <- (i - 1) * group_width + 0.2
    x_center <- x_start + group_width/2 - 0.2
    
    # Group title
    p <- p + 
      annotate("text", x = x_center, y = max_zones + 1.8, 
               label = group_data$title, 
               size = 5.5, fontface = "bold", hjust = 0.5,
               color = "gray20") +
      
      # Underline for group
      annotate("segment", x = x_start + 0.2, xend = x_start + group_width - 0.4, 
               y = max_zones + 1.5, yend = max_zones + 1.5,
               color = "gray40", linewidth = 1)
    
    # Add zones for this group
    for (j in 1:nrow(group_data$zones)) {
      zone <- group_data$zones[j, ]
      y_pos <- max_zones + 1 - j * 0.5
      
      # Color square
      p <- p + 
        annotate("rect", 
                 xmin = x_start + 0.1, xmax = x_start + 0.35, 
                 ymin = y_pos - 0.08, ymax = y_pos + 0.08,
                 fill = zone$color, color = "black", linewidth = 0.3)
      
      # Zone code and name
      p <- p + 
        annotate("text", x = x_start + 0.45, y = y_pos, 
                 label = paste0(zone$code, " - ", zone$name),
                 size = 3.2, hjust = 0, fontface = "bold")
    }
  }
  
  # Add data source section at bottom
  source_y <- 1.5
  p <- p + 
    annotate("text", x = total_width/2, y = source_y, 
             label = "Data Source", 
             size = 5.5, fontface = "bold", hjust = 0.5) +
    
    annotate("text", x = total_width/2, y = source_y - 0.4, 
             label = paste(
               "Beck, H.E. et al. (2023). High-resolution (1 km) Köppen-Geiger maps for 1901–2099",
               "based on constrained CMIP6 projections. Scientific Data 10, 724."
             ), 
             size = 3.5, hjust = 0.5, lineheight = 1.1) +
    
    annotate("text", x = total_width/2, y = source_y - 0.8, 
             label = "DOI: 10.1038/s41597-023-02549-6", 
             size = 3.8, hjust = 0.5, fontface = "bold", color = "#0066CC") +
    
    annotate("text", x = total_width/2, y = source_y - 1.1, 
             label = "Available: https://figshare.com/articles/dataset/21789074", 
             size = 3.3, hjust = 0.5, color = "#0066CC") +
    
    # Border around entire legend
    annotate("rect", xmin = 0.05, xmax = total_width - 0.05, 
             ymin = 0.05, ymax = max_zones + 3.3,
             fill = NA, color = "black", linewidth = 1.2)
  
  return(p)
}

# Create the structured legend
structured_legend <- create_structured_legend()

# Save as SVG
ggsave("climate_zone_legend_structured.svg", structured_legend, 
       width = 14, height = 10, bg = "white", device = "svg")

cat("✅ Structured Köppen-Geiger legend created!\n")
cat("File: climate_zone_legend_structured.svg\n")
cat("Organization: A (Tropical) | B (Arid) | C (Temperate) | D (Cold) | E (Polar)\n")
cat("Each group shows subcategories vertically below\n")
cat("Perfect for Figma integration with your climate trajectory diagram!\n")