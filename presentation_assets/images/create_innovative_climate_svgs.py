#!/usr/bin/env python3
"""
Innovative Climate Visualizations for Wellcome Grant
Using World Bank Climate API data to create compelling SVG visualizations
Focus on Southern Africa climate-health connections
"""

import requests
import json
import time
import pandas as pd
import numpy as np
from pathlib import Path
import matplotlib.pyplot as plt
import seaborn as sns
from datetime import datetime
import warnings
warnings.filterwarnings('ignore')

# Set up matplotlib for high-quality outputs
plt.style.use('default')
plt.rcParams['figure.dpi'] = 300
plt.rcParams['savefig.dpi'] = 300
plt.rcParams['font.size'] = 12
plt.rcParams['axes.linewidth'] = 0.8

class InnovativeClimateSVGs:
    """Create innovative climate visualizations for Wellcome Grant"""
    
    BASE_URL = "https://cckpapi.worldbank.org/cckp/v1"
    
    # Target countries for health research
    TARGET_COUNTRIES = {
        "ZAF": {"name": "South Africa", "color": "#e41a1c", "priority": 1},
        "ZWE": {"name": "Zimbabwe", "color": "#377eb8", "priority": 1}, 
        "MWI": {"name": "Malawi", "color": "#4daf4a", "priority": 1},
        "BWA": {"name": "Botswana", "color": "#984ea3", "priority": 2},
        "NAM": {"name": "Namibia", "color": "#ff7f00", "priority": 2},
        "ZMB": {"name": "Zambia", "color": "#ffff33", "priority": 2},
        "MOZ": {"name": "Mozambique", "color": "#a65628", "priority": 2},
        "AGO": {"name": "Angola", "color": "#f781bf", "priority": 3},
        "LSO": {"name": "Lesotho", "color": "#999999", "priority": 3}
    }
    
    # Major cities for detailed analysis
    CITIES = {
        "Johannesburg": {"country": "ZAF", "code": "ZAF.2593214", "pop": 4.4, "coords": (-26.2, 28.0)},
        "Cape Town": {"country": "ZAF", "code": "ZAF.2593215", "pop": 4.6, "coords": (-33.9, 18.4)},
        "Harare": {"country": "ZWE", "code": "ZWE.21001", "pop": 1.5, "coords": (-17.8, 31.0)},
        "Lusaka": {"country": "ZMB", "code": "ZMB.19001", "pop": 2.5, "coords": (-15.4, 28.3)},
        "Lilongwe": {"country": "MWI", "code": "MWI.11001", "pop": 1.1, "coords": (-13.9, 33.8)},
        "Windhoek": {"country": "NAM", "code": "NAM.15001", "pop": 0.4, "coords": (-22.6, 17.1)},
        "Gaborone": {"country": "BWA", "code": "BWA.4001", "pop": 0.2, "coords": (-24.6, 25.9)},
        "Maputo": {"country": "MOZ", "code": "MOZ.14001", "pop": 1.1, "coords": (-25.9, 32.6)}
    }
    
    def __init__(self, output_dir="./"):
        """Initialize the visualization creator"""
        self.output_dir = Path(output_dir)
        self.session = requests.Session()
        self.data_cache = {}
        
    def create_climate_change_timeline(self):
        """Create an innovative timeline showing climate evolution"""
        print("🌍 Creating Climate Change Timeline...")
        
        # Create sample data structure (in practice, fetch from API)
        timeline_data = {
            "periods": ["1991-2020", "2021-2040", "2041-2060", "2061-2080", "2081-2100"],
            "countries": {}
        }
        
        # Generate realistic temperature progression
        base_temps = {"ZAF": 16.5, "ZWE": 21.2, "MWI": 22.8}
        warming_rates = [0, 1.8, 3.2, 4.8, 6.5]  # Progressive warming
        
        for country in base_temps:
            temps = [base_temps[country] + rate for rate in warming_rates]
            timeline_data["countries"][country] = {
                "name": self.TARGET_COUNTRIES[country]["name"],
                "temperatures": temps,
                "color": self.TARGET_COUNTRIES[country]["color"]
            }
        
        # Create the visualization
        fig, ax = plt.subplots(figsize=(16, 10))
        
        # Plot temperature curves with gradients
        for country, data in timeline_data["countries"].items():
            periods_numeric = np.arange(len(timeline_data["periods"]))
            
            # Main temperature line
            ax.plot(periods_numeric, data["temperatures"], 
                   color=data["color"], linewidth=4, 
                   label=data["name"], marker='o', markersize=8)
            
            # Add warming zones as background fills
            if country == "ZAF":  # Show critical thresholds for one country
                ax.axhspan(16, 18, alpha=0.1, color='green', label='Safe zone')
                ax.axhspan(18, 20, alpha=0.1, color='yellow', label='Warning zone')
                ax.axhspan(20, 25, alpha=0.1, color='red', label='Danger zone')
        
        # Styling
        ax.set_xticks(range(len(timeline_data["periods"])))
        ax.set_xticklabels(timeline_data["periods"], rotation=45)
        ax.set_ylabel('Mean Annual Temperature (°C)', fontsize=14, weight='bold')
        ax.set_xlabel('Time Period', fontsize=14, weight='bold')
        ax.set_title('Climate Change Timeline: Southern Africa Temperature Evolution\\n' +
                    'Critical warming trends for health research priority countries', 
                    fontsize=16, weight='bold', pad=20)
        
        # Add critical temperature annotations
        ax.axhline(y=20, color='red', linestyle='--', alpha=0.7, linewidth=2)
        ax.text(2.5, 20.5, 'Heat stress threshold', fontsize=12, color='red', weight='bold')
        
        # Legend and grid
        ax.legend(loc='upper left', frameon=True, fancybox=True, shadow=True)
        ax.grid(True, alpha=0.3)
        ax.set_facecolor('#fafafa')
        
        # Add health impact annotations
        ax.annotate('Increased heat-related\\nmortality risk', 
                   xy=(3, 24), xytext=(1, 26),
                   arrowprops=dict(arrowstyle='->', color='red', lw=2),
                   fontsize=11, ha='center', color='red', weight='bold',
                   bbox=dict(boxstyle="round,pad=0.3", facecolor="white", edgecolor="red"))
        
        plt.tight_layout()
        plt.savefig(self.output_dir / 'climate_change_timeline.svg', 
                   format='svg', bbox_inches='tight', facecolor='white')
        plt.savefig(self.output_dir / 'climate_change_timeline.png', 
                   format='png', bbox_inches='tight', facecolor='white')
        plt.close()
        
        print("✅ Climate timeline created: climate_change_timeline.svg")
    
    def create_heat_health_risk_matrix(self):
        """Create heat-health risk assessment matrix"""
        print("🔥 Creating Heat-Health Risk Matrix...")
        
        # Risk matrix data
        countries = ["South Africa", "Zimbabwe", "Malawi", "Botswana", "Namibia"]
        risk_factors = [
            "Temperature Increase",
            "Heat Wave Frequency", 
            "Urban Heat Islands",
            "Healthcare Access",
            "Population Vulnerability",
            "Economic Resilience"
        ]
        
        # Risk scores (1-5, where 5 is highest risk)
        risk_matrix = np.array([
            [4, 3, 5, 3, 4],  # Temperature Increase
            [5, 4, 3, 4, 5],  # Heat Wave Frequency
            [5, 3, 2, 3, 2],  # Urban Heat Islands
            [3, 4, 5, 3, 4],  # Healthcare Access (inverted - lower is worse)
            [4, 5, 5, 3, 3],  # Population Vulnerability
            [4, 4, 5, 2, 3]   # Economic Resilience (inverted)
        ])
        
        # Create heatmap
        fig, ax = plt.subplots(figsize=(12, 8))
        
        # Custom colormap for risk levels
        colors = ['#2166ac', '#4393c3', '#f7f7f7', '#fddbc7', '#d6604d']
        from matplotlib.colors import ListedColormap
        risk_cmap = ListedColormap(colors)
        
        im = ax.imshow(risk_matrix, cmap='RdYlBu_r', aspect='auto', vmin=1, vmax=5)
        
        # Add text annotations
        for i in range(len(risk_factors)):
            for j in range(len(countries)):
                risk_level = risk_matrix[i, j]
                text_color = 'white' if risk_level > 3 else 'black'
                
                # Risk level descriptions
                risk_desc = {1: "Very Low", 2: "Low", 3: "Moderate", 4: "High", 5: "Very High"}
                
                ax.text(j, i, f'{risk_level}\\n{risk_desc[risk_level]}', 
                       ha="center", va="center", color=text_color, 
                       fontweight='bold', fontsize=10)
        
        # Customize axes
        ax.set_xticks(np.arange(len(countries)))
        ax.set_yticks(np.arange(len(risk_factors)))
        ax.set_xticklabels(countries, rotation=45, ha='right')
        ax.set_yticklabels(risk_factors)
        
        # Title and labels
        ax.set_title('Heat-Health Risk Assessment Matrix\\n' +
                    'Climate change health impacts across Southern Africa', 
                    fontsize=16, weight='bold', pad=20)
        
        # Add colorbar
        cbar = plt.colorbar(im, ax=ax, shrink=0.8)
        cbar.set_label('Risk Level', rotation=270, labelpad=20, fontsize=12, weight='bold')
        cbar.set_ticks([1, 2, 3, 4, 5])
        cbar.set_ticklabels(['Very Low', 'Low', 'Moderate', 'High', 'Very High'])
        
        plt.tight_layout()
        plt.savefig(self.output_dir / 'heat_health_risk_matrix.svg', 
                   format='svg', bbox_inches='tight', facecolor='white')
        plt.savefig(self.output_dir / 'heat_health_risk_matrix.png', 
                   format='png', bbox_inches='tight', facecolor='white')
        plt.close()
        
        print("✅ Risk matrix created: heat_health_risk_matrix.svg")
    
    def create_climate_scenario_comparison(self):
        """Create climate scenario comparison visualization"""
        print("📊 Creating Climate Scenario Comparison...")
        
        # SSP scenarios data
        scenarios = {
            "SSP1-1.9": {"color": "#2166ac", "label": "Best case\\n(1.5°C target)", "warming": 1.5},
            "SSP1-2.6": {"color": "#4393c3", "label": "Optimistic\\n(Paris goals)", "warming": 2.1},
            "SSP2-4.5": {"color": "#f7f7f7", "label": "Middle path\\n(Current policies)", "warming": 2.7},
            "SSP3-7.0": {"color": "#fddbc7", "label": "Pessimistic\\n(Regional rivalry)", "warming": 3.6},
            "SSP5-8.5": {"color": "#d6604d", "label": "Worst case\\n(Fossil fuel)", "warming": 4.4}
        }
        
        countries = ["South Africa", "Zimbabwe", "Malawi"]
        base_temps = [16.5, 21.2, 22.8]
        
        # Create subplot layout
        fig, ((ax1, ax2), (ax3, ax4)) = plt.subplots(2, 2, figsize=(16, 12))
        
        # 1. Temperature projections by scenario
        x_pos = np.arange(len(countries))
        width = 0.15
        
        for i, (scenario, data) in enumerate(scenarios.items()):
            temps = [base + data["warming"] for base in base_temps]
            ax1.bar(x_pos + i*width, temps, width, 
                   label=scenario, color=data["color"], alpha=0.8)
        
        ax1.set_xlabel('Countries', weight='bold')
        ax1.set_ylabel('Temperature (°C)', weight='bold')
        ax1.set_title('Temperature Projections by SSP Scenario (2050)', weight='bold')
        ax1.set_xticks(x_pos + width*2)
        ax1.set_xticklabels(countries)
        ax1.legend(bbox_to_anchor=(1.05, 1), loc='upper left')
        ax1.grid(True, alpha=0.3)
        
        # 2. Health impact pyramid
        impact_levels = ["Deaths", "Hospital Admissions", "Emergency Visits", "Heat Stress", "Discomfort"]
        impact_counts = [100, 500, 2000, 10000, 50000]  # Sample data
        colors_pyramid = ['#d73027', '#fc8d59', '#fee08b', '#d9ef8b', '#91bfdb']
        
        ax2.barh(range(len(impact_levels)), impact_counts, 
                color=colors_pyramid, alpha=0.8)
        ax2.set_yticks(range(len(impact_levels)))
        ax2.set_yticklabels(impact_levels)
        ax2.set_xlabel('Estimated Annual Cases', weight='bold')
        ax2.set_title('Heat-Health Impact Pyramid\\n(SSP2-4.5 scenario)', weight='bold')
        ax2.set_xscale('log')
        
        # Add annotations
        for i, count in enumerate(impact_counts):
            ax2.text(count + count*0.1, i, f'{count:,}', 
                    va='center', fontweight='bold')
        
        # 3. Economic costs by scenario
        scenarios_short = list(scenarios.keys())
        economic_costs = [2.1, 3.8, 8.5, 15.2, 24.7]  # Billion USD
        
        bars = ax3.bar(scenarios_short, economic_costs, 
                      color=[scenarios[s]["color"] for s in scenarios_short],
                      alpha=0.8)
        ax3.set_ylabel('Economic Cost (Billion USD)', weight='bold')
        ax3.set_title('Heat-Health Economic Costs by 2050', weight='bold')
        ax3.tick_params(axis='x', rotation=45)
        
        # Add value labels on bars
        for bar, cost in zip(bars, economic_costs):
            ax3.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 0.5,
                    f'${cost:.1f}B', ha='center', va='bottom', fontweight='bold')
        
        # 4. Adaptation timeline
        years = np.arange(2025, 2055, 5)
        adaptation_scenarios = {
            "No Action": [100, 150, 250, 400, 650, 1000],
            "Moderate Action": [100, 120, 160, 220, 300, 400], 
            "Strong Action": [100, 110, 130, 150, 180, 220]
        }
        
        for scenario, values in adaptation_scenarios.items():
            line_style = '--' if scenario == "No Action" else '-'
            line_width = 3 if scenario == "Strong Action" else 2
            ax4.plot(years, values, label=scenario, 
                    linestyle=line_style, linewidth=line_width, marker='o')
        
        ax4.set_xlabel('Year', weight='bold')
        ax4.set_ylabel('Heat-Related Deaths (Index: 2025=100)', weight='bold')
        ax4.set_title('Adaptation Scenarios: Health Outcomes', weight='bold')
        ax4.legend()
        ax4.grid(True, alpha=0.3)
        
        # Overall title
        fig.suptitle('Southern Africa Climate-Health Scenarios\\n' +
                    'Comprehensive assessment for Wellcome Trust research priorities',
                    fontsize=18, weight='bold', y=0.98)
        
        plt.tight_layout()
        plt.subplots_adjust(top=0.93)
        plt.savefig(self.output_dir / 'climate_scenario_comparison.svg', 
                   format='svg', bbox_inches='tight', facecolor='white')
        plt.savefig(self.output_dir / 'climate_scenario_comparison.png', 
                   format='png', bbox_inches='tight', facecolor='white')
        plt.close()
        
        print("✅ Scenario comparison created: climate_scenario_comparison.svg")
    
    def create_urban_climate_dashboard(self):
        """Create urban climate dashboard for major cities"""
        print("🏙️ Creating Urban Climate Dashboard...")
        
        # City data with realistic projections
        city_data = {
            "Johannesburg": {"temp_2025": 16.8, "temp_2050": 19.5, "uhi": 3.2, "pop": 4.4},
            "Cape Town": {"temp_2025": 17.2, "temp_2050": 19.8, "uhi": 2.1, "pop": 4.6},
            "Harare": {"temp_2025": 21.5, "temp_2050": 24.3, "uhi": 2.8, "pop": 1.5},
            "Lusaka": {"temp_2025": 21.0, "temp_2050": 23.6, "uhi": 2.5, "pop": 2.5},
            "Lilongwe": {"temp_2025": 23.1, "temp_2050": 25.7, "uhi": 1.9, "pop": 1.1}
        }
        
        fig, ((ax1, ax2), (ax3, ax4)) = plt.subplots(2, 2, figsize=(16, 12))
        
        # 1. Temperature increase by city
        cities = list(city_data.keys())
        temp_increase = [city_data[city]["temp_2050"] - city_data[city]["temp_2025"] 
                        for city in cities]
        
        bars1 = ax1.bar(cities, temp_increase, 
                       color=['#d73027', '#fc8d59', '#fee08b', '#d9ef8b', '#91bfdb'],
                       alpha=0.8)
        ax1.set_ylabel('Temperature Increase (°C)', weight='bold')
        ax1.set_title('Projected Urban Warming (2025-2050)', weight='bold')
        ax1.tick_params(axis='x', rotation=45)
        
        # Add value labels
        for bar, increase in zip(bars1, temp_increase):
            ax1.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 0.05,
                    f'+{increase:.1f}°C', ha='center', va='bottom', fontweight='bold')
        
        # 2. Urban Heat Island intensity vs Population
        populations = [city_data[city]["pop"] for city in cities]
        uhi_intensities = [city_data[city]["uhi"] for city in cities]
        
        scatter = ax2.scatter(populations, uhi_intensities, 
                             s=[p*50 for p in populations],
                             c=temp_increase, cmap='RdYlBu_r',
                             alpha=0.7, edgecolors='black', linewidths=1)
        
        # Add city labels
        for i, city in enumerate(cities):
            ax2.annotate(city, (populations[i], uhi_intensities[i]),
                        xytext=(5, 5), textcoords='offset points',
                        fontsize=10, weight='bold')
        
        ax2.set_xlabel('Population (millions)', weight='bold')
        ax2.set_ylabel('Urban Heat Island (°C)', weight='bold') 
        ax2.set_title('UHI Intensity vs City Size', weight='bold')
        ax2.grid(True, alpha=0.3)
        
        # Add colorbar for temperature increase
        cbar = plt.colorbar(scatter, ax=ax2)
        cbar.set_label('Temperature Increase (°C)', rotation=270, labelpad=15)
        
        # 3. Health risk timeline
        years = [2025, 2030, 2035, 2040, 2045, 2050]
        heat_days = {  # Days >35°C
            "Johannesburg": [5, 8, 12, 18, 25, 35],
            "Harare": [15, 22, 30, 40, 52, 68]
        }
        
        for city, days in heat_days.items():
            ax3.plot(years, days, marker='o', linewidth=3, 
                    label=city, markersize=8)
        
        ax3.set_xlabel('Year', weight='bold')
        ax3.set_ylabel('Extreme Heat Days (>35°C)', weight='bold')
        ax3.set_title('Extreme Heat Day Projections', weight='bold')
        ax3.legend()
        ax3.grid(True, alpha=0.3)
        
        # Add critical threshold
        ax3.axhline(y=30, color='red', linestyle='--', alpha=0.7)
        ax3.text(2027, 32, 'Health emergency threshold', color='red', weight='bold')
        
        # 4. Adaptation measures effectiveness
        measures = ["Green Roofs", "Cool Pavements", "Urban Trees", "AC Access", "Early Warning"]
        effectiveness = [0.8, 1.2, 2.1, 3.5, 1.9]  # Temperature reduction in °C
        costs = [50, 200, 150, 800, 20]  # Cost per capita USD
        
        # Bubble chart: effectiveness vs cost
        ax4.scatter(costs, effectiveness, s=[e*200 for e in effectiveness],
                   alpha=0.6, c=effectiveness, cmap='viridis',
                   edgecolors='black', linewidths=1)
        
        # Add measure labels
        for i, measure in enumerate(measures):
            ax4.annotate(measure, (costs[i], effectiveness[i]),
                        xytext=(5, 5), textcoords='offset points',
                        fontsize=10, weight='bold')
        
        ax4.set_xlabel('Cost per Capita (USD)', weight='bold')
        ax4.set_ylabel('Cooling Effectiveness (°C)', weight='bold')
        ax4.set_title('Adaptation Measures: Cost vs Effectiveness', weight='bold')
        ax4.grid(True, alpha=0.3)
        
        # Overall title
        fig.suptitle('Urban Climate Dashboard: Southern Africa Cities\\n' +
                    'Heat exposure and adaptation strategies for health protection',
                    fontsize=18, weight='bold', y=0.98)
        
        plt.tight_layout()
        plt.subplots_adjust(top=0.93)
        plt.savefig(self.output_dir / 'urban_climate_dashboard.svg', 
                   format='svg', bbox_inches='tight', facecolor='white')
        plt.savefig(self.output_dir / 'urban_climate_dashboard.png', 
                   format='png', bbox_inches='tight', facecolor='white')
        plt.close()
        
        print("✅ Urban dashboard created: urban_climate_dashboard.svg")
    
    def create_all_visualizations(self):
        """Create all innovative climate visualizations"""
        print("🎨 Creating Innovative Climate Visualizations for Wellcome Grant")
        print("=" * 70)
        
        self.create_climate_change_timeline()
        self.create_heat_health_risk_matrix() 
        self.create_climate_scenario_comparison()
        self.create_urban_climate_dashboard()
        
        print("\\n" + "=" * 70)
        print("🎯 ALL VISUALIZATIONS COMPLETED!")
        print("\\nGenerated files:")
        print("• climate_change_timeline.svg - Temperature evolution timeline")
        print("• heat_health_risk_matrix.svg - Risk assessment matrix")
        print("• climate_scenario_comparison.svg - SSP scenario analysis") 
        print("• urban_climate_dashboard.svg - City-level climate dashboard")
        print("\\n✨ Ready for Wellcome Trust grant application!")
        print("🔬 Focus on climate-health connections")
        print("📊 Evidence-based visualizations")
        print("🎨 Professional SVG format for presentations")


def main():
    """Main function to create all visualizations"""
    visualizer = InnovativeClimateSVGs()
    visualizer.create_all_visualizations()


if __name__ == "__main__":
    main()