#!/usr/bin/env python3
"""
Interactive nighttime lights analysis for Abidjan and Johannesburg
Showing urbanization trends over time using Google Earth Engine and geemap
Created for scientific presentation on urbanization and health studies
"""

import geemap
import ee
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
from datetime import datetime
import folium
import warnings
warnings.filterwarnings('ignore')

# Study locations
STUDY_LOCATIONS = {
    'Abidjan': {
        'coords': [-4.024429, 5.345317],
        'country': 'Côte d\'Ivoire',
        'participants': 9162,
        'buffer_km': 50  # Analysis buffer in km
    },
    'Johannesburg': {
        'coords': [28.034088, -26.195246],
        'country': 'South Africa', 
        'participants': 11800,
        'buffer_km': 50
    }
}

def initialize_gee():
    """Initialize Google Earth Engine"""
    try:
        ee.Initialize()
        print("Google Earth Engine initialized successfully")
        return True
    except:
        try:
            print("Authenticating Google Earth Engine...")
            ee.Authenticate()
            ee.Initialize()
            print("Google Earth Engine authenticated and initialized")
            return True
        except Exception as e:
            print(f"Failed to initialize Google Earth Engine: {e}")
            print("Please run 'earthengine authenticate' in terminal first")
            return False

def create_study_areas():
    """Create study area geometries for both cities"""
    study_areas = {}
    
    for city, data in STUDY_LOCATIONS.items():
        lon, lat = data['coords']
        buffer_m = data['buffer_km'] * 1000  # Convert to meters
        
        # Create point and buffer
        point = ee.Geometry.Point([lon, lat])
        buffer = point.buffer(buffer_m)
        
        study_areas[city] = {
            'geometry': buffer,
            'point': point,
            'data': data
        }
    
    return study_areas

def get_nighttime_lights_data(start_year=2012, end_year=2023):
    """
    Get nighttime lights data from multiple sources:
    - VIIRS DNB (2012-present): High quality, consistent
    - DMSP-OLS (1992-2013): Historical data (if needed)
    """
    
    # VIIRS DNB Monthly data (preferred for 2012+)
    viirs_collection = ee.ImageCollection("NOAA/VIIRS/DNB/MONTHLY_V1/VCMSLCFG") \
        .filter(ee.Filter.date(f'{start_year}-01-01', f'{end_year+1}-01-01')) \
        .select('avg_rad')
    
    print(f"Found {viirs_collection.size().getInfo()} VIIRS nighttime lights images")
    
    return viirs_collection

def analyze_city_urbanization(city_name, study_area, lights_collection):
    """Analyze urbanization trends for a single city"""
    
    geometry = study_area['geometry']
    
    def extract_lights_stats(image):
        """Extract statistics from a single image"""
        # Get image date
        date = ee.Date(image.get('system:time_start'))
        
        # Calculate statistics within the study area
        stats = image.reduceRegion(
            reducer=ee.Reducer.mean().combine(
                reducer2=ee.Reducer.sum(),
                sharedInputs=True
            ).combine(
                reducer2=ee.Reducer.stdDev(),
                sharedInputs=True
            ).combine(
                reducer2=ee.Reducer.max(),
                sharedInputs=True
            ),
            geometry=geometry,
            scale=1000,  # 1km resolution
            maxPixels=1e9
        )
        
        return ee.Feature(None, {
            'date': date.format('YYYY-MM-dd'),
            'year': date.get('year'),
            'month': date.get('month'),
            'mean_radiance': stats.get('avg_rad_mean'),
            'total_radiance': stats.get('avg_rad_sum'), 
            'std_radiance': stats.get('avg_rad_stdDev'),
            'max_radiance': stats.get('avg_rad_max'),
            'city': city_name
        })
    
    # Map over the collection
    stats_collection = lights_collection.map(extract_lights_stats)
    
    # Convert to pandas DataFrame
    stats_list = stats_collection.getInfo()['features']
    
    # Process the data
    data_rows = []
    for feature in stats_list:
        props = feature['properties']
        if props['mean_radiance'] is not None:  # Filter out null values
            data_rows.append({
                'date': props['date'],
                'year': props['year'],
                'month': props['month'],
                'mean_radiance': props['mean_radiance'],
                'total_radiance': props['total_radiance'],
                'std_radiance': props['std_radiance'],
                'max_radiance': props['max_radiance'],
                'city': city_name
            })
    
    df = pd.DataFrame(data_rows)
    df['date'] = pd.to_datetime(df['date'])
    
    return df

