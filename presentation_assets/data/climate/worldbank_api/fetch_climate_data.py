#!/usr/bin/env python3
"""
World Bank Climate Change Knowledge Portal API Data Fetcher
Fetches climate data for Southern African countries
"""

import json
import os
import time
import requests
from typing import List, Dict, Optional
import pandas as pd
from datetime import datetime

# Southern African country codes (ISO3)
SOUTHERN_AFRICA_COUNTRIES = {
    "AGO": "Angola",
    "BWA": "Botswana",
    "COM": "Comoros",
    "SWZ": "Eswatini (Swaziland)",
    "LSO": "Lesotho",
    "MDG": "Madagascar",
    "MWI": "Malawi",
    "MUS": "Mauritius",
    "MOZ": "Mozambique",
    "NAM": "Namibia",
    "SYC": "Seychelles",
    "ZAF": "South Africa",
    "TZA": "Tanzania",
    "ZMB": "Zambia",
    "ZWE": "Zimbabwe"
}

# Major cities for analysis
SOUTHERN_AFRICA_CITIES = {
    "Johannesburg": "ZAF.2593214",  # South Africa
    "Cape Town": "ZAF.2593215",     # South Africa
    "Durban": "ZAF.2593217",        # South Africa
    "Luanda": "AGO.12001",          # Angola
    "Harare": "ZWE.21001",          # Zimbabwe
    "Lusaka": "ZMB.19001",          # Zambia
    "Maputo": "MOZ.14001",          # Mozambique
    "Windhoek": "NAM.15001",        # Namibia
    "Gaborone": "BWA.4001",         # Botswana
}

