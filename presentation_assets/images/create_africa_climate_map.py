#!/usr/bin/env python3
"""
Scientific visualization of African Köppen-Geiger climate zones with study locations
Created following Nature/Science publication standards
"""

import matplotlib.pyplot as plt
import matplotlib.patches as patches
import geopandas as gpd
import pandas as pd
import numpy as np
from matplotlib.patches import Rectangle
import warnings
warnings.filterwarnings('ignore')

# Set publication-quality style
plt.style.use('default')
plt.rcParams.update({
    'font.family': 'sans-serif',
    'font.sans-serif': ['Arial', 'DejaVu Sans', 'Liberation Sans'],
    'font.size': 10,
    'axes.linewidth': 0.5,
    'axes.spines.left': True,
    'axes.spines.bottom': True,
    'axes.spines.top': False,
    'axes.spines.right': False,
    'xtick.direction': 'out',
    'ytick.direction': 'out',
    'axes.grid': False,
    'figure.facecolor': 'white',
    'axes.facecolor': 'white'
})

def load_climate_data():
    """Load and process Köppen-Geiger climate data"""
    try:
        # Load the GeoJSON data
        gdf = gpd.read_file('koppen_africa_with_labels.geojson')
        print(f"Loaded {len(gdf)} climate polygons")
        
        # Print unique climate zones found
        unique_climates = gdf['koppen_code'].unique()
        print(f"Climate zones found: {sorted(unique_climates)}")
        
        return gdf
    except Exception as e:
        print(f"Error loading climate data: {e}")
        return None

def get_climate_colors():
    """Define scientifically accurate colors for Köppen climate zones"""
    # Based on standard Köppen-Geiger color schemes used in climatology
    colors = {
        'Af': '#006837',   # Tropical rainforest - dark green
        'Am': '#31a354',   # Tropical monsoon - medium green
        'Aw': '#74c476',   # Tropical wet savanna - light green  
        'As': '#a1d99b',   # Tropical dry savanna - very light green
        'BWh': '#fee08b',  # Hot desert - yellow
        'BWk': '#fdae61',  # Cold desert - orange
        'BSh': '#f46d43',  # Hot semi-arid - red-orange
        'BSk': '#a50026',  # Cold semi-arid - dark red
        'BSh/BSk': '#d73027', # Semi-arid variant - red
        'Csa': '#762a83',  # Mediterranean hot summer - purple
        'Csb': '#5aae61',  # Mediterranean warm summer - green
        'Cwa': '#2166ac',  # Humid subtropical - blue
        'Cwb': '#5288bd',  # Subtropical highland - medium blue
        'Cfa': '#92c5de',  # Humid subtropical - light blue
        'Cfb': '#c7eae5',  # Oceanic - very light blue
        'Dfb': '#4575b4',  # Continental warm summer - dark blue
        'Dsa': '#313695'   # Continental hot dry summer - very dark blue
    }
    return colors

def create_africa_map():
    """Create the main map figure"""
    # Create figure with publication dimensions
    fig, ax = plt.subplots(1, 1, figsize=(12, 9), dpi=300)
    
    # Load climate data
    climate_gdf = load_climate_data()
    climate_colors = get_climate_colors()
    
    if climate_gdf is not None:
        # Plot climate zones
        for idx, row in climate_gdf.iterrows():
            climate_code = row['koppen_code']
            color = climate_colors.get(climate_code, '#cccccc')
            
            # Plot the polygon
            if row.geometry.geom_type == 'Polygon':
                coords = list(row.geometry.exterior.coords)
                x_coords = [coord[0] for coord in coords]
                y_coords = [coord[1] for coord in coords]
                ax.fill(x_coords, y_coords, color=color, alpha=0.7, 
                       edgecolor='white', linewidth=0.1)
            elif row.geometry.geom_type == 'MultiPolygon':
                for geom in row.geometry.geoms:
                    coords = list(geom.exterior.coords)
                    x_coords = [coord[0] for coord in coords]
                    y_coords = [coord[1] for coord in coords]
                    ax.fill(x_coords, y_coords, color=color, alpha=0.7,
                           edgecolor='white', linewidth=0.1)
    
    # Study locations
    study_locations = [
        {'name': 'Abidjan', 'lat': 5.345317, 'lon': -4.024429, 'participants': 9162, 'climate': 'Am'},
        {'name': 'Johannesburg', 'lat': -26.195246, 'lon': 28.034088, 'participants': 11800, 'climate': 'Cwa'}
    ]
    
    # Plot study locations
    for location in study_locations:
        # Size marker by participants
        size = 150 if location['participants'] > 10000 else 100
        
        # Plot marker
        ax.scatter(location['lon'], location['lat'], 
                  s=size, c='#E3120B', marker='o', 
                  edgecolor='white', linewidth=2, zorder=5)
        
        # Add location label
        ax.annotate(location['name'], 
                   (location['lon'], location['lat']),
                   xytext=(8, 8), textcoords='offset points',
                   fontsize=9, fontweight='bold',
                   bbox=dict(boxstyle='round,pad=0.3', facecolor='white', 
                            edgecolor='none', alpha=0.8))
    
    # Set map extent for Africa
    ax.set_xlim(-20, 55)
    ax.set_ylim(-35, 40)
    
    # Add country boundaries (simplified)
    add_country_labels(ax)
    
    # Style the map
    ax.set_xlabel('Longitude (°E)', fontsize=10)
    ax.set_ylabel('Latitude (°N)', fontsize=10)
    ax.set_title('Study locations in African climate context\nKöppen-Geiger climate classification and participant distribution', 
                fontsize=12, fontweight='bold', pad=20)
    
    # Remove tick marks but keep labels
    ax.tick_params(axis='both', which='both', length=0)
    
    # Add grid with subtle styling
    ax.grid(True, alpha=0.3, linewidth=0.5, color='gray')
    
    return fig, ax, climate_gdf, climate_colors