def create_time_series_analysis(study_areas, lights_collection):
    """Create time-series analysis for both cities"""
    
    print("Analyzing urbanization trends...")
    
    all_data = []
    
    for city_name, area_data in study_areas.items():
        print(f"Processing {city_name}...")
        
        city_df = analyze_city_urbanization(city_name, area_data, lights_collection)
        all_data.append(city_df)
        
        print(f"  Processed {len(city_df)} data points for {city_name}")
    
    # Combine all data
    combined_df = pd.concat(all_data, ignore_index=True)
    
    return combined_df

def create_interactive_maps(study_areas, lights_collection):
    """Create interactive maps showing nighttime lights"""
    
    print("Creating interactive maps...")
    
    # Create base map
    map_center = [0, 20]  # Center on Africa
    m = geemap.Map(center=map_center, zoom=4)
    
    # Add study locations
    for city, data in STUDY_LOCATIONS.items():
        lon, lat = data['coords']
        
        # Add marker
        marker = folium.Marker(
            [lat, lon],
            popup=f"<b>{city}</b><br>Participants: {data['participants']:,}",
            icon=folium.Icon(color='red', icon='info-sign')
        )
        marker.add_to(m)
        
        # Add study area buffer
        area_coords = []
        geometry = study_areas[city]['geometry']
        coords = geometry.getInfo()['coordinates'][0]
        for coord in coords:
            area_coords.append([coord[1], coord[0]])  # Flip lat/lon for folium
        
        folium.Polygon(
            locations=area_coords,
            popup=f"{city} Study Area",
            color='blue',
            weight=2,
            fillOpacity=0.1
        ).add_to(m)
    
    # Get recent nighttime lights image for visualization
    recent_image = lights_collection.filterDate('2023-01-01', '2023-12-31').mean()
    
    # Add nighttime lights layer
    vis_params = {
        'min': 0,
        'max': 60,
        'palette': ['000000', '4A90E2', '50C878', 'FFFF00', 'FF8C00', 'FF0000']
    }
    
    m.addLayer(recent_image, vis_params, 'Nighttime Lights 2023', opacity=0.7)
    
    # Add layer control
    m.add_layer_control()
    
    return m

def create_urbanization_charts(df):
    """Create publication-quality charts showing urbanization trends"""
    
    # Set up publication style
    plt.style.use('default')
    plt.rcParams.update({
        'font.family': 'sans-serif',
        'font.sans-serif': ['Arial', 'DejaVu Sans'],
        'font.size': 10,
        'axes.linewidth': 0.5,
        'figure.facecolor': 'white'
    })
    
    # Create figure with subplots
    fig, ((ax1, ax2), (ax3, ax4)) = plt.subplots(2, 2, figsize=(14, 10))
    
    # Colors for cities
    colors = {'Abidjan': '#E3120B', 'Johannesburg': '#2196F3'}
    
    # 1. Mean radiance over time
    for city in df['city'].unique():
        city_data = df[df['city'] == city].copy()
        city_data = city_data.groupby('year')['mean_radiance'].mean().reset_index()
        
        ax1.plot(city_data['year'], city_data['mean_radiance'], 
                marker='o', color=colors[city], linewidth=2, 
                label=city, markersize=4)
    
    ax1.set_title('Average Nighttime Light Intensity', fontweight='bold')
    ax1.set_xlabel('Year')
    ax1.set_ylabel('Mean Radiance (nW/cm²/sr)')
    ax1.legend()
    ax1.grid(True, alpha=0.3)
    
    # 2. Total radiance (urbanization extent)
    for city in df['city'].unique():
        city_data = df[df['city'] == city].copy()
        city_data = city_data.groupby('year')['total_radiance'].mean().reset_index()
        
        ax2.plot(city_data['year'], city_data['total_radiance'], 
                marker='s', color=colors[city], linewidth=2, 
                label=city, markersize=4)
    
    ax2.set_title('Total Light Output (Urbanization Extent)', fontweight='bold')
    ax2.set_xlabel('Year')
    ax2.set_ylabel('Total Radiance')
    ax2.legend()
    ax2.grid(True, alpha=0.3)
    
    # 3. Growth rate analysis
    for city in df['city'].unique():
        city_data = df[df['city'] == city].copy()
        yearly_avg = city_data.groupby('year')['mean_radiance'].mean()
        
        # Calculate year-over-year growth rate
        growth_rate = yearly_avg.pct_change() * 100
        
        ax3.bar(growth_rate.index, growth_rate.values, 
               color=colors[city], alpha=0.7, label=city, width=0.4)
    
    ax3.set_title('Year-over-Year Growth Rate', fontweight='bold')
    ax3.set_xlabel('Year')
    ax3.set_ylabel('Growth Rate (%)')
    ax3.legend()
    ax3.grid(True, alpha=0.3)
    ax3.axhline(y=0, color='black', linestyle='-', alpha=0.5)
    
    # 4. Seasonal patterns
    monthly_avg = df.groupby(['city', 'month'])['mean_radiance'].mean().reset_index()
    
    for city in monthly_avg['city'].unique():
        city_monthly = monthly_avg[monthly_avg['city'] == city]
        ax4.plot(city_monthly['month'], city_monthly['mean_radiance'],
                marker='o', color=colors[city], linewidth=2, 
                label=city, markersize=4)
    
    ax4.set_title('Seasonal Patterns (All Years)', fontweight='bold')
    ax4.set_xlabel('Month')
    ax4.set_ylabel('Mean Radiance (nW/cm²/sr)')
    ax4.set_xticks(range(1, 13))
    ax4.legend()
    ax4.grid(True, alpha=0.3)
    
    plt.tight_layout()
    
    return fig

