#!/usr/bin/env python3
"""
Google Earth Engine Heat Health Context Maps for Johannesburg and Abidjan
Generates comprehensive environmental and demographic maps for heat health analysis
"""

import ee
import folium
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from datetime import datetime, timedelta
import json
import os
from typing import Dict, List, Tuple, Any
import warnings
warnings.filterwarnings('ignore')

# Initialize Earth Engine
try:
    ee.Initialize(project='joburg-hvi')
    print("✓ Google Earth Engine initialized successfully with project joburg-hvi")
except Exception as e:
    print(f"⚠ Error initializing EE: {e}")
    print("Please run: earthengine authenticate --project=joburg-hvi")
    print("Then try running the script again")
    exit(1)

class HeatHealthMapper:
    """Generate heat health context maps using Google Earth Engine"""
    
    def __init__(self):
        """Initialize the mapper with city coordinates"""
        self.cities = {
            'Johannesburg': {
                'coords': [27.9, -26.3, 28.3, -26.0],  # xmin, ymin, xmax, ymax
                'center': [28.0473, -26.2041],
                'zoom': 10
            },
            'Abidjan': {
                'coords': [-4.2, 5.2, -3.8, 5.5],
                'center': [-4.0083, 5.3599],
                'zoom': 10
            }
        }
        
        self.palettes = {
            'temperature': ['0000FF', '00FFFF', '00FF00', 'FFFF00', 'FF8C00', 'FF0000'],
            'ndvi': ['FF0000', 'FFFF00', '00FF00', '008000', '004000'],
            'urban': ['FFFFFF', 'FFE5CC', 'FFCC99', 'FF9966', 'FF6633', 'CC0000'],
            'nightlights': ['000000', '0000FF', '00FFFF', 'FFFF00', 'FFA500', 'FF0000'],
            'population': ['FFFFFF', 'FFFFCC', 'FFEDA0', 'FED976', 'FEB24C', 'FD8D3C', 'FC4E2A', 'E31A1C', 'B10026'],
            'no2': ['0000FF', '00FF00', 'FFFF00', 'FFA500', 'FF0000', '8B0000'],
            'hvi': ['00FF00', '90EE90', 'FFFF00', 'FFA500', 'FF4500', '8B0000']
        }
        
        self.results = {}
        
    def create_geometry(self, city: str) -> ee.Geometry:
        """Create Earth Engine geometry for a city"""
        coords = self.cities[city]['coords']
        return ee.Geometry.Rectangle(coords)
    
    def get_land_surface_temperature(self, city: str, year: int = 2023) -> Dict:
        """Get Land Surface Temperature data"""
        print(f"Processing LST for {city}...")
        
        geometry = self.create_geometry(city)
        
        # Use MODIS LST data
        lst_collection = (ee.ImageCollection('MODIS/061/MOD11A1')
                         .filterDate(f'{year}-01-01', f'{year}-12-31')
                         .filterBounds(geometry)
                         .select('LST_Day_1km'))
        
        # Calculate mean LST and convert to Celsius
        lst_mean = (lst_collection.mean()
                   .multiply(0.02)
                   .subtract(273.15)
                   .clip(geometry))
        
        # Calculate summer LST (Jun-Aug for Johannesburg, year-round for Abidjan)
        if city == 'Johannesburg':
            summer_months = [6, 7, 8]
            lst_summer = (ee.ImageCollection('MODIS/061/MOD11A1')
                         .filterDate(f'{year}-06-01', f'{year}-08-31')
                         .filterBounds(geometry)
                         .select('LST_Day_1km')
                         .mean()
                         .multiply(0.02)
                         .subtract(273.15)
                         .clip(geometry))
        else:  # Abidjan
            lst_summer = lst_mean  # Tropical climate, use annual mean
        
        # Calculate statistics
        stats = lst_mean.reduceRegion(
            reducer=ee.Reducer.percentile([25, 50, 75, 90, 95]),
            geometry=geometry,
            scale=1000,
            maxPixels=1e9
        )
        
        return {
            'mean': lst_mean,
            'summer': lst_summer,
            'stats': stats.getInfo(),
            'viz_params': {
                'min': 20,
                'max': 45,
                'palette': self.palettes['temperature']
            }
        }
    
    def get_vegetation_index(self, city: str, year: int = 2023) -> Dict:
        """Calculate NDVI from Sentinel-2"""
        print(f"Processing NDVI for {city}...")
        
        geometry = self.create_geometry(city)
        
        # Use Sentinel-2 for better resolution
        s2_collection = (ee.ImageCollection('COPERNICUS/S2_SR_HARMONIZED')
                        .filterDate(f'{year}-01-01', f'{year}-12-31')
                        .filterBounds(geometry)
                        .filter(ee.Filter.lt('CLOUDY_PIXEL_PERCENTAGE', 10)))
        
        # Create cloud-free composite
        composite = s2_collection.median().clip(geometry)
        
        # Calculate NDVI
        ndvi = composite.normalizedDifference(['B8', 'B4']).rename('NDVI')
        
        # Calculate statistics
        stats = ndvi.reduceRegion(
            reducer=ee.Reducer.percentile([25, 50, 75, 90]),
            geometry=geometry,
            scale=100,
            maxPixels=1e9
        )
        
        return {
            'ndvi': ndvi,
            'composite': composite,
            'stats': stats.getInfo(),
            'viz_params': {
                'min': -0.2,
                'max': 0.8,
                'palette': self.palettes['ndvi']
            }
        }
    
    def get_urban_heat_island(self, city: str) -> Dict:
        """Analyze Urban Heat Island effect"""
        print(f"Processing UHI for {city}...")
        
        geometry = self.create_geometry(city)
        
        # Get LST data for summer
        lst_data = self.get_land_surface_temperature(city)
        lst_summer = lst_data['summer']
        
        # Get impervious surface data
        impervious = (ee.ImageCollection('COPERNICUS/Landcover/100m/Proba-V-C3/Global')
                     .select('urban-coverfraction')
                     .first()
                     .clip(geometry))
        
        # Get built-up area from Dynamic World
        built_up = (ee.ImageCollection('GOOGLE/DYNAMICWORLD/V1')
                   .filterDate('2023-01-01', '2023-12-31')
                   .filterBounds(geometry)
                   .select('built')
                   .mean()
                   .multiply(100)
                   .clip(geometry))
        
        return {
            'lst': lst_summer,
            'impervious': impervious,
            'built_up': built_up,
            'viz_params_urban': {
                'min': 0,
                'max': 100,
                'palette': self.palettes['urban']
            }
        }
    
    def get_nighttime_lights(self, city: str, year: int = 2023) -> Dict:
        """Analyze nighttime lights as proxy for economic activity"""
        print(f"Processing nighttime lights for {city}...")
        
        geometry = self.create_geometry(city)
        
        # Use VIIRS nighttime lights
        viirs = (ee.ImageCollection('NOAA/VIIRS/DNB/MONTHLY_V1/VCMSLCFG')
                .filterDate(f'{year}-01-01', f'{year}-12-31')
                .filterBounds(geometry)
                .select('avg_rad'))
        
        # Calculate median
        nightlights = viirs.median().clip(geometry)
        
        # Calculate statistics
        stats = nightlights.reduceRegion(
            reducer=ee.Reducer.percentile([25, 50, 75, 90, 95]),
            geometry=geometry,
            scale=500,
            maxPixels=1e9
        )
        
        return {
            'image': nightlights,
            'stats': stats.getInfo(),
            'viz_params': {
                'min': 0,
                'max': 60,
                'palette': self.palettes['nightlights']
            }
        }
    
    def get_population_density(self, city: str) -> Dict:
        """Get population density data"""
        print(f"Processing population density for {city}...")
        
        geometry = self.create_geometry(city)
        
        # Use WorldPop data
        try:
            # Try to get the most recent WorldPop data
            population = (ee.ImageCollection('WorldPop/GP/100m/pop')
                         .filterBounds(geometry)
                         .first()
                         .clip(geometry))
        except:
            # Fallback to GHS population
            population = (ee.Image('JRC/GHSL/P2023A/GHS_POP/2020')
                         .select('b1')
                         .clip(geometry))
        
        # Calculate total population
        total_pop = population.reduceRegion(
            reducer=ee.Reducer.sum(),
            geometry=geometry,
            scale=100,
            maxPixels=1e9
        )
        
        return {
            'image': population,
            'total': total_pop.getInfo(),
            'viz_params': {
                'min': 0,
                'max': 1000,
                'palette': self.palettes['population']
            }
        }
    
    def get_air_quality(self, city: str, year: int = 2023) -> Dict:
        """Get NO2 air quality data"""
        print(f"Processing air quality for {city}...")
        
        geometry = self.create_geometry(city)
        
        # Use Sentinel-5P TROPOMI NO2 data
        no2 = (ee.ImageCollection('COPERNICUS/S5P/NRTI/L3_NO2')
              .filterDate(f'{year}-01-01', f'{year}-12-31')
              .filterBounds(geometry)
              .select('NO2_column_number_density'))
        
        # Calculate mean NO2
        no2_mean = no2.mean().clip(geometry)
        
        # Calculate statistics
        stats = no2_mean.reduceRegion(
            reducer=ee.Reducer.percentile([25, 50, 75, 90, 95]),
            geometry=geometry,
            scale=1000,
            maxPixels=1e9
        )
        
        return {
            'image': no2_mean,
            'stats': stats.getInfo(),
            'viz_params': {
                'min': 0,
                'max': 0.0002,
                'palette': self.palettes['no2']
            }
        }
    
    def calculate_heat_vulnerability_index(self, city: str) -> Dict:
        """Calculate composite Heat Vulnerability Index"""
        print(f"Calculating Heat Vulnerability Index for {city}...")
        
        geometry = self.create_geometry(city)
        
        # Get all component layers
        lst_data = self.get_land_surface_temperature(city)
        ndvi_data = self.get_vegetation_index(city)
        pop_data = self.get_population_density(city)
        uhi_data = self.get_urban_heat_island(city)
        
        # Normalize layers to 0-1 scale
        lst_norm = lst_data['summer'].unitScale(20, 45)
        ndvi_norm = ndvi_data['ndvi'].multiply(-1).add(1).multiply(0.5)  # Invert: less vegetation = higher vulnerability
        pop_norm = pop_data['image'].unitScale(0, 1000)
        imperv_norm = uhi_data['impervious'].divide(100)
        
        # Calculate weighted HVI
        weights = {
            'temperature': 0.3,
            'vegetation': 0.2,
            'population': 0.3,
            'impervious': 0.2
        }
        
        hvi = (lst_norm.multiply(weights['temperature'])
              .add(ndvi_norm.multiply(weights['vegetation']))
              .add(pop_norm.multiply(weights['population']))
              .add(imperv_norm.multiply(weights['impervious']))
              .rename('HVI')
              .clip(geometry))
        
        # Calculate statistics
        stats = hvi.reduceRegion(
            reducer=ee.Reducer.percentile([25, 50, 75, 90, 95]),
            geometry=geometry,
            scale=100,
            maxPixels=1e9
        )
        
        return {
            'hvi': hvi,
            'components': {
                'lst_norm': lst_norm,
                'ndvi_norm': ndvi_norm,
                'pop_norm': pop_norm,
                'imperv_norm': imperv_norm
            },
            'weights': weights,
            'stats': stats.getInfo(),
            'viz_params': {
                'min': 0,
                'max': 1,
                'palette': self.palettes['hvi']
            }
        }
    
    def create_folium_map(self, city: str, layer_name: str, image: ee.Image, 
                         viz_params: Dict) -> folium.Map:
        """Create an interactive Folium map"""
        
        # Create base map
        center = self.cities[city]['center']
        m = folium.Map(location=[center[1], center[0]], zoom_start=self.cities[city]['zoom'])
        
        # Add the EE layer
        map_id_dict = image.getMapId(viz_params)
        folium.TileLayer(
            tiles=map_id_dict['tile_fetcher'].url_format,
            attr='Google Earth Engine',
            name=layer_name,
            overlay=True,
            control=True
        ).add_to(m)
        
        # Add layer control
        folium.LayerControl().add_to(m)
        
        return m
    
    def export_to_drive(self, image: ee.Image, city: str, layer_name: str, 
                        scale: int = 100) -> ee.batch.Task:
        """Export image to Google Drive"""
        
        geometry = self.create_geometry(city)
        
        task = ee.batch.Export.image.toDrive(
            image=image,
            description=f'{city}_{layer_name}',
            folder='GEE_Heat_Health_Maps',
            fileNamePrefix=f'{city}_{layer_name}',
            region=geometry,
            scale=scale,
            maxPixels=1e9
        )
        
        task.start()
        print(f"Export task started: {city}_{layer_name}")
        
        return task
    
    def generate_all_maps(self, export: bool = False) -> Dict:
        """Generate all maps for both cities"""
        
        for city in self.cities.keys():
            print(f"\n{'='*50}")
            print(f"Processing {city}")
            print('='*50)
            
            self.results[city] = {}
            
            # Generate all analyses
            try:
                self.results[city]['lst'] = self.get_land_surface_temperature(city)
                print(f"✓ LST complete for {city}")
            except Exception as e:
                print(f"✗ LST failed for {city}: {e}")
            
            try:
                self.results[city]['ndvi'] = self.get_vegetation_index(city)
                print(f"✓ NDVI complete for {city}")
            except Exception as e:
                print(f"✗ NDVI failed for {city}: {e}")
            
            try:
                self.results[city]['uhi'] = self.get_urban_heat_island(city)
                print(f"✓ UHI complete for {city}")
            except Exception as e:
                print(f"✗ UHI failed for {city}: {e}")
            
            try:
                self.results[city]['nightlights'] = self.get_nighttime_lights(city)
                print(f"✓ Nighttime lights complete for {city}")
            except Exception as e:
                print(f"✗ Nighttime lights failed for {city}: {e}")
            
            try:
                self.results[city]['population'] = self.get_population_density(city)
                print(f"✓ Population density complete for {city}")
            except Exception as e:
                print(f"✗ Population density failed for {city}: {e}")
            
            try:
                self.results[city]['air_quality'] = self.get_air_quality(city)
                print(f"✓ Air quality complete for {city}")
            except Exception as e:
                print(f"✗ Air quality failed for {city}: {e}")
            
            try:
                self.results[city]['hvi'] = self.calculate_heat_vulnerability_index(city)
                print(f"✓ HVI complete for {city}")
            except Exception as e:
                print(f"✗ HVI failed for {city}: {e}")
            
            # Export if requested
            if export:
                self.export_results(city)
        
        return self.results
    
    def export_results(self, city: str):
        """Export all results for a city"""
        print(f"\nExporting results for {city}...")
        
        exports = []
        
        if 'lst' in self.results[city]:
            exports.append(self.export_to_drive(
                self.results[city]['lst']['mean'], city, 'LST', 1000
            ))
        
        if 'ndvi' in self.results[city]:
            exports.append(self.export_to_drive(
                self.results[city]['ndvi']['ndvi'], city, 'NDVI', 100
            ))
        
        if 'hvi' in self.results[city]:
            exports.append(self.export_to_drive(
                self.results[city]['hvi']['hvi'], city, 'HVI', 100
            ))
        
        if 'nightlights' in self.results[city]:
            exports.append(self.export_to_drive(
                self.results[city]['nightlights']['image'], city, 'NightLights', 500
            ))
        
        print(f"Started {len(exports)} export tasks for {city}")
    
    def create_comparison_figure(self) -> plt.Figure:
        """Create a comparison figure for both cities"""
        
        fig, axes = plt.subplots(2, 4, figsize=(20, 10))
        fig.suptitle('Heat Health Context: Johannesburg vs Abidjan', fontsize=16)
        
        # Placeholder for visualization
        # In practice, you would download and visualize the actual data
        
        analyses = ['LST', 'NDVI', 'UHI', 'Night Lights']
        
        for i, city in enumerate(['Johannesburg', 'Abidjan']):
            for j, analysis in enumerate(analyses):
                ax = axes[i, j]
                ax.set_title(f'{city}: {analysis}')
                ax.axis('off')
                # Add placeholder text
                ax.text(0.5, 0.5, f'{analysis}\nData', 
                       ha='center', va='center', fontsize=12)
        
        plt.tight_layout()
        return fig
    
    def save_statistics(self, output_file: str = 'heat_health_statistics.json'):
        """Save all statistics to a JSON file"""
        
        stats_output = {}
        
        for city in self.results:
            stats_output[city] = {}
            for analysis in self.results[city]:
                if 'stats' in self.results[city][analysis]:
                    stats_output[city][analysis] = self.results[city][analysis]['stats']
        
        with open(output_file, 'w') as f:
            json.dump(stats_output, f, indent=2)
        
        print(f"Statistics saved to {output_file}")