def add_country_labels(ax):
    """Add major country labels"""
    countries = [
        {'name': 'ALGERIA', 'lon': 3, 'lat': 28},
        {'name': 'LIBYA', 'lon': 17, 'lat': 27},
        {'name': 'EGYPT', 'lon': 30, 'lat': 26},
        {'name': 'SUDAN', 'lon': 30, 'lat': 15},
        {'name': 'CHAD', 'lon': 19, 'lat': 15},
        {'name': 'NIGER', 'lon': 8, 'lat': 16},
        {'name': 'MALI', 'lon': -4, 'lat': 17},
        {'name': 'NIGERIA', 'lon': 8, 'lat': 10},
        {'name': 'ETHIOPIA', 'lon': 40, 'lat': 9},
        {'name': 'KENYA', 'lon': 38, 'lat': 1},
        {'name': 'TANZANIA', 'lon': 35, 'lat': -6},
        {'name': 'DEM. REP.', 'lon': 22, 'lat': -4},
        {'name': 'CONGO', 'lon': 22, 'lat': -6},
        {'name': 'ANGOLA', 'lon': 18, 'lat': -12},
        {'name': 'NAMIBIA', 'lon': 17, 'lat': -22},
        {'name': 'SOUTH AFRICA', 'lon': 24, 'lat': -29},
        {'name': 'MADAGASCAR', 'lon': 47, 'lat': -19}
    ]
    
    for country in countries:
        ax.text(country['lon'], country['lat'], country['name'],
               fontsize=8, color='gray', ha='center', va='center',
               alpha=0.7, weight='normal')

def create_legend(ax, climate_gdf, climate_colors):
    """Create publication-quality legend"""
    if climate_gdf is None:
        return
    
    # Get unique climate zones present in the data
    unique_climates = sorted(climate_gdf['koppen_code'].unique())
    climate_names = {
        'Af': 'Tropical rainforest',
        'Am': 'Tropical monsoon', 
        'Aw': 'Tropical wet savanna',
        'As': 'Tropical dry savanna',
        'BWh': 'Hot desert',
        'BWk': 'Cold desert', 
        'BSh': 'Hot semi-arid',
        'BSk': 'Cold semi-arid',
        'BSh/BSk': 'Semi-arid variant',
        'Csa': 'Mediterranean hot summer',
        'Csb': 'Mediterranean warm summer',
        'Cwa': 'Humid subtropical',
        'Cwb': 'Subtropical highland',
        'Cfa': 'Humid subtropical',
        'Cfb': 'Oceanic',
        'Dfb': 'Continental warm summer',
        'Dsa': 'Continental hot dry summer'
    }
    
    # Create legend elements
    legend_elements = []
    for climate in unique_climates[:8]:  # Show top 8 most common
        if climate in climate_colors and climate in climate_names:
            legend_elements.append(
                patches.Patch(color=climate_colors[climate], 
                            label=f'{climate} – {climate_names[climate]}')
            )
    
    # Add study location markers to legend
    legend_elements.append(
        plt.Line2D([0], [0], marker='o', color='w', markerfacecolor='#E3120B',
                  markersize=8, markeredgecolor='white', markeredgewidth=1,
                  label='Study locations')
    )
    
    # Position legend
    legend = ax.legend(handles=legend_elements, loc='lower left', 
                      bbox_to_anchor=(0.02, 0.02), frameon=True, 
                      fancybox=False, fontsize=9)
    legend.get_frame().set_edgecolor('black')
    legend.get_frame().set_facecolor('white')
    legend.get_frame().set_alpha(0.9)

def add_statistics_panel(fig):
    """Add study statistics panel"""
    # Create text box with study information
    stats_text = """Study Overview
Studies: 23
Participants: 20,962
Countries: 2
Climate zones: 14

Abidjan: 9,162 participants
Johannesburg: 11,800 participants"""
    
    fig.text(0.82, 0.75, stats_text, fontsize=9,
            bbox=dict(boxstyle='round,pad=0.5', facecolor='white', 
                     edgecolor='gray', alpha=0.9),
            verticalalignment='top')

def main():
    """Main function to create the visualization"""
    print("Creating African climate zone map with study locations...")
    
    # Create the map
    fig, ax, climate_gdf, climate_colors = create_africa_map()
    
    # Add legend
    create_legend(ax, climate_gdf, climate_colors)
    
    # Add statistics panel
    add_statistics_panel(fig)
    
    # Adjust layout
    plt.tight_layout()
    
    # Save high-resolution figure
    output_file = 'africa_climate_study_locations.png'
    plt.savefig(output_file, dpi=300, bbox_inches='tight', 
               facecolor='white', edgecolor='none')
    
    print(f"Map saved as {output_file}")
    
    # Also save as PDF for publication
    plt.savefig('africa_climate_study_locations.pdf', 
               bbox_inches='tight', facecolor='white', edgecolor='none')
    
    plt.show()

if __name__ == "__main__":
    main()