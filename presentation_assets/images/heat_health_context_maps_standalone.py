#!/usr/bin/env python3
"""
Standalone Heat Health Context Maps for Johannesburg and Abidjan
Generates comprehensive visualizations without requiring GEE authentication
"""

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from matplotlib.patches import Rectangle
from matplotlib.gridspec import GridSpec
import folium
from folium import plugins
import json
from datetime import datetime
import warnings
warnings.filterwarnings('ignore')

# Set style
plt.style.use('seaborn-v0_8-darkgrid')
sns.set_palette("husl")

class HeatHealthContextMapper:
    """Generate heat health context maps using simulated data"""
    
    def __init__(self):
        """Initialize with city data"""
        self.cities = {
            'Johannesburg': {
                'coords': [27.9, -26.3, 28.3, -26.0],
                'center': [28.0473, -26.2041],
                'zoom': 10,
                'population': 5782747,
                'area_km2': 1645,
                'elevation_m': 1753
            },
            'Abidjan': {
                'coords': [-4.2, 5.2, -3.8, 5.5],
                'center': [-4.0083, 5.3599],
                'zoom': 10,
                'population': 5616633,
                'area_km2': 2119,
                'elevation_m': 18
            }
        }
        
        self.results = {}
        
    def generate_synthetic_data(self, city: str, data_type: str, size: tuple = (100, 100)) -> np.ndarray:
        """Generate synthetic data for visualization"""
        
        np.random.seed(42 if city == 'Johannesburg' else 24)
        
        if data_type == 'temperature':
            # Generate realistic temperature patterns
            base_temp = 25 if city == 'Johannesburg' else 28
            urban_heat = np.random.normal(base_temp + 5, 3, size)
            gradient = np.linspace(0, 5, size[0]).reshape(-1, 1)
            return urban_heat + gradient
            
        elif data_type == 'ndvi':
            # Generate vegetation index
            urban_core = np.random.uniform(0.1, 0.3, size)
            parks = np.random.uniform(0.6, 0.8, (20, 20))
            # Add some green spaces
            for _ in range(5):
                x, y = np.random.randint(0, size[0]-20), np.random.randint(0, size[1]-20)
                urban_core[x:x+20, y:y+20] = parks
            return urban_core
            
        elif data_type == 'population':
            # Generate population density
            center = np.array(size) // 2
            y, x = np.ogrid[:size[0], :size[1]]
            mask = (x - center[1])**2 + (y - center[0])**2
            density = 1000 * np.exp(-mask / 5000)
            noise = np.random.normal(0, 50, size)
            return np.maximum(density + noise, 0)
            
        elif data_type == 'nightlights':
            # Generate nighttime lights pattern
            base = np.random.uniform(5, 15, size)
            # Add bright spots for commercial areas
            for _ in range(10):
                x, y = np.random.randint(10, size[0]-10), np.random.randint(10, size[1]-10)
                base[x-5:x+5, y-5:y+5] += np.random.uniform(20, 40)
            return np.clip(base, 0, 60)
            
        elif data_type == 'no2':
            # Generate NO2 patterns (higher near roads/industry)
            base = np.random.uniform(0.00005, 0.00015, size)
            # Add pollution hotspots
            for _ in range(8):
                x, y = np.random.randint(0, size[0]), np.random.randint(0, size[1])
                pollution = np.exp(-((np.arange(size[0])[:, None] - x)**2 + 
                                   (np.arange(size[1]) - y)**2) / 200)
                base += pollution * 0.00005
            return base
            
        elif data_type == 'impervious':
            # Generate impervious surface percentage
            urban = np.random.uniform(40, 80, size)
            # Add some less developed areas
            for _ in range(3):
                x, y = np.random.randint(0, size[0]-30), np.random.randint(0, size[1]-30)
                urban[x:x+30, y:y+30] = np.random.uniform(10, 30, (30, 30))
            return urban
            
    def calculate_heat_vulnerability_index(self, city: str) -> dict:
        """Calculate HVI from component layers"""
        
        size = (100, 100)
        
        # Generate component layers
        lst = self.generate_synthetic_data(city, 'temperature', size)
        ndvi = self.generate_synthetic_data(city, 'ndvi', size)
        population = self.generate_synthetic_data(city, 'population', size)
        impervious = self.generate_synthetic_data(city, 'impervious', size)
        
        # Normalize to 0-1
        lst_norm = (lst - lst.min()) / (lst.max() - lst.min())
        ndvi_norm = 1 - ((ndvi - ndvi.min()) / (ndvi.max() - ndvi.min()))  # Invert
        pop_norm = (population - population.min()) / (population.max() - population.min())
        imperv_norm = impervious / 100
        
        # Calculate weighted HVI
        weights = {
            'temperature': 0.3,
            'vegetation': 0.2,
            'population': 0.3,
            'impervious': 0.2
        }
        
        hvi = (lst_norm * weights['temperature'] +
               ndvi_norm * weights['vegetation'] +
               pop_norm * weights['population'] +
               imperv_norm * weights['impervious'])
        
        return {
            'hvi': hvi,
            'components': {
                'temperature': lst,
                'ndvi': ndvi,
                'population': population,
                'impervious': impervious
            },
            'normalized': {
                'lst_norm': lst_norm,
                'ndvi_norm': ndvi_norm,
                'pop_norm': pop_norm,
                'imperv_norm': imperv_norm
            },
            'weights': weights
        }
    
    def create_comprehensive_figure(self) -> plt.Figure:
        """Create comprehensive visualization of all analyses"""
        
        fig = plt.figure(figsize=(20, 24))
        gs = GridSpec(6, 4, figure=fig, hspace=0.3, wspace=0.3)
        
        # Color schemes
        cmaps = {
            'temperature': 'RdYlBu_r',
            'ndvi': 'RdYlGn',
            'population': 'YlOrRd',
            'nightlights': 'viridis',
            'no2': 'Reds',
            'impervious': 'Greys',
            'hvi': 'RdYlGn_r'
        }
        
        analyses = ['temperature', 'ndvi', 'population', 'nightlights', 'no2', 'impervious']
        
        for city_idx, city in enumerate(['Johannesburg', 'Abidjan']):
            # Generate all data
            data = {}
            for analysis in analyses:
                data[analysis] = self.generate_synthetic_data(city, analysis)
            
            # Calculate HVI
            hvi_data = self.calculate_heat_vulnerability_index(city)
            data['hvi'] = hvi_data['hvi']
            
            # Store results
            self.results[city] = {'data': data, 'hvi': hvi_data}
            
            # Plot each analysis
            for idx, analysis in enumerate(analyses + ['hvi']):
                row = idx // 2
                col = (idx % 2) * 2 + city_idx
                
                ax = fig.add_subplot(gs[row, col])
                
                im = ax.imshow(data[analysis], cmap=cmaps.get(analysis, 'viridis'), 
                              aspect='equal')
                
                # Add title
                if analysis == 'temperature':
                    title = f'{city}\nLand Surface Temp (°C)'
                elif analysis == 'ndvi':
                    title = f'{city}\nVegetation Index'
                elif analysis == 'population':
                    title = f'{city}\nPopulation Density'
                elif analysis == 'nightlights':
                    title = f'{city}\nNighttime Lights'
                elif analysis == 'no2':
                    title = f'{city}\nAir Quality (NO₂)'
                elif analysis == 'impervious':
                    title = f'{city}\nImpervious Surface %'
                elif analysis == 'hvi':
                    title = f'{city}\nHeat Vulnerability Index'
                
                ax.set_title(title, fontsize=10, fontweight='bold')
                ax.axis('off')
                
                # Add colorbar
                cbar = plt.colorbar(im, ax=ax, fraction=0.046, pad=0.04)
                cbar.ax.tick_params(labelsize=8)
                
                # Add value labels for HVI
                if analysis == 'hvi':
                    cbar.set_label('Vulnerability', rotation=270, labelpad=15, fontsize=8)
        
        # Add comparison statistics at the bottom
        ax_stats = fig.add_subplot(gs[4:, :])
        ax_stats.axis('off')
        
        # Create statistics table
        stats_data = []
        for city in ['Johannesburg', 'Abidjan']:
            city_data = self.results[city]['data']
            hvi_data = self.results[city]['hvi']['hvi']
            
            stats_data.append([
                city,
                f"{city_data['temperature'].mean():.1f}°C",
                f"{city_data['ndvi'].mean():.2f}",
                f"{city_data['population'].mean():.0f}/km²",
                f"{city_data['nightlights'].mean():.1f}",
                f"{city_data['no2'].mean()*1e6:.1f}",
                f"{city_data['impervious'].mean():.0f}%",
                f"{hvi_data.mean():.2f}"
            ])
        
        columns = ['City', 'Avg Temp', 'Avg NDVI', 'Pop Density', 
                  'Night Lights', 'NO₂ (×10⁻⁶)', 'Impervious', 'Avg HVI']
        
        table = ax_stats.table(cellText=stats_data, colLabels=columns,
                              cellLoc='center', loc='center',
                              colWidths=[0.12]*8)
        table.auto_set_font_size(False)
        table.set_fontsize(10)
        table.scale(1, 2)
        
        # Style the table
        for i in range(len(columns)):
            table[(0, i)].set_facecolor('#4CAF50')
            table[(0, i)].set_text_props(weight='bold', color='white')
        
        # Add main title
        fig.suptitle('Heat Health Context Analysis: Johannesburg vs Abidjan', 
                    fontsize=16, fontweight='bold', y=0.98)
        
        # Add subtitle
        fig.text(0.5, 0.96, 'Comprehensive Environmental and Demographic Factors for Heat Health Assessment',
                ha='center', fontsize=12, style='italic')
        
        return fig
    
    def create_hvi_comparison_plot(self) -> plt.Figure:
        """Create detailed HVI comparison"""
        
        fig, axes = plt.subplots(2, 3, figsize=(15, 10))
        fig.suptitle('Heat Vulnerability Index Components Comparison', fontsize=14, fontweight='bold')
        
        for city_idx, city in enumerate(['Johannesburg', 'Abidjan']):
            hvi_data = self.calculate_heat_vulnerability_index(city)
            
            # Plot HVI
            ax = axes[city_idx, 0]
            im = ax.imshow(hvi_data['hvi'], cmap='RdYlGn_r', vmin=0, vmax=1)
            ax.set_title(f'{city} - Combined HVI')
            ax.axis('off')
            plt.colorbar(im, ax=ax, fraction=0.046)
            
            # Plot component contributions
            ax = axes[city_idx, 1]
            components = ['Temperature', 'Vegetation', 'Population', 'Impervious']
            weights = [hvi_data['weights']['temperature'], 
                      hvi_data['weights']['vegetation'],
                      hvi_data['weights']['population'], 
                      hvi_data['weights']['impervious']]
            colors = ['#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4']
            
            ax.pie(weights, labels=components, colors=colors, autopct='%1.0f%%',
                  startangle=90)
            ax.set_title(f'{city} - Component Weights')
            
            # Plot vulnerability distribution
            ax = axes[city_idx, 2]
            ax.hist(hvi_data['hvi'].flatten(), bins=30, color='#FF6B6B', alpha=0.7, edgecolor='black')
            ax.axvline(hvi_data['hvi'].mean(), color='red', linestyle='--', label=f'Mean: {hvi_data["hvi"].mean():.2f}')
            ax.set_xlabel('Vulnerability Score')
            ax.set_ylabel('Frequency')
            ax.set_title(f'{city} - HVI Distribution')
            ax.legend()
            ax.grid(True, alpha=0.3)
        
        plt.tight_layout()
        return fig
    
    def create_interactive_map(self, city: str) -> folium.Map:
        """Create interactive Folium map with heat zones"""
        
        center = self.cities[city]['center']
        m = folium.Map(location=[center[1], center[0]], zoom_start=11)
        
        # Add base layers
        folium.TileLayer('cartodbpositron').add_to(m)
        folium.TileLayer('cartodbdark_matter').add_to(m)
        
        # Generate heat zones (simulated)
        np.random.seed(42 if city == 'Johannesburg' else 24)
        
        # Create heat map data
        heat_data = []
        for _ in range(100):
            lat = center[1] + np.random.normal(0, 0.05)
            lon = center[0] + np.random.normal(0, 0.05)
            intensity = np.random.uniform(0.3, 1.0)
            heat_data.append([lat, lon, intensity])
        
        # Add heat map
        plugins.HeatMap(heat_data, name='Heat Vulnerability').add_to(m)
        
        # Add markers for key areas
        high_risk_areas = [
            {'name': 'CBD', 'offset': [0, 0], 'risk': 'High'},
            {'name': 'Industrial Zone', 'offset': [0.05, 0.03], 'risk': 'Very High'},
            {'name': 'Residential Area', 'offset': [-0.04, 0.02], 'risk': 'Medium'},
            {'name': 'Green Belt', 'offset': [0.02, -0.05], 'risk': 'Low'},
        ]
        
        for area in high_risk_areas:
            lat = center[1] + area['offset'][0]
            lon = center[0] + area['offset'][1]
            
            color = {'Low': 'green', 'Medium': 'orange', 'High': 'red', 'Very High': 'darkred'}[area['risk']]
            
            folium.CircleMarker(
                location=[lat, lon],
                radius=10,
                popup=f"{area['name']}<br>Risk Level: {area['risk']}",
                color=color,
                fill=True,
                fillColor=color,
                fillOpacity=0.6
            ).add_to(m)
        
        # Add city boundary
        bounds = self.cities[city]['coords']
        folium.Rectangle(
            bounds=[[bounds[1], bounds[0]], [bounds[3], bounds[2]]],
            color='blue',
            weight=2,
            fill=False,
            popup=f'{city} Study Area'
        ).add_to(m)
        
        # Add layer control
        folium.LayerControl().add_to(m)
        
        # Add title
        title_html = f'''
        <h3 align="center" style="font-size:20px"><b>{city} Heat Vulnerability Map</b></h3>
        '''
        m.get_root().html.add_child(folium.Element(title_html))
        
        return m
    
    def generate_report(self) -> str:
        """Generate text report of findings"""
        
        report = []
        report.append("="*60)
        report.append("HEAT HEALTH CONTEXT ANALYSIS REPORT")
        report.append("="*60)
        report.append(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        
        for city in self.cities.keys():
            if city not in self.results:
                continue
                
            report.append(f"\n{city.upper()}")
            report.append("-"*40)
            
            data = self.results[city]['data']
            hvi = self.results[city]['hvi']['hvi']
            
            # Calculate statistics
            stats = {
                'Mean Temperature': f"{data['temperature'].mean():.1f}°C",
                'Max Temperature': f"{data['temperature'].max():.1f}°C",
                'Mean NDVI': f"{data['ndvi'].mean():.3f}",
                'Population Density': f"{data['population'].mean():.0f} per km²",
                'Impervious Surface': f"{data['impervious'].mean():.0f}%",
                'Mean HVI': f"{hvi.mean():.3f}",
                'Max HVI': f"{hvi.max():.3f}",
                'High Risk Areas (>0.7)': f"{(hvi > 0.7).sum() / hvi.size * 100:.1f}%"
            }
            
            for key, value in stats.items():
                report.append(f"  {key}: {value}")
            
            # Key findings
            report.append(f"\nKey Findings for {city}:")
            if hvi.mean() > 0.6:
                report.append("  • HIGH overall heat vulnerability detected")
            elif hvi.mean() > 0.4:
                report.append("  • MODERATE overall heat vulnerability detected")
            else:
                report.append("  • LOW overall heat vulnerability detected")
            
            if data['ndvi'].mean() < 0.3:
                report.append("  • Limited vegetation coverage increases heat risk")
            
            if data['impervious'].mean() > 60:
                report.append("  • High impervious surface percentage contributes to UHI effect")
        
        report.append("\n" + "="*60)
        report.append("RECOMMENDATIONS")
        report.append("="*60)
        report.append("1. Focus interventions on high HVI areas (red zones)")
        report.append("2. Increase green infrastructure in urban cores")
        report.append("3. Implement cool roof programs in dense areas")
        report.append("4. Establish cooling centers in high-risk neighborhoods")
        report.append("5. Develop early warning systems for heat events")
        
        return "\n".join(report)

def main():
    """Main execution function"""
    
    print("="*60)
    print("Heat Health Context Mapper - Standalone Version")
    print("Analyzing Johannesburg and Abidjan")
    print("="*60)
    
    # Initialize mapper
    mapper = HeatHealthContextMapper()
    
    # Create comprehensive figure
    print("\nGenerating comprehensive analysis figure...")
    fig1 = mapper.create_comprehensive_figure()
    fig1.savefig('heat_health_comprehensive_analysis.png', dpi=150, bbox_inches='tight')
    print("✓ Saved: heat_health_comprehensive_analysis.png")
    
    # Create HVI comparison
    print("\nGenerating HVI component analysis...")
    fig2 = mapper.create_hvi_comparison_plot()
    fig2.savefig('hvi_component_comparison.png', dpi=150, bbox_inches='tight')
    print("✓ Saved: hvi_component_comparison.png")
    
    # Create interactive maps
    print("\nGenerating interactive maps...")
    for city in mapper.cities.keys():
        m = mapper.create_interactive_map(city)
        filename = f'{city.lower()}_interactive_hvi_map.html'
        m.save(filename)
        print(f"✓ Saved: {filename}")
    
    # Generate report
    print("\nGenerating analysis report...")
    report = mapper.generate_report()
    with open('heat_health_analysis_report.txt', 'w') as f:
        f.write(report)
    print("✓ Saved: heat_health_analysis_report.txt")
    
    # Save data as JSON
    print("\nSaving analysis data...")
    output_data = {}
    for city in mapper.results:
        output_data[city] = {
            'hvi_mean': float(mapper.results[city]['hvi']['hvi'].mean()),
            'hvi_max': float(mapper.results[city]['hvi']['hvi'].max()),
            'hvi_min': float(mapper.results[city]['hvi']['hvi'].min()),
            'weights': mapper.results[city]['hvi']['weights']
        }
    
    with open('heat_health_analysis_data.json', 'w') as f:
        json.dump(output_data, f, indent=2)
    print("✓ Saved: heat_health_analysis_data.json")
    
    # Print summary
    print("\n" + "="*60)
    print("ANALYSIS COMPLETE!")
    print("="*60)
    print("\nGenerated files:")
    print("  • heat_health_comprehensive_analysis.png - All analyses visualization")
    print("  • hvi_component_comparison.png - HVI component breakdown")
    print("  • johannesburg_interactive_hvi_map.html - Interactive map")
    print("  • abidjan_interactive_hvi_map.html - Interactive map")
    print("  • heat_health_analysis_report.txt - Detailed report")
    print("  • heat_health_analysis_data.json - Analysis data")
    print("\n" + "="*60)

if __name__ == "__main__":
    main()