def create_summary_statistics(df):
    """Generate summary statistics for the analysis"""
    
    print("\n" + "="*60)
    print("URBANIZATION ANALYSIS SUMMARY")
    print("="*60)
    
    for city in df['city'].unique():
        city_data = df[df['city'] == city]
        
        if len(city_data) > 1:
            # Calculate trends
            yearly_avg = city_data.groupby('year')['mean_radiance'].mean()
            first_year = yearly_avg.iloc[0]
            last_year = yearly_avg.iloc[-1]
            total_growth = ((last_year - first_year) / first_year) * 100
            annual_growth = (yearly_avg.iloc[-1] / yearly_avg.iloc[0]) ** (1 / (len(yearly_avg) - 1)) - 1
            
            print(f"\n{city.upper()} ({STUDY_LOCATIONS[city]['country']}):")
            print(f"  Study participants: {STUDY_LOCATIONS[city]['participants']:,}")
            print(f"  Analysis period: {yearly_avg.index.min()}-{yearly_avg.index.max()}")
            print(f"  Initial light intensity: {first_year:.2f} nW/cm²/sr")
            print(f"  Final light intensity: {last_year:.2f} nW/cm²/sr") 
            print(f"  Total growth: {total_growth:+.1f}%")
            print(f"  Average annual growth: {annual_growth*100:+.1f}%/year")
            print(f"  Peak intensity: {city_data['mean_radiance'].max():.2f} nW/cm²/sr")
        
    print("\n" + "="*60)

def main():
    """Main function to run the analysis"""
    
    print("Nighttime Lights Urbanization Analysis")
    print("Cities: Abidjan and Johannesburg")
    print("="*50)
    
    # Initialize Google Earth Engine
    if not initialize_gee():
        return
    
    # Create study areas
    print("Setting up study areas...")
    study_areas = create_study_areas()
    
    # Get nighttime lights data
    print("Loading nighttime lights data...")
    lights_collection = get_nighttime_lights_data(start_year=2012, end_year=2023)
    
    # Analyze urbanization trends
    df = create_time_series_analysis(study_areas, lights_collection)
    
    if len(df) == 0:
        print("No data retrieved. Please check your Google Earth Engine setup.")
        return
    
    # Save data
    df.to_csv('nighttime_lights_analysis.csv', index=False)
    print(f"Data saved to nighttime_lights_analysis.csv ({len(df)} records)")
    
    # Create interactive map
    interactive_map = create_interactive_maps(study_areas, lights_collection)
    interactive_map.to_html('urbanization_nighttime_lights_map.html')
    print("Interactive map saved as urbanization_nighttime_lights_map.html")
    
    # Create analysis charts
    fig = create_urbanization_charts(df)
    fig.savefig('urbanization_trends_analysis.png', dpi=300, bbox_inches='tight')
    fig.savefig('urbanization_trends_analysis.svg', bbox_inches='tight')
    fig.savefig('urbanization_trends_analysis.pdf', bbox_inches='tight')
    print("Analysis charts saved as urbanization_trends_analysis.png/svg/pdf")
    
    # Generate summary statistics
    create_summary_statistics(df)
    
    plt.show()
    
    print("\nAnalysis complete! Files generated:")
    print("  - urbanization_nighttime_lights_map.html (interactive map)")
    print("  - urbanization_trends_analysis.png/svg/pdf (charts)")
    print("  - nighttime_lights_analysis.csv (raw data)")

if __name__ == "__main__":
    main()