class ClimateDataFetcher:
    """Fetches climate data from World Bank Climate API"""
    
    BASE_URL = "https://cckpapi.worldbank.org/cckp/v1"
    
    def __init__(self, output_dir: str = "./data"):
        """Initialize the data fetcher"""
        self.output_dir = output_dir
        os.makedirs(output_dir, exist_ok=True)
        self.session = requests.Session()
        
    def fetch_historical_temperature(self, 
                                   geocode: str,
                                   aggregation: str = "annual",
                                   period: str = "1991-2020") -> Optional[Dict]:
        """
        Fetch historical temperature data (CRU TS dataset)
        
        Args:
            geocode: Country/city code
            aggregation: Time aggregation (annual, monthly)
            period: Time period (e.g., "1991-2020")
        """
        # CRU historical temperature endpoint
        endpoint = f"{self.BASE_URL}/cru-x0.5_climatology_tas,tasmax,tasmin_climatology_{aggregation}_{period}_mean_historical_mean/all/{geocode}"
        
        return self._make_request(endpoint)
    
    def fetch_historical_precipitation(self,
                                      geocode: str,
                                      aggregation: str = "annual",
                                      period: str = "1991-2020") -> Optional[Dict]:
        """
        Fetch historical precipitation data
        
        Args:
            geocode: Country/city code
            aggregation: Time aggregation
            period: Time period
        """
        # CRU historical precipitation endpoint
        endpoint = f"{self.BASE_URL}/cru-x0.5_climatology_pr_climatology_{aggregation}_{period}_mean_historical_mean/all/{geocode}"
        
        return self._make_request(endpoint)
    
    def fetch_future_projections(self,
                                geocode: str,
                                scenario: str = "ssp245",
                                period: str = "2040-2059",
                                variables: str = "tas,tasmax,tasmin,pr") -> Optional[Dict]:
        """
        Fetch future climate projections (CMIP6)
        
        Args:
            geocode: Country/city code
            scenario: SSP scenario (ssp119, ssp126, ssp245, ssp370, ssp585)
            period: Future period
            variables: Climate variables
        """
        # CMIP6 future projections endpoint
        endpoint = f"{self.BASE_URL}/cmip6-x0.25_climatology_{variables}_anomaly_annual_{period}_median_{scenario}_ensemble_all_mean/{geocode}"
        
        return self._make_request(endpoint)
    
    def fetch_extreme_indices(self,
                             geocode: str,
                             index: str = "rx5day",  # Max 5-day rainfall
                             scenario: str = "ssp245",
                             period: str = "2040-2059") -> Optional[Dict]:
        """
        Fetch climate extreme indices
        
        Args:
            geocode: Country/city code
            index: Extreme index (rx5day, tx90p, etc.)
            scenario: SSP scenario
            period: Future period
        """
        endpoint = f"{self.BASE_URL}/cmip6-x1.0_extremes_{index}_absolute_model-median_annual_{period}_mean_{scenario}_mean/all/{geocode}"
        
        return self._make_request(endpoint)
    
    def _make_request(self, endpoint: str, format: str = "json") -> Optional[Dict]:
        """Make API request with error handling"""
        try:
            url = f"{endpoint}?_format={format}"
            print(f"Fetching: {url}")
            
            response = self.session.get(url, timeout=30)
            response.raise_for_status()
            
            if format == "json":
                return response.json()
            else:
                return response.content
                
        except requests.exceptions.RequestException as e:
            print(f"Error fetching data: {e}")
            return None
        except json.JSONDecodeError as e:
            print(f"Error parsing JSON: {e}")
            return None
    
    def fetch_all_southern_africa(self):
        """Fetch climate data for all Southern African countries"""
        results = {}
        
        for code, name in SOUTHERN_AFRICA_COUNTRIES.items():
            print(f"\n{'='*50}")
            print(f"Fetching data for {name} ({code})")
            print(f"{'='*50}")
            
            country_data = {}
            
            # Fetch historical data
            print("Fetching historical temperature...")
            temp_hist = self.fetch_historical_temperature(code)
            if temp_hist:
                country_data['historical_temperature'] = temp_hist
            
            print("Fetching historical precipitation...")
            precip_hist = self.fetch_historical_precipitation(code)
            if precip_hist:
                country_data['historical_precipitation'] = precip_hist
            
            # Fetch future projections for different scenarios
            scenarios = ["ssp126", "ssp245", "ssp585"]
            periods = ["2040-2059", "2080-2099"]
            
            country_data['projections'] = {}
            
            for scenario in scenarios:
                for period in periods:
                    print(f"Fetching {scenario} projections for {period}...")
                    proj = self.fetch_future_projections(code, scenario, period)
                    if proj:
                        key = f"{scenario}_{period}"
                        country_data['projections'][key] = proj
            
            # Fetch extreme indices
            print("Fetching extreme indices...")
            extremes = self.fetch_extreme_indices(code)
            if extremes:
                country_data['extremes'] = extremes
            
            results[code] = country_data
            
            # Save intermediate results
            self.save_country_data(code, name, country_data)
            
            # Be nice to the API
            time.sleep(1)
        
        # Save combined results
        self.save_all_data(results)
        
        return results
    
    def fetch_city_data(self):
        """Fetch climate data for major Southern African cities"""
        results = {}
        
        for city, code in SOUTHERN_AFRICA_CITIES.items():
            print(f"\nFetching data for {city} ({code})")
            
            city_data = {}
            
            # Fetch temperature and precipitation
            temp = self.fetch_historical_temperature(code)
            if temp:
                city_data['temperature'] = temp
                
            precip = self.fetch_historical_precipitation(code)
            if precip:
                city_data['precipitation'] = precip
            
            results[city] = city_data
            
            # Save city data
            self.save_city_data(city, code, city_data)
            
            time.sleep(1)
        
        return results
    
    def save_country_data(self, code: str, name: str, data: Dict):
        """Save individual country data"""
        filename = os.path.join(self.output_dir, f"{code}_{name.replace(' ', '_')}.json")
        with open(filename, 'w') as f:
            json.dump(data, f, indent=2)
        print(f"Saved: {filename}")
    
    def save_city_data(self, city: str, code: str, data: Dict):
        """Save individual city data"""
        filename = os.path.join(self.output_dir, f"city_{city.replace(' ', '_')}.json")
        with open(filename, 'w') as f:
            json.dump(data, f, indent=2)
        print(f"Saved: {filename}")
    
    def save_all_data(self, data: Dict):
        """Save all combined data"""
        filename = os.path.join(self.output_dir, "southern_africa_climate_data.json")
        with open(filename, 'w') as f:
            json.dump(data, f, indent=2)
        print(f"\nSaved combined data: {filename}")
        
        # Also save as CSV for easier analysis
        self.export_to_csv(data)
    
    def export_to_csv(self, data: Dict):
        """Export data to CSV format for analysis"""
        rows = []
        
        for country_code, country_data in data.items():
            country_name = SOUTHERN_AFRICA_COUNTRIES.get(country_code, country_code)
            
            # Historical data
            if 'historical_temperature' in country_data:
                hist_temp = country_data['historical_temperature']
                # Extract relevant fields (this depends on actual API response structure)
                # This is a placeholder - adjust based on actual data structure
                
            # Projections
            if 'projections' in country_data:
                for scenario_period, proj_data in country_data['projections'].items():
                    # Extract projection data
                    pass
        
        # Create DataFrame and save
        if rows:
            df = pd.DataFrame(rows)
            csv_file = os.path.join(self.output_dir, "southern_africa_climate_summary.csv")
            df.to_csv(csv_file, index=False)
            print(f"Saved CSV: {csv_file}")


def main():
    """Main function to fetch all data"""
    print("World Bank Climate API Data Fetcher")
    print("=" * 50)
    
    # Create fetcher instance
    fetcher = ClimateDataFetcher(
        output_dir="./southern_africa_climate"
    )
    
    # Fetch country-level data
    print("\nFetching country-level data...")
    country_results = fetcher.fetch_all_southern_africa()
    
    # Fetch city-level data
    print("\nFetching city-level data...")
    city_results = fetcher.fetch_city_data()
    
    print("\n" + "=" * 50)
    print("Data fetching complete!")
    print(f"Country data fetched: {len(country_results)}")
    print(f"City data fetched: {len(city_results)}")
    
    # Print summary
    print("\nCountries processed:")
    for code, name in SOUTHERN_AFRICA_COUNTRIES.items():
        status = "✓" if code in country_results else "✗"
        print(f"  {status} {name} ({code})")
    
    print("\nCities processed:")
    for city in SOUTHERN_AFRICA_CITIES.keys():
        status = "✓" if city in city_results else "✗"
        print(f"  {status} {city}")


if __name__ == "__main__":
    main()