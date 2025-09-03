#!/usr/bin/env python3
"""
Quick test of World Bank Climate API
Tests a simple call to verify the API is working
"""

import requests
import json

def test_api():
    """Test the World Bank Climate API with a simple call"""
    
    # Test endpoint - Historical temperature for South Africa
    url = "https://cckpapi.worldbank.org/cckp/v1/cru-x0.5_climatology_tas_climatology_annual_1991-2020_mean_historical_mean/all/ZAF"
    
    print("Testing World Bank Climate API...")
    print(f"URL: {url}")
    print("-" * 50)
    
    try:
        response = requests.get(url, params={"_format": "json"}, timeout=30)
        response.raise_for_status()
        
        data = response.json()
        
        print("✓ API call successful!")
        
        # Handle different response formats
        if isinstance(data, list):
            print(f"✓ Response contains {len(data)} records")
            if data:
                first_record = data[0]
                print("\nSample data (first record):")
                print(json.dumps(first_record, indent=2)[:500] + "...")
        elif isinstance(data, dict):
            print(f"✓ Response contains dictionary with {len(data)} keys")
            print(f"✓ Keys: {', '.join(list(data.keys())[:10])}")
            print("\nSample data structure:")
            sample = {k: str(type(v)) for k, v in list(data.items())[:5]}
            print(json.dumps(sample, indent=2))
        else:
            print(f"✓ Response type: {type(data)}")
        
        # Save test data
        with open("test_api_response.json", "w") as f:
            json.dump(data, f, indent=2)
        print("\n✓ Full response saved to test_api_response.json")
        
        return True
        
    except requests.exceptions.RequestException as e:
        print(f"✗ API call failed: {e}")
        return False
    except json.JSONDecodeError as e:
        print(f"✗ Failed to parse JSON response: {e}")
        return False

if __name__ == "__main__":
    success = test_api()
    exit(0 if success else 1)