def main():
    """Main execution function"""
    
    print("="*60)
    print("Google Earth Engine Heat Health Context Mapper")
    print("Analyzing Johannesburg and Abidjan")
    print("="*60)
    
    # Initialize mapper
    mapper = HeatHealthMapper()
    
    # Generate all maps
    results = mapper.generate_all_maps(export=True)
    
    # Save statistics
    mapper.save_statistics()
    
    # Create comparison figure
    fig = mapper.create_comparison_figure()
    fig.savefig('heat_health_comparison.png', dpi=150, bbox_inches='tight')
    print("\nComparison figure saved as 'heat_health_comparison.png'")
    
    # Create individual Folium maps for key layers
    print("\nCreating interactive maps...")
    
    for city in mapper.cities.keys():
        if city in results and 'hvi' in results[city]:
            m = mapper.create_folium_map(
                city, 
                f'{city} Heat Vulnerability Index',
                results[city]['hvi']['hvi'],
                results[city]['hvi']['viz_params']
            )
            m.save(f'{city}_HVI_map.html')
            print(f"✓ Saved {city}_HVI_map.html")
    
    print("\n" + "="*60)
    print("Analysis complete!")
    print("Check Google Drive folder 'GEE_Heat_Health_Maps' for exported images")
    print("="*60)

if __name__ == "__main__":
    main()