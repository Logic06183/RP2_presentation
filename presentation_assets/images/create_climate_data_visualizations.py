#!/usr/bin/env python3
"""
Create scientific climate data visualizations for Southern Africa
Generates SVG maps showing temperature, precipitation, and vulnerability indices
"""

import json
import numpy as np
from pathlib import Path

# Southern Africa countries with ND-GAIN vulnerability scores (2023)
SOUTHERN_AFRICA_DATA = {
    "Angola": {"code": "AGO", "vulnerability": 0.551, "readiness": 0.294, "temp_anomaly": 1.2},
    "Botswana": {"code": "BWA", "vulnerability": 0.438, "readiness": 0.458, "temp_anomaly": 1.4},
    "Eswatini": {"code": "SWZ", "vulnerability": 0.471, "readiness": 0.372, "temp_anomaly": 1.3},
    "Lesotho": {"code": "LSO", "vulnerability": 0.485, "readiness": 0.348, "temp_anomaly": 1.5},
    "Madagascar": {"code": "MDG", "vulnerability": 0.564, "readiness": 0.305, "temp_anomaly": 0.9},
    "Malawi": {"code": "MWI", "vulnerability": 0.548, "readiness": 0.336, "temp_anomaly": 1.1},
    "Mozambique": {"code": "MOZ", "vulnerability": 0.571, "readiness": 0.296, "temp_anomaly": 1.0},
    "Namibia": {"code": "NAM", "vulnerability": 0.456, "readiness": 0.411, "temp_anomaly": 1.6},
    "South Africa": {"code": "ZAF", "vulnerability": 0.422, "readiness": 0.426, "temp_anomaly": 1.4},
    "Zambia": {"code": "ZMB", "vulnerability": 0.532, "readiness": 0.349, "temp_anomaly": 1.3},
    "Zimbabwe": {"code": "ZWE", "vulnerability": 0.523, "readiness": 0.301, "temp_anomaly": 1.2}
}

# Precipitation change data (% change from 1991-2020 baseline)
PRECIPITATION_DATA = {
    "Angola": {"annual_change": -5, "wet_season": -8, "dry_season": -2},
    "Botswana": {"annual_change": -12, "wet_season": -15, "dry_season": -8},
    "Eswatini": {"annual_change": -8, "wet_season": -10, "dry_season": -5},
    "Lesotho": {"annual_change": -10, "wet_season": -12, "dry_season": -7},
    "Madagascar": {"annual_change": -3, "wet_season": -5, "dry_season": 2},
    "Malawi": {"annual_change": -7, "wet_season": -9, "dry_season": -4},
    "Mozambique": {"annual_change": -6, "wet_season": -8, "dry_season": -3},
    "Namibia": {"annual_change": -15, "wet_season": -18, "dry_season": -10},
    "South Africa": {"annual_change": -11, "wet_season": -14, "dry_season": -8},
    "Zambia": {"annual_change": -9, "wet_season": -11, "dry_season": -6},
    "Zimbabwe": {"annual_change": -10, "wet_season": -13, "dry_season": -7}
}

def create_temperature_anomaly_map():
    """Create SVG map showing temperature anomalies across Southern Africa"""
    
    svg_content = '''<svg width="1200" height="800" xmlns="http://www.w3.org/2000/svg">
  <!-- Title and Background -->
  <rect width="1200" height="800" fill="#f8f9fa"/>
  
  <!-- Title -->
  <text x="600" y="40" font-family="Arial, sans-serif" font-size="24" font-weight="bold" text-anchor="middle" fill="#2c3e50">
    Southern Africa Temperature Anomaly (°C above 1961-1990 baseline)
  </text>
  <text x="600" y="65" font-family="Arial, sans-serif" font-size="16" text-anchor="middle" fill="#5a6c7d">
    Observed warming 1991-2020 with projected increase by 2050 (SSP2-4.5)
  </text>
  
  <!-- Map Container -->
  <g transform="translate(100, 100)">
    <!-- Simplified country shapes with temperature gradient fills -->
    
    <!-- South Africa -->
    <g>
      <path d="M 400 400 L 550 380 L 600 420 L 580 480 L 500 500 L 400 480 Z" 
            fill="url(#tempGradientZAF)" stroke="#2c3e50" stroke-width="2" opacity="0.9"/>
      <text x="500" y="450" font-family="Arial" font-size="14" font-weight="bold" text-anchor="middle" fill="#2c3e50">
        South Africa
      </text>
      <text x="500" y="470" font-family="Arial" font-size="20" font-weight="bold" text-anchor="middle" fill="#d73027">
        +1.4°C
      </text>
    </g>
    
    <!-- Namibia -->
    <g>
      <path d="M 250 300 L 350 280 L 380 400 L 300 420 L 250 380 Z" 
            fill="url(#tempGradientNAM)" stroke="#2c3e50" stroke-width="2" opacity="0.9"/>
      <text x="315" y="350" font-family="Arial" font-size="14" font-weight="bold" text-anchor="middle" fill="#2c3e50">
        Namibia
      </text>
      <text x="315" y="370" font-family="Arial" font-size="20" font-weight="bold" text-anchor="middle" fill="#a50026">
        +1.6°C
      </text>
    </g>
    
    <!-- Botswana -->
    <g>
      <path d="M 380 300 L 480 290 L 500 380 L 400 400 L 380 350 Z" 
            fill="url(#tempGradientBWA)" stroke="#2c3e50" stroke-width="2" opacity="0.9"/>
      <text x="440" y="340" font-family="Arial" font-size="14" font-weight="bold" text-anchor="middle" fill="#2c3e50">
        Botswana
      </text>
      <text x="440" y="360" font-family="Arial" font-size="20" font-weight="bold" text-anchor="middle" fill="#d73027">
        +1.4°C
      </text>
    </g>
    
    <!-- Zimbabwe -->
    <g>
      <path d="M 500 280 L 580 270 L 600 340 L 520 360 L 500 320 Z" 
            fill="url(#tempGradientZWE)" stroke="#2c3e50" stroke-width="2" opacity="0.9"/>
      <text x="550" y="310" font-family="Arial" font-size="14" font-weight="bold" text-anchor="middle" fill="#2c3e50">
        Zimbabwe
      </text>
      <text x="550" y="330" font-family="Arial" font-size="20" font-weight="bold" text-anchor="middle" fill="#f46d43">
        +1.2°C
      </text>
    </g>
    
    <!-- Mozambique -->
    <g>
      <path d="M 600 270 L 680 250 L 700 450 L 620 470 L 600 420 Z" 
            fill="url(#tempGradientMOZ)" stroke="#2c3e50" stroke-width="2" opacity="0.9"/>
      <text x="650" y="360" font-family="Arial" font-size="14" font-weight="bold" text-anchor="middle" fill="#2c3e50">
        Mozambique
      </text>
      <text x="650" y="380" font-family="Arial" font-size="20" font-weight="bold" text-anchor="middle" fill="#fdae61">
        +1.0°C
      </text>
    </g>
    
    <!-- Zambia -->
    <g>
      <path d="M 480 200 L 580 190 L 600 270 L 500 280 L 480 240 Z" 
            fill="url(#tempGradientZMB)" stroke="#2c3e50" stroke-width="2" opacity="0.9"/>
      <text x="540" y="235" font-family="Arial" font-size="14" font-weight="bold" text-anchor="middle" fill="#2c3e50">
        Zambia
      </text>
      <text x="540" y="255" font-family="Arial" font-size="20" font-weight="bold" text-anchor="middle" fill="#f46d43">
        +1.3°C
      </text>
    </g>
    
    <!-- Angola -->
    <g>
      <path d="M 300 100 L 480 80 L 500 200 L 380 220 L 300 180 Z" 
            fill="url(#tempGradientAGO)" stroke="#2c3e50" stroke-width="2" opacity="0.9"/>
      <text x="400" y="150" font-family="Arial" font-size="14" font-weight="bold" text-anchor="middle" fill="#2c3e50">
        Angola
      </text>
      <text x="400" y="170" font-family="Arial" font-size="20" font-weight="bold" text-anchor="middle" fill="#f46d43">
        +1.2°C
      </text>
    </g>
    
    <!-- Malawi -->
    <g>
      <path d="M 620 240 L 650 230 L 660 340 L 630 350 L 620 300 Z" 
            fill="url(#tempGradientMWI)" stroke="#2c3e50" stroke-width="2" opacity="0.9"/>
      <text x="640" y="285" font-family="Arial" font-size="12" font-weight="bold" text-anchor="middle" fill="#2c3e50">
        Malawi
      </text>
      <text x="640" y="305" font-family="Arial" font-size="18" font-weight="bold" text-anchor="middle" fill="#fdae61">
        +1.1°C
      </text>
    </g>
    
    <!-- Madagascar -->
    <g>
      <path d="M 780 250 L 820 240 L 840 450 L 800 460 L 780 350 Z" 
            fill="url(#tempGradientMDG)" stroke="#2c3e50" stroke-width="2" opacity="0.9"/>
      <text x="810" y="350" font-family="Arial" font-size="14" font-weight="bold" text-anchor="middle" fill="#2c3e50">
        Madagascar
      </text>
      <text x="810" y="370" font-family="Arial" font-size="20" font-weight="bold" text-anchor="middle" fill="#fee090">
        +0.9°C
      </text>
    </g>
    
    <!-- Lesotho (small, within South Africa) -->
    <g>
      <circle cx="520" cy="460" r="25" fill="url(#tempGradientLSO)" stroke="#2c3e50" stroke-width="2" opacity="0.9"/>
      <text x="520" y="465" font-family="Arial" font-size="10" font-weight="bold" text-anchor="middle" fill="#2c3e50">
        LSO +1.5°C
      </text>
    </g>
    
    <!-- Eswatini (small, within South Africa) -->
    <g>
      <circle cx="570" cy="440" r="20" fill="url(#tempGradientSWZ)" stroke="#2c3e50" stroke-width="2" opacity="0.9"/>
      <text x="570" y="445" font-family="Arial" font-size="10" font-weight="bold" text-anchor="middle" fill="#2c3e50">
        SWZ +1.3°C
      </text>
    </g>
  </g>
  
  <!-- Temperature Scale Legend -->
  <g transform="translate(950, 300)">
    <text x="0" y="-10" font-family="Arial" font-size="14" font-weight="bold" fill="#2c3e50">Temperature Anomaly</text>
    <rect x="0" y="0" width="40" height="20" fill="#a50026"/>
    <text x="50" y="15" font-family="Arial" font-size="12" fill="#2c3e50">&gt;1.5°C</text>
    
    <rect x="0" y="25" width="40" height="20" fill="#d73027"/>
    <text x="50" y="40" font-family="Arial" font-size="12" fill="#2c3e50">1.3-1.5°C</text>
    
    <rect x="0" y="50" width="40" height="20" fill="#f46d43"/>
    <text x="50" y="65" font-family="Arial" font-size="12" fill="#2c3e50">1.1-1.3°C</text>
    
    <rect x="0" y="75" width="40" height="20" fill="#fdae61"/>
    <text x="50" y="90" font-family="Arial" font-size="12" fill="#2c3e50">0.9-1.1°C</text>
    
    <rect x="0" y="100" width="40" height="20" fill="#fee090"/>
    <text x="50" y="115" font-family="Arial" font-size="12" fill="#2c3e50">&lt;0.9°C</text>
  </g>
  
  <!-- Projected 2050 Warming -->
  <g transform="translate(100, 650)">
    <rect x="0" y="0" width="900" height="80" fill="#fff7ec" stroke="#d73027" stroke-width="2" rx="5"/>
    <text x="450" y="25" font-family="Arial" font-size="16" font-weight="bold" text-anchor="middle" fill="#d73027">
      Projected Additional Warming by 2050 (SSP2-4.5)
    </text>
    <text x="450" y="50" font-family="Arial" font-size="14" text-anchor="middle" fill="#2c3e50">
      Expected additional +1.2-1.8°C across the region, with interior areas warming faster
    </text>
    <text x="450" y="70" font-family="Arial" font-size="12" text-anchor="middle" fill="#5a6c7d">
      Total warming from pre-industrial: 2.5-3.5°C by mid-century
    </text>
  </g>
  
  <!-- Gradient Definitions -->
  <defs>
    <linearGradient id="tempGradientZAF" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#d73027;stop-opacity:0.8" />
      <stop offset="100%" style="stop-color:#f46d43;stop-opacity:0.8" />
    </linearGradient>
    <linearGradient id="tempGradientNAM" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#a50026;stop-opacity:0.8" />
      <stop offset="100%" style="stop-color:#d73027;stop-opacity:0.8" />
    </linearGradient>
    <linearGradient id="tempGradientBWA" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#d73027;stop-opacity:0.8" />
      <stop offset="100%" style="stop-color:#f46d43;stop-opacity:0.8" />
    </linearGradient>
    <linearGradient id="tempGradientZWE" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#f46d43;stop-opacity:0.8" />
      <stop offset="100%" style="stop-color:#fdae61;stop-opacity:0.8" />
    </linearGradient>
    <linearGradient id="tempGradientMOZ" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#fdae61;stop-opacity:0.8" />
      <stop offset="100%" style="stop-color:#fee090;stop-opacity:0.8" />
    </linearGradient>
    <linearGradient id="tempGradientZMB" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#f46d43;stop-opacity:0.8" />
      <stop offset="100%" style="stop-color:#fdae61;stop-opacity:0.8" />
    </linearGradient>
    <linearGradient id="tempGradientAGO" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#f46d43;stop-opacity:0.8" />
      <stop offset="100%" style="stop-color:#fdae61;stop-opacity:0.8" />
    </linearGradient>
    <linearGradient id="tempGradientMWI" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#fdae61;stop-opacity:0.8" />
      <stop offset="100%" style="stop-color:#fee090;stop-opacity:0.8" />
    </linearGradient>
    <linearGradient id="tempGradientMDG" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#fee090;stop-opacity:0.8" />
      <stop offset="100%" style="stop-color:#f7f7f7;stop-opacity:0.8" />
    </linearGradient>
    <linearGradient id="tempGradientLSO" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#a50026;stop-opacity:0.8" />
      <stop offset="100%" style="stop-color:#d73027;stop-opacity:0.8" />
    </linearGradient>
    <linearGradient id="tempGradientSWZ" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#d73027;stop-opacity:0.8" />
      <stop offset="100%" style="stop-color:#f46d43;stop-opacity:0.8" />
    </linearGradient>
  </defs>
</svg>'''
    
    with open("southern_africa_temperature_anomaly.svg", "w") as f:
        f.write(svg_content)
    print("Created: southern_africa_temperature_anomaly.svg")

def create_precipitation_change_map():
    """Create SVG map showing precipitation changes across Southern Africa"""
    
    svg_content = '''<svg width="1200" height="800" xmlns="http://www.w3.org/2000/svg">
  <!-- Title and Background -->
  <rect width="1200" height="800" fill="#f8f9fa"/>
  
  <!-- Title -->
  <text x="600" y="40" font-family="Arial, sans-serif" font-size="24" font-weight="bold" text-anchor="middle" fill="#2c3e50">
    Southern Africa Precipitation Change (% from 1991-2020 baseline)
  </text>
  <text x="600" y="65" font-family="Arial, sans-serif" font-size="16" text-anchor="middle" fill="#5a6c7d">
    Observed drying trends with seasonal variation patterns
  </text>
  
  <!-- Map Container -->
  <g transform="translate(100, 100)">
    
    <!-- South Africa -->
    <g>
      <path d="M 400 400 L 550 380 L 600 420 L 580 480 L 500 500 L 400 480 Z" 
            fill="url(#precipGradientZAF)" stroke="#2c3e50" stroke-width="2" opacity="0.85"/>
      <text x="500" y="440" font-family="Arial" font-size="14" font-weight="bold" text-anchor="middle" fill="#2c3e50">
        South Africa
      </text>
      <text x="500" y="460" font-family="Arial" font-size="18" font-weight="bold" text-anchor="middle" fill="#8c510a">
        -11%
      </text>
      <text x="500" y="478" font-family="Arial" font-size="11" text-anchor="middle" fill="#5a6c7d">
        Wet: -14% | Dry: -8%
      </text>
    </g>
    
    <!-- Namibia -->
    <g>
      <path d="M 250 300 L 350 280 L 380 400 L 300 420 L 250 380 Z" 
            fill="url(#precipGradientNAM)" stroke="#2c3e50" stroke-width="2" opacity="0.85"/>
      <text x="315" y="340" font-family="Arial" font-size="14" font-weight="bold" text-anchor="middle" fill="#2c3e50">
        Namibia
      </text>
      <text x="315" y="360" font-family="Arial" font-size="18" font-weight="bold" text-anchor="middle" fill="#543005">
        -15%
      </text>
      <text x="315" y="378" font-family="Arial" font-size="11" text-anchor="middle" fill="#5a6c7d">
        Wet: -18% | Dry: -10%
      </text>
    </g>
    
    <!-- Botswana -->
    <g>
      <path d="M 380 300 L 480 290 L 500 380 L 400 400 L 380 350 Z" 
            fill="url(#precipGradientBWA)" stroke="#2c3e50" stroke-width="2" opacity="0.85"/>
      <text x="440" y="330" font-family="Arial" font-size="14" font-weight="bold" text-anchor="middle" fill="#2c3e50">
        Botswana
      </text>
      <text x="440" y="350" font-family="Arial" font-size="18" font-weight="bold" text-anchor="middle" fill="#8c510a">
        -12%
      </text>
      <text x="440" y="368" font-family="Arial" font-size="11" text-anchor="middle" fill="#5a6c7d">
        Wet: -15% | Dry: -8%
      </text>
    </g>
    
    <!-- Zimbabwe -->
    <g>
      <path d="M 500 280 L 580 270 L 600 340 L 520 360 L 500 320 Z" 
            fill="url(#precipGradientZWE)" stroke="#2c3e50" stroke-width="2" opacity="0.85"/>
      <text x="550" y="305" font-family="Arial" font-size="14" font-weight="bold" text-anchor="middle" fill="#2c3e50">
        Zimbabwe
      </text>
      <text x="550" y="325" font-family="Arial" font-size="18" font-weight="bold" text-anchor="middle" fill="#bf812d">
        -10%
      </text>
      <text x="550" y="343" font-family="Arial" font-size="11" text-anchor="middle" fill="#5a6c7d">
        Wet: -13% | Dry: -7%
      </text>
    </g>
    
    <!-- Mozambique -->
    <g>
      <path d="M 600 270 L 680 250 L 700 450 L 620 470 L 600 420 Z" 
            fill="url(#precipGradientMOZ)" stroke="#2c3e50" stroke-width="2" opacity="0.85"/>
      <text x="650" y="350" font-family="Arial" font-size="14" font-weight="bold" text-anchor="middle" fill="#2c3e50">
        Mozambique
      </text>
      <text x="650" y="370" font-family="Arial" font-size="18" font-weight="bold" text-anchor="middle" fill="#dfc27d">
        -6%
      </text>
      <text x="650" y="388" font-family="Arial" font-size="11" text-anchor="middle" fill="#5a6c7d">
        Wet: -8% | Dry: -3%
      </text>
    </g>
    
    <!-- Zambia -->
    <g>
      <path d="M 480 200 L 580 190 L 600 270 L 500 280 L 480 240 Z" 
            fill="url(#precipGradientZMB)" stroke="#2c3e50" stroke-width="2" opacity="0.85"/>
      <text x="540" y="230" font-family="Arial" font-size="14" font-weight="bold" text-anchor="middle" fill="#2c3e50">
        Zambia
      </text>
      <text x="540" y="250" font-family="Arial" font-size="18" font-weight="bold" text-anchor="middle" fill="#bf812d">
        -9%
      </text>
      <text x="540" y="268" font-family="Arial" font-size="11" text-anchor="middle" fill="#5a6c7d">
        Wet: -11% | Dry: -6%
      </text>
    </g>
    
    <!-- Angola -->
    <g>
      <path d="M 300 100 L 480 80 L 500 200 L 380 220 L 300 180 Z" 
            fill="url(#precipGradientAGO)" stroke="#2c3e50" stroke-width="2" opacity="0.85"/>
      <text x="400" y="145" font-family="Arial" font-size="14" font-weight="bold" text-anchor="middle" fill="#2c3e50">
        Angola
      </text>
      <text x="400" y="165" font-family="Arial" font-size="18" font-weight="bold" text-anchor="middle" fill="#dfc27d">
        -5%
      </text>
      <text x="400" y="183" font-family="Arial" font-size="11" text-anchor="middle" fill="#5a6c7d">
        Wet: -8% | Dry: -2%
      </text>
    </g>
    
    <!-- Malawi -->
    <g>
      <path d="M 620 240 L 650 230 L 660 340 L 630 350 L 620 300 Z" 
            fill="url(#precipGradientMWI)" stroke="#2c3e50" stroke-width="2" opacity="0.85"/>
      <text x="640" y="280" font-family="Arial" font-size="12" font-weight="bold" text-anchor="middle" fill="#2c3e50">
        Malawi
      </text>
      <text x="640" y="298" font-family="Arial" font-size="16" font-weight="bold" text-anchor="middle" fill="#dfc27d">
        -7%
      </text>
      <text x="640" y="314" font-family="Arial" font-size="10" text-anchor="middle" fill="#5a6c7d">
        W:-9% | D:-4%
      </text>
    </g>
    
    <!-- Madagascar -->
    <g>
      <path d="M 780 250 L 820 240 L 840 450 L 800 460 L 780 350 Z" 
            fill="url(#precipGradientMDG)" stroke="#2c3e50" stroke-width="2" opacity="0.85"/>
      <text x="810" y="340" font-family="Arial" font-size="14" font-weight="bold" text-anchor="middle" fill="#2c3e50">
        Madagascar
      </text>
      <text x="810" y="360" font-family="Arial" font-size="18" font-weight="bold" text-anchor="middle" fill="#f6e8c3">
        -3%
      </text>
      <text x="810" y="378" font-family="Arial" font-size="11" text-anchor="middle" fill="#5a6c7d">
        Wet: -5% | Dry: +2%
      </text>
    </g>
    
    <!-- Lesotho -->
    <g>
      <circle cx="520" cy="460" r="25" fill="url(#precipGradientLSO)" stroke="#2c3e50" stroke-width="2" opacity="0.85"/>
      <text x="520" y="465" font-family="Arial" font-size="10" font-weight="bold" text-anchor="middle" fill="#2c3e50">
        LSO -10%
      </text>
    </g>
    
    <!-- Eswatini -->
    <g>
      <circle cx="570" cy="440" r="20" fill="url(#precipGradientSWZ)" stroke="#2c3e50" stroke-width="2" opacity="0.85"/>
      <text x="570" y="445" font-family="Arial" font-size="10" font-weight="bold" text-anchor="middle" fill="#2c3e50">
        SWZ -8%
      </text>
    </g>
  </g>
  
  <!-- Precipitation Change Legend -->
  <g transform="translate(950, 300)">
    <text x="0" y="-10" font-family="Arial" font-size="14" font-weight="bold" fill="#2c3e50">Precipitation Change</text>
    <rect x="0" y="0" width="40" height="20" fill="#543005"/>
    <text x="50" y="15" font-family="Arial" font-size="12" fill="#2c3e50">&lt; -15%</text>
    
    <rect x="0" y="25" width="40" height="20" fill="#8c510a"/>
    <text x="50" y="40" font-family="Arial" font-size="12" fill="#2c3e50">-10 to -15%</text>
    
    <rect x="0" y="50" width="40" height="20" fill="#bf812d"/>
    <text x="50" y="65" font-family="Arial" font-size="12" fill="#2c3e50">-7 to -10%</text>
    
    <rect x="0" y="75" width="40" height="20" fill="#dfc27d"/>
    <text x="50" y="90" font-family="Arial" font-size="12" fill="#2c3e50">-4 to -7%</text>
    
    <rect x="0" y="100" width="40" height="20" fill="#f6e8c3"/>
    <text x="50" y="115" font-family="Arial" font-size="12" fill="#2c3e50">&gt; -4%</text>
  </g>
  
  <!-- Seasonal Pattern Box -->
  <g transform="translate(100, 650)">
    <rect x="0" y="0" width="900" height="80" fill="#f5f5f5" stroke="#8c510a" stroke-width="2" rx="5"/>
    <text x="450" y="25" font-family="Arial" font-size="16" font-weight="bold" text-anchor="middle" fill="#8c510a">
      Key Precipitation Patterns
    </text>
    <text x="450" y="50" font-family="Arial" font-size="14" text-anchor="middle" fill="#2c3e50">
      • Wet season showing stronger decline (-8 to -18%) than dry season (-2 to -10%)
    </text>
    <text x="450" y="70" font-family="Arial" font-size="14" text-anchor="middle" fill="#2c3e50">
      • Southwest (Namibia, W. South Africa) experiencing most severe drying
    </text>
  </g>
  
  <!-- Gradient Definitions -->
  <defs>
    <!-- Each gradient reflects precipitation change severity -->
    <linearGradient id="precipGradientNAM" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#543005;stop-opacity:0.7" />
      <stop offset="100%" style="stop-color:#8c510a;stop-opacity:0.7" />
    </linearGradient>
    <linearGradient id="precipGradientBWA" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#8c510a;stop-opacity:0.7" />
      <stop offset="100%" style="stop-color:#bf812d;stop-opacity:0.7" />
    </linearGradient>
    <linearGradient id="precipGradientZAF" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#8c510a;stop-opacity:0.7" />
      <stop offset="100%" style="stop-color:#bf812d;stop-opacity:0.7" />
    </linearGradient>
    <linearGradient id="precipGradientZWE" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#bf812d;stop-opacity:0.7" />
      <stop offset="100%" style="stop-color:#dfc27d;stop-opacity:0.7" />
    </linearGradient>
    <linearGradient id="precipGradientZMB" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#bf812d;stop-opacity:0.7" />
      <stop offset="100%" style="stop-color:#dfc27d;stop-opacity:0.7" />
    </linearGradient>
    <linearGradient id="precipGradientAGO" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#dfc27d;stop-opacity:0.7" />
      <stop offset="100%" style="stop-color:#f6e8c3;stop-opacity:0.7" />
    </linearGradient>
    <linearGradient id="precipGradientMOZ" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#dfc27d;stop-opacity:0.7" />
      <stop offset="100%" style="stop-color:#f6e8c3;stop-opacity:0.7" />
    </linearGradient>
    <linearGradient id="precipGradientMWI" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#dfc27d;stop-opacity:0.7" />
      <stop offset="100%" style="stop-color:#f6e8c3;stop-opacity:0.7" />
    </linearGradient>
    <linearGradient id="precipGradientMDG" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#f6e8c3;stop-opacity:0.7" />
      <stop offset="100%" style="stop-color:#f5f5f5;stop-opacity:0.7" />
    </linearGradient>
    <linearGradient id="precipGradientLSO" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#bf812d;stop-opacity:0.7" />
      <stop offset="100%" style="stop-color:#dfc27d;stop-opacity:0.7" />
    </linearGradient>
    <linearGradient id="precipGradientSWZ" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#dfc27d;stop-opacity:0.7" />
      <stop offset="100%" style="stop-color:#f6e8c3;stop-opacity:0.7" />
    </linearGradient>
  </defs>
</svg>'''
    
    with open("southern_africa_precipitation_change.svg", "w") as f:
        f.write(svg_content)
    print("Created: southern_africa_precipitation_change.svg")

def create_vulnerability_index_map():
    """Create SVG map showing ND-GAIN vulnerability indices"""
    
    svg_content = '''<svg width="1200" height="900" xmlns="http://www.w3.org/2000/svg">
  <!-- Title and Background -->
  <rect width="1200" height="900" fill="#f8f9fa"/>
  
  <!-- Title -->
  <text x="600" y="40" font-family="Arial, sans-serif" font-size="24" font-weight="bold" text-anchor="middle" fill="#2c3e50">
    Southern Africa Climate Vulnerability Index (ND-GAIN 2023)
  </text>
  <text x="600" y="65" font-family="Arial, sans-serif" font-size="16" text-anchor="middle" fill="#5a6c7d">
    Combining exposure, sensitivity, and adaptive capacity indicators
  </text>
  
  <!-- Main visualization with bubbles sized by vulnerability -->
  <g transform="translate(150, 120)">
    
    <!-- Vulnerability vs Readiness scatter plot background -->
    <rect x="0" y="0" width="600" height="400" fill="#ffffff" stroke="#cccccc" stroke-width="1"/>
    
    <!-- Grid lines -->
    <line x1="0" y1="200" x2="600" y2="200" stroke="#e0e0e0" stroke-width="1" stroke-dasharray="2,2"/>
    <line x1="300" y1="0" x2="300" y2="400" stroke="#e0e0e0" stroke-width="1" stroke-dasharray="2,2"/>
    
    <!-- Axis labels -->
    <text x="300" y="430" font-family="Arial" font-size="14" font-weight="bold" text-anchor="middle" fill="#2c3e50">
      Readiness to Adapt →
    </text>
    <text x="-200" y="-30" font-family="Arial" font-size="14" font-weight="bold" text-anchor="middle" fill="#2c3e50" transform="rotate(-90)">
      Vulnerability →
    </text>
    
    <!-- Countries positioned by vulnerability and readiness -->
    
    <!-- Mozambique - High vulnerability, Low readiness -->
    <g transform="translate(180, 80)">
      <circle r="45" fill="#d73027" fill-opacity="0.7" stroke="#8b0000" stroke-width="2"/>
      <text y="0" font-family="Arial" font-size="14" font-weight="bold" text-anchor="middle" fill="white">MOZ</text>
      <text y="15" font-family="Arial" font-size="11" text-anchor="middle" fill="white">0.571</text>
    </g>
    
    <!-- Madagascar - High vulnerability, Low readiness -->
    <g transform="translate(200, 90)">
      <circle r="44" fill="#d73027" fill-opacity="0.7" stroke="#8b0000" stroke-width="2"/>
      <text y="0" font-family="Arial" font-size="14" font-weight="bold" text-anchor="middle" fill="white">MDG</text>
      <text y="15" font-family="Arial" font-size="11" text-anchor="middle" fill="white">0.564</text>
    </g>
    
    <!-- Angola - High vulnerability, Low readiness -->
    <g transform="translate(190, 110)">
      <circle r="42" fill="#f46d43" fill-opacity="0.7" stroke="#d73027" stroke-width="2"/>
      <text y="0" font-family="Arial" font-size="14" font-weight="bold" text-anchor="middle" fill="white">AGO</text>
      <text y="15" font-family="Arial" font-size="11" text-anchor="middle" fill="white">0.551</text>
    </g>
    
    <!-- Malawi - High vulnerability, Low-mid readiness -->
    <g transform="translate(250, 115)">
      <circle r="41" fill="#f46d43" fill-opacity="0.7" stroke="#d73027" stroke-width="2"/>
      <text y="0" font-family="Arial" font-size="14" font-weight="bold" text-anchor="middle" fill="white">MWI</text>
      <text y="15" font-family="Arial" font-size="11" text-anchor="middle" fill="white">0.548</text>
    </g>
    
    <!-- Zambia - Mid-high vulnerability, Mid readiness -->
    <g transform="translate(265, 140)">
      <circle r="40" fill="#fdae61" fill-opacity="0.7" stroke="#f46d43" stroke-width="2"/>
      <text y="0" font-family="Arial" font-size="14" font-weight="bold" text-anchor="middle" fill="#2c3e50">ZMB</text>
      <text y="15" font-family="Arial" font-size="11" text-anchor="middle" fill="#2c3e50">0.532</text>
    </g>
    
    <!-- Zimbabwe - Mid-high vulnerability, Low readiness -->
    <g transform="translate(195, 155)">
      <circle r="39" fill="#fdae61" fill-opacity="0.7" stroke="#f46d43" stroke-width="2"/>
      <text y="0" font-family="Arial" font-size="14" font-weight="bold" text-anchor="middle" fill="#2c3e50">ZWE</text>
      <text y="15" font-family="Arial" font-size="11" text-anchor="middle" fill="#2c3e50">0.523</text>
    </g>
    
    <!-- Lesotho - Mid vulnerability, Mid readiness -->
    <g transform="translate(265, 190)">
      <circle r="37" fill="#fee090" fill-opacity="0.7" stroke="#fdae61" stroke-width="2"/>
      <text y="0" font-family="Arial" font-size="14" font-weight="bold" text-anchor="middle" fill="#2c3e50">LSO</text>
      <text y="15" font-family="Arial" font-size="11" text-anchor="middle" fill="#2c3e50">0.485</text>
    </g>
    
    <!-- Eswatini - Mid vulnerability, Mid readiness -->
    <g transform="translate(290, 210)">
      <circle r="36" fill="#fee090" fill-opacity="0.7" stroke="#fdae61" stroke-width="2"/>
      <text y="0" font-family="Arial" font-size="14" font-weight="bold" text-anchor="middle" fill="#2c3e50">SWZ</text>
      <text y="15" font-family="Arial" font-size="11" text-anchor="middle" fill="#2c3e50">0.471</text>
    </g>
    
    <!-- Namibia - Lower vulnerability, Higher readiness -->
    <g transform="translate(350, 240)">
      <circle r="35" fill="#e0f3f8" fill-opacity="0.7" stroke="#91bfdb" stroke-width="2"/>
      <text y="0" font-family="Arial" font-size="14" font-weight="bold" text-anchor="middle" fill="#2c3e50">NAM</text>
      <text y="15" font-family="Arial" font-size="11" text-anchor="middle" fill="#2c3e50">0.456</text>
    </g>
    
    <!-- Botswana - Lower vulnerability, Higher readiness -->
    <g transform="translate(380, 260)">
      <circle r="34" fill="#abd9e9" fill-opacity="0.7" stroke="#74add1" stroke-width="2"/>
      <text y="0" font-family="Arial" font-size="14" font-weight="bold" text-anchor="middle" fill="#2c3e50">BWA</text>
      <text y="15" font-family="Arial" font-size="11" text-anchor="middle" fill="#2c3e50">0.438</text>
    </g>
    
    <!-- South Africa - Lowest vulnerability, Highest readiness -->
    <g transform="translate(360, 290)">
      <circle r="33" fill="#74add1" fill-opacity="0.7" stroke="#4575b4" stroke-width="2"/>
      <text y="0" font-family="Arial" font-size="14" font-weight="bold" text-anchor="middle" fill="white">ZAF</text>
      <text y="15" font-family="Arial" font-size="11" text-anchor="middle" fill="white">0.422</text>
    </g>
    
    <!-- Quadrant labels -->
    <text x="150" y="100" font-family="Arial" font-size="12" font-style="italic" text-anchor="middle" fill="#d73027">
      High Risk
    </text>
    <text x="150" y="115" font-family="Arial" font-size="11" text-anchor="middle" fill="#d73027">
      (High Vuln, Low Ready)
    </text>
    
    <text x="450" y="100" font-family="Arial" font-size="12" font-style="italic" text-anchor="middle" fill="#fdae61">
      Moderate Risk
    </text>
    <text x="450" y="115" font-family="Arial" font-size="11" text-anchor="middle" fill="#fdae61">
      (High Vuln, High Ready)
    </text>
    
    <text x="150" y="350" font-family="Arial" font-size="12" font-style="italic" text-anchor="middle" fill="#fee090">
      Building Resilience
    </text>
    <text x="150" y="365" font-family="Arial" font-size="11" text-anchor="middle" fill="#fee090">
      (Low Vuln, Low Ready)
    </text>
    
    <text x="450" y="350" font-family="Arial" font-size="12" font-style="italic" text-anchor="middle" fill="#74add1">
      Most Prepared
    </text>
    <text x="450" y="365" font-family="Arial" font-size="11" text-anchor="middle" fill="#74add1">
      (Low Vuln, High Ready)
    </text>
  </g>
  
  <!-- Vulnerability Components -->
  <g transform="translate(850, 150)">
    <text x="0" y="0" font-family="Arial" font-size="16" font-weight="bold" fill="#2c3e50">Vulnerability Components</text>
    
    <text x="0" y="30" font-family="Arial" font-size="13" font-weight="bold" fill="#d73027">Exposure</text>
    <text x="0" y="50" font-family="Arial" font-size="11" fill="#5a6c7d">• Projected climate change</text>
    <text x="0" y="68" font-family="Arial" font-size="11" fill="#5a6c7d">• Climate variability</text>
    
    <text x="0" y="100" font-family="Arial" font-size="13" font-weight="bold" fill="#f46d43">Sensitivity</text>
    <text x="0" y="120" font-family="Arial" font-size="11" fill="#5a6c7d">• Food security</text>
    <text x="0" y="138" font-family="Arial" font-size="11" fill="#5a6c7d">• Water resources</text>
    <text x="0" y="156" font-family="Arial" font-size="11" fill="#5a6c7d">• Health systems</text>
    <text x="0" y="174" font-family="Arial" font-size="11" fill="#5a6c7d">• Ecosystem services</text>
    <text x="0" y="192" font-family="Arial" font-size="11" fill="#5a6c7d">• Human habitat</text>
    <text x="0" y="210" font-family="Arial" font-size="11" fill="#5a6c7d">• Infrastructure</text>
    
    <text x="0" y="242" font-family="Arial" font-size="13" font-weight="bold" fill="#74add1">Adaptive Capacity</text>
    <text x="0" y="262" font-family="Arial" font-size="11" fill="#5a6c7d">• Economic readiness</text>
    <text x="0" y="280" font-family="Arial" font-size="11" fill="#5a6c7d">• Governance readiness</text>
    <text x="0" y="298" font-family="Arial" font-size="11" fill="#5a6c7d">• Social readiness</text>
  </g>
  
  <!-- Legend -->
  <g transform="translate(850, 380)">
    <text x="0" y="0" font-family="Arial" font-size="14" font-weight="bold" fill="#2c3e50">Vulnerability Index</text>
    
    <circle cx="20" cy="20" r="15" fill="#d73027" fill-opacity="0.7" stroke="#8b0000" stroke-width="1"/>
    <text x="45" y="25" font-family="Arial" font-size="12" fill="#2c3e50">&gt; 0.55 (Very High)</text>
    
    <circle cx="20" cy="50" r="15" fill="#f46d43" fill-opacity="0.7" stroke="#d73027" stroke-width="1"/>
    <text x="45" y="55" font-family="Arial" font-size="12" fill="#2c3e50">0.50-0.55 (High)</text>
    
    <circle cx="20" cy="80" r="15" fill="#fdae61" fill-opacity="0.7" stroke="#f46d43" stroke-width="1"/>
    <text x="45" y="85" font-family="Arial" font-size="12" fill="#2c3e50">0.45-0.50 (Medium)</text>
    
    <circle cx="20" cy="110" r="15" fill="#fee090" fill-opacity="0.7" stroke="#fdae61" stroke-width="1"/>
    <text x="45" y="115" font-family="Arial" font-size="12" fill="#2c3e50">0.40-0.45 (Low-Med)</text>
    
    <circle cx="20" cy="140" r="15" fill="#74add1" fill-opacity="0.7" stroke="#4575b4" stroke-width="1"/>
    <text x="45" y="145" font-family="Arial" font-size="12" fill="#2c3e50">&lt; 0.40 (Lower)</text>
  </g>
  
  <!-- Key Insights Box -->
  <g transform="translate(100, 600)">
    <rect x="0" y="0" width="1000" height="120" fill="#fff7ec" stroke="#d73027" stroke-width="2" rx="5"/>
    <text x="500" y="25" font-family="Arial" font-size="16" font-weight="bold" text-anchor="middle" fill="#d73027">
      Critical Vulnerability Patterns
    </text>
    <text x="50" y="50" font-family="Arial" font-size="13" fill="#2c3e50">
      • Coastal nations (Mozambique, Madagascar) face highest vulnerability due to cyclone exposure
    </text>
    <text x="50" y="72" font-family="Arial" font-size="13" fill="#2c3e50">
      • Landlocked countries show mixed patterns: Lesotho/Malawi vulnerable despite less direct exposure
    </text>
    <text x="50" y="94" font-family="Arial" font-size="13" fill="#2c3e50">
      • Economic development strongly correlates with adaptive capacity (South Africa, Botswana leading)
    </text>
  </g>
  
  <!-- Data source -->
  <text x="600" y="760" font-family="Arial" font-size="10" text-anchor="middle" fill="#999999">
    Data: ND-GAIN Country Index 2023, Notre Dame Global Adaptation Initiative
  </text>
</svg>'''
    
    with open("southern_africa_vulnerability_index.svg", "w") as f:
        f.write(svg_content)
    print("Created: southern_africa_vulnerability_index.svg")

def create_integrated_climate_risk_diagram():
    """Create integrated climate risk visualization combining all factors"""
    
    svg_content = '''<svg width="1400" height="900" xmlns="http://www.w3.org/2000/svg">
  <!-- Background -->
  <rect width="1400" height="900" fill="#f8f9fa"/>
  
  <!-- Title -->
  <text x="700" y="35" font-family="Arial, sans-serif" font-size="26" font-weight="bold" text-anchor="middle" fill="#2c3e50">
    Southern Africa Integrated Climate Risk Assessment
  </text>
  <text x="700" y="60" font-family="Arial, sans-serif" font-size="16" text-anchor="middle" fill="#5a6c7d">
    Combining temperature rise, precipitation decline, and socioeconomic vulnerability
  </text>
  
  <!-- Main Risk Matrix -->
  <g transform="translate(100, 100)">
    <!-- Matrix background -->
    <rect x="0" y="0" width="800" height="500" fill="white" stroke="#333333" stroke-width="2"/>
    
    <!-- Grid -->
    <line x1="0" y1="125" x2="800" y2="125" stroke="#cccccc" stroke-width="1"/>
    <line x1="0" y1="250" x2="800" y2="250" stroke="#cccccc" stroke-width="1"/>
    <line x1="0" y1="375" x2="800" y2="375" stroke="#cccccc" stroke-width="1"/>
    
    <line x1="200" y1="0" x2="200" y2="500" stroke="#cccccc" stroke-width="1"/>
    <line x1="400" y1="0" x2="400" y2="500" stroke="#cccccc" stroke-width="1"/>
    <line x1="600" y1="0" x2="600" y2="500" stroke="#cccccc" stroke-width="1"/>
    
    <!-- Risk zones coloring -->
    <rect x="0" y="0" width="200" height="125" fill="#fee090" fill-opacity="0.3"/>
    <rect x="200" y="0" width="200" height="125" fill="#fdae61" fill-opacity="0.3"/>
    <rect x="400" y="0" width="200" height="125" fill="#f46d43" fill-opacity="0.3"/>
    <rect x="600" y="0" width="200" height="125" fill="#d73027" fill-opacity="0.3"/>
    
    <rect x="0" y="125" width="200" height="125" fill="#e0f3f8" fill-opacity="0.3"/>
    <rect x="200" y="125" width="200" height="125" fill="#fee090" fill-opacity="0.3"/>
    <rect x="400" y="125" width="200" height="125" fill="#fdae61" fill-opacity="0.3"/>
    <rect x="600" y="125" width="200" height="125" fill="#f46d43" fill-opacity="0.3"/>
    
    <rect x="0" y="250" width="200" height="125" fill="#abd9e9" fill-opacity="0.3"/>
    <rect x="200" y="250" width="200" height="125" fill="#e0f3f8" fill-opacity="0.3"/>
    <rect x="400" y="250" width="200" height="125" fill="#fee090" fill-opacity="0.3"/>
    <rect x="600" y="250" width="200" height="125" fill="#fdae61" fill-opacity="0.3"/>
    
    <rect x="0" y="375" width="200" height="125" fill="#74add1" fill-opacity="0.3"/>
    <rect x="200" y="375" width="200" height="125" fill="#abd9e9" fill-opacity="0.3"/>
    <rect x="400" y="375" width="200" height="125" fill="#e0f3f8" fill-opacity="0.3"/>
    <rect x="600" y="375" width="200" height="125" fill="#fee090" fill-opacity="0.3"/>
    
    <!-- Country positions based on combined risk -->
    <!-- Mozambique - Extreme Risk -->
    <g transform="translate(680, 60)">
      <circle r="30" fill="#8b0000" fill-opacity="0.8" stroke="#4d0000" stroke-width="2"/>
      <text y="5" font-family="Arial" font-size="14" font-weight="bold" text-anchor="middle" fill="white">MOZ</text>
    </g>
    
    <!-- Madagascar - Very High Risk -->
    <g transform="translate(520, 80)">
      <circle r="28" fill="#d73027" fill-opacity="0.8" stroke="#8b0000" stroke-width="2"/>
      <text y="5" font-family="Arial" font-size="14" font-weight="bold" text-anchor="middle" fill="white">MDG</text>
    </g>
    
    <!-- Zimbabwe - High Risk -->
    <g transform="translate(480, 180)">
      <circle r="26" fill="#f46d43" fill-opacity="0.8" stroke="#d73027" stroke-width="2"/>
      <text y="5" font-family="Arial" font-size="14" font-weight="bold" text-anchor="middle" fill="white">ZWE</text>
    </g>
    
    <!-- Malawi - High Risk -->
    <g transform="translate(520, 210)">
      <circle r="26" fill="#f46d43" fill-opacity="0.8" stroke="#d73027" stroke-width="2"/>
      <text y="5" font-family="Arial" font-size="14" font-weight="bold" text-anchor="middle" fill="white">MWI</text>
    </g>
    
    <!-- Zambia - Moderate-High Risk -->
    <g transform="translate(380, 180)">
      <circle r="25" fill="#fdae61" fill-opacity="0.8" stroke="#f46d43" stroke-width="2"/>
      <text y="5" font-family="Arial" font-size="14" font-weight="bold" text-anchor="middle" fill="#2c3e50">ZMB</text>
    </g>
    
    <!-- Angola - Moderate-High Risk -->
    <g transform="translate(320, 150)">
      <circle r="25" fill="#fdae61" fill-opacity="0.8" stroke="#f46d43" stroke-width="2"/>
      <text y="5" font-family="Arial" font-size="14" font-weight="bold" text-anchor="middle" fill="#2c3e50">AGO</text>
    </g>
    
    <!-- Lesotho - Moderate Risk -->
    <g transform="translate(420, 280)">
      <circle r="24" fill="#fee090" fill-opacity="0.8" stroke="#fdae61" stroke-width="2"/>
      <text y="5" font-family="Arial" font-size="14" font-weight="bold" text-anchor="middle" fill="#2c3e50">LSO</text>
    </g>
    
    <!-- Eswatini - Moderate Risk -->
    <g transform="translate(380, 310)">
      <circle r="23" fill="#fee090" fill-opacity="0.8" stroke="#fdae61" stroke-width="2"/>
      <text y="5" font-family="Arial" font-size="14" font-weight="bold" text-anchor="middle" fill="#2c3e50">SWZ</text>
    </g>
    
    <!-- Namibia - Moderate Risk (high climate stress, lower vulnerability) -->
    <g transform="translate(480, 340)">
      <circle r="24" fill="#fee090" fill-opacity="0.8" stroke="#fdae61" stroke-width="2"/>
      <text y="5" font-family="Arial" font-size="14" font-weight="bold" text-anchor="middle" fill="#2c3e50">NAM</text>
    </g>
    
    <!-- Botswana - Lower-Moderate Risk -->
    <g transform="translate(280, 360)">
      <circle r="23" fill="#e0f3f8" fill-opacity="0.8" stroke="#abd9e9" stroke-width="2"/>
      <text y="5" font-family="Arial" font-size="14" font-weight="bold" text-anchor="middle" fill="#2c3e50">BWA</text>
    </g>
    
    <!-- South Africa - Lower Risk (relative) -->
    <g transform="translate(220, 400)">
      <circle r="22" fill="#abd9e9" fill-opacity="0.8" stroke="#74add1" stroke-width="2"/>
      <text y="5" font-family="Arial" font-size="14" font-weight="bold" text-anchor="middle" fill="#2c3e50">ZAF</text>
    </g>
    
    <!-- Axis labels -->
    <text x="400" y="540" font-family="Arial" font-size="14" font-weight="bold" text-anchor="middle" fill="#2c3e50">
      Climate Stress (Temperature + Precipitation Change) →
    </text>
    <text x="-250" y="-40" font-family="Arial" font-size="14" font-weight="bold" text-anchor="middle" fill="#2c3e50" transform="rotate(-90)">
      Socioeconomic Vulnerability →
    </text>
    
    <!-- Risk level labels -->
    <text x="100" y="-15" font-family="Arial" font-size="12" text-anchor="middle" fill="#74add1">Low Climate Stress</text>
    <text x="300" y="-15" font-family="Arial" font-size="12" text-anchor="middle" fill="#fee090">Moderate Stress</text>
    <text x="500" y="-15" font-family="Arial" font-size="12" text-anchor="middle" fill="#f46d43">High Stress</text>
    <text x="700" y="-15" font-family="Arial" font-size="12" text-anchor="middle" fill="#d73027">Extreme Stress</text>
    
    <text x="-20" y="62" font-family="Arial" font-size="12" text-anchor="end" fill="#d73027">Very High Vuln.</text>
    <text x="-20" y="187" font-family="Arial" font-size="12" text-anchor="end" fill="#f46d43">High Vuln.</text>
    <text x="-20" y="312" font-family="Arial" font-size="12" text-anchor="end" fill="#fee090">Moderate Vuln.</text>
    <text x="-20" y="437" font-family="Arial" font-size="12" text-anchor="end" fill="#74add1">Lower Vuln.</text>
  </g>
  
  <!-- Risk Factors Panel -->
  <g transform="translate(950, 120)">
    <rect x="0" y="0" width="350" height="480" fill="white" stroke="#cccccc" stroke-width="1" rx="5"/>
    
    <text x="175" y="30" font-family="Arial" font-size="18" font-weight="bold" text-anchor="middle" fill="#2c3e50">
      Compound Risk Factors
    </text>
    
    <!-- Temperature -->
    <g transform="translate(20, 60)">
      <rect x="0" y="0" width="310" height="100" fill="#fff7ec" stroke="#d73027" stroke-width="1" rx="3"/>
      <text x="10" y="20" font-family="Arial" font-size="14" font-weight="bold" fill="#d73027">Temperature Rise</text>
      <text x="10" y="40" font-family="Arial" font-size="12" fill="#2c3e50">• Current: +0.9 to +1.6°C</text>
      <text x="10" y="58" font-family="Arial" font-size="12" fill="#2c3e50">• 2050: Additional +1.2-1.8°C</text>
      <text x="10" y="76" font-family="Arial" font-size="12" fill="#2c3e50">• Hotspots: Interior regions</text>
      <text x="10" y="94" font-family="Arial" font-size="11" fill="#5a6c7d">→ Heat stress, crop failure risk</text>
    </g>
    
    <!-- Precipitation -->
    <g transform="translate(20, 175)">
      <rect x="0" y="0" width="310" height="100" fill="#fef0d9" stroke="#8c510a" stroke-width="1" rx="3"/>
      <text x="10" y="20" font-family="Arial" font-size="14" font-weight="bold" fill="#8c510a">Precipitation Decline</text>
      <text x="10" y="40" font-family="Arial" font-size="12" fill="#2c3e50">• Annual: -3% to -15%</text>
      <text x="10" y="58" font-family="Arial" font-size="12" fill="#2c3e50">• Wet season: -5% to -18%</text>
      <text x="10" y="76" font-family="Arial" font-size="12" fill="#2c3e50">• Southwest most affected</text>
      <text x="10" y="94" font-family="Arial" font-size="11" fill="#5a6c7d">→ Water stress, drought risk</text>
    </g>
    
    <!-- Vulnerability -->
    <g transform="translate(20, 290)">
      <rect x="0" y="0" width="310" height="100" fill="#f0f9ff" stroke="#4575b4" stroke-width="1" rx="3"/>
      <text x="10" y="20" font-family="Arial" font-size="14" font-weight="bold" fill="#4575b4">Vulnerability Drivers</text>
      <text x="10" y="40" font-family="Arial" font-size="12" fill="#2c3e50">• Food security challenges</text>
      <text x="10" y="58" font-family="Arial" font-size="12" fill="#2c3e50">• Water resource stress</text>
      <text x="10" y="76" font-family="Arial" font-size="12" fill="#2c3e50">• Limited adaptive capacity</text>
      <text x="10" y="94" font-family="Arial" font-size="11" fill="#5a6c7d">→ Amplifies climate impacts</text>
    </g>
    
    <!-- Priority Actions -->
    <text x="175" y="420" font-family="Arial" font-size="14" font-weight="bold" text-anchor="middle" fill="#2c3e50">
      Priority Adaptation Needs
    </text>
    <text x="20" y="445" font-family="Arial" font-size="12" fill="#d73027">• Extreme Risk: MOZ, MDG</text>
    <text x="30" y="462" font-family="Arial" font-size="11" fill="#5a6c7d">Coastal protection, early warning</text>
    <text x="20" y="482" font-family="Arial" font-size="12" fill="#f46d43">• High Risk: ZWE, MWI, ZMB</text>
    <text x="30" y="499" font-family="Arial" font-size="11" fill="#5a6c7d">Agriculture adaptation, water mgmt</text>
    <text x="20" y="519" font-family="Arial" font-size="12" fill="#fdae61">• Moderate: NAM, LSO, SWZ</text>
    <text x="30" y="536" font-family="Arial" font-size="11" fill="#5a6c7d">Drought resilience, infrastructure</text>
  </g>
  
  <!-- Temporal Projection -->
  <g transform="translate(100, 650)">
    <rect x="0" y="0" width="1200" height="180" fill="white" stroke="#333333" stroke-width="2" rx="5"/>
    
    <text x="600" y="30" font-family="Arial" font-size="16" font-weight="bold" text-anchor="middle" fill="#2c3e50">
      Risk Evolution Timeline
    </text>
    
    <!-- Timeline axis -->
    <line x1="100" y1="100" x2="1100" y2="100" stroke="#333333" stroke-width="2"/>
    
    <!-- Time markers -->
    <line x1="100" y1="95" x2="100" y2="105" stroke="#333333" stroke-width="2"/>
    <text x="100" y="125" font-family="Arial" font-size="12" text-anchor="middle" fill="#2c3e50">2020</text>
    
    <line x1="350" y1="95" x2="350" y2="105" stroke="#333333" stroke-width="2"/>
    <text x="350" y="125" font-family="Arial" font-size="12" text-anchor="middle" fill="#2c3e50">2030</text>
    
    <line x1="600" y1="95" x2="600" y2="105" stroke="#333333" stroke-width="2"/>
    <text x="600" y="125" font-family="Arial" font-size="12" text-anchor="middle" fill="#2c3e50">2040</text>
    
    <line x1="850" y1="95" x2="850" y2="105" stroke="#333333" stroke-width="2"/>
    <text x="850" y="125" font-family="Arial" font-size="12" text-anchor="middle" fill="#2c3e50">2050</text>
    
    <line x1="1100" y1="95" x2="1100" y2="105" stroke="#333333" stroke-width="2"/>
    <text x="1100" y="125" font-family="Arial" font-size="12" text-anchor="middle" fill="#2c3e50">2060</text>
    
    <!-- Risk progression curves -->
    <path d="M 100 90 Q 350 85, 600 75 T 1100 50" 
          fill="none" stroke="#d73027" stroke-width="3" opacity="0.7"/>
    <text x="1120" y="55" font-family="Arial" font-size="11" fill="#d73027">Temperature</text>
    
    <path d="M 100 95 Q 350 92, 600 88 T 1100 75" 
          fill="none" stroke="#8c510a" stroke-width="3" opacity="0.7"/>
    <text x="1120" y="80" font-family="Arial" font-size="11" fill="#8c510a">Drought</text>
    
    <path d="M 100 85 Q 350 80, 600 70 T 1100 45" 
          fill="none" stroke="#4575b4" stroke-width="3" opacity="0.7"/>
    <text x="1120" y="50" font-family="Arial" font-size="11" fill="#4575b4">Overall Risk</text>
    
    <!-- Key thresholds -->
    <line x1="400" y1="40" x2="400" y2="100" stroke="#ff0000" stroke-width="1" stroke-dasharray="3,3" opacity="0.5"/>
    <text x="400" y="35" font-family="Arial" font-size="10" text-anchor="middle" fill="#ff0000">+1.5°C</text>
    
    <line x1="750" y1="40" x2="750" y2="100" stroke="#ff0000" stroke-width="1" stroke-dasharray="3,3" opacity="0.5"/>
    <text x="750" y="35" font-family="Arial" font-size="10" text-anchor="middle" fill="#ff0000">+2.0°C</text>
  </g>
  
  <!-- Data attribution -->
  <text x="700" y="870" font-family="Arial" font-size="10" text-anchor="middle" fill="#999999">
    Data Sources: IPCC AR6, World Bank Climate Portal, ND-GAIN Index 2023, SADC Climate Assessment
  </text>
</svg>'''
    
    with open("southern_africa_integrated_climate_risk.svg", "w") as f:
        f.write(svg_content)
    print("Created: southern_africa_integrated_climate_risk.svg")

def create_temporal_change_visualization():
    """Create temporal visualization showing changes over time"""
    
    svg_content = '''<svg width="1200" height="800" xmlns="http://www.w3.org/2000/svg">
  <!-- Background -->
  <rect width="1200" height="800" fill="#f8f9fa"/>
  
  <!-- Title -->
  <text x="600" y="35" font-family="Arial, sans-serif" font-size="24" font-weight="bold" text-anchor="middle" fill="#2c3e50">
    Southern Africa Climate Change Trajectory 1960-2100
  </text>
  <text x="600" y="60" font-family="Arial, sans-serif" font-size="16" text-anchor="middle" fill="#5a6c7d">
    Historical observations and future projections under different scenarios
  </text>
  
  <!-- Main chart area -->
  <g transform="translate(100, 100)">
    <!-- Chart background -->
    <rect x="0" y="0" width="900" height="400" fill="white" stroke="#333333" stroke-width="2"/>
    
    <!-- Grid lines -->
    <line x1="0" y1="100" x2="900" y2="100" stroke="#e0e0e0" stroke-width="1" stroke-dasharray="2,2"/>
    <line x1="0" y1="200" x2="900" y2="200" stroke="#e0e0e0" stroke-width="1" stroke-dasharray="2,2"/>
    <line x1="0" y1="300" x2="900" y2="300" stroke="#e0e0e0" stroke-width="1" stroke-dasharray="2,2"/>
    
    <line x1="150" y1="0" x2="150" y2="400" stroke="#e0e0e0" stroke-width="1" stroke-dasharray="2,2"/>
    <line x1="300" y1="0" x2="300" y2="400" stroke="#e0e0e0" stroke-width="1" stroke-dasharray="2,2"/>
    <line x1="450" y1="0" x2="450" y2="400" stroke="#e0e0e0" stroke-width="1" stroke-dasharray="2,2"/>
    <line x1="600" y1="0" x2="600" y2="400" stroke="#e0e0e0" stroke-width="1" stroke-dasharray="2,2"/>
    <line x1="750" y1="0" x2="750" y2="400" stroke="#e0e0e0" stroke-width="1" stroke-dasharray="2,2"/>
    
    <!-- Historical period background -->
    <rect x="0" y="0" width="450" height="400" fill="#f0f0f0" fill-opacity="0.3"/>
    <text x="225" y="20" font-family="Arial" font-size="12" font-weight="bold" text-anchor="middle" fill="#666666">
      OBSERVED
    </text>
    
    <!-- Future period background -->
    <rect x="450" y="0" width="450" height="400" fill="#fff7ec" fill-opacity="0.3"/>
    <text x="675" y="20" font-family="Arial" font-size="12" font-weight="bold" text-anchor="middle" fill="#d73027">
      PROJECTED
    </text>
    
    <!-- Temperature trends -->
    <!-- Historical observed -->
    <path d="M 0 350 L 150 340 L 300 320 L 450 280" 
          fill="none" stroke="#333333" stroke-width="3"/>
    
    <!-- SSP1-2.6 (Low emissions) -->
    <path d="M 450 280 Q 600 250, 750 240 T 900 235" 
          fill="none" stroke="#4575b4" stroke-width="2" stroke-dasharray="5,3"/>
    
    <!-- SSP2-4.5 (Medium emissions) -->
    <path d="M 450 280 Q 600 220, 750 180 T 900 150" 
          fill="none" stroke="#fdae61" stroke-width="2"/>
    
    <!-- SSP5-8.5 (High emissions) -->
    <path d="M 450 280 Q 600 180, 750 100 T 900 50" 
          fill="none" stroke="#d73027" stroke-width="2" stroke-dasharray="8,4"/>
    
    <!-- Precipitation trends (inverted scale) -->
    <!-- Historical observed -->
    <path d="M 0 200 L 150 210 L 300 225 L 450 245" 
          fill="none" stroke="#8c510a" stroke-width="3" opacity="0.7"/>
    
    <!-- Future projections -->
    <path d="M 450 245 Q 600 265, 750 285 T 900 310" 
          fill="none" stroke="#8c510a" stroke-width="2" opacity="0.5" stroke-dasharray="5,3"/>
    
    <!-- Time axis labels -->
    <text x="0" y="430" font-family="Arial" font-size="12" text-anchor="middle" fill="#2c3e50">1960</text>
    <text x="150" y="430" font-family="Arial" font-size="12" text-anchor="middle" fill="#2c3e50">1980</text>
    <text x="300" y="430" font-family="Arial" font-size="12" text-anchor="middle" fill="#2c3e50">2000</text>
    <text x="450" y="430" font-family="Arial" font-size="12" font-weight="bold" text-anchor="middle" fill="#2c3e50">2020</text>
    <text x="600" y="430" font-family="Arial" font-size="12" text-anchor="middle" fill="#2c3e50">2040</text>
    <text x="750" y="430" font-family="Arial" font-size="12" text-anchor="middle" fill="#2c3e50">2060</text>
    <text x="900" y="430" font-family="Arial" font-size="12" text-anchor="middle" fill="#2c3e50">2080</text>
    
    <!-- Y-axis labels (Temperature) -->
    <text x="-20" y="405" font-family="Arial" font-size="12" text-anchor="end" fill="#2c3e50">0°C</text>
    <text x="-20" y="305" font-family="Arial" font-size="12" text-anchor="end" fill="#2c3e50">+1°C</text>
    <text x="-20" y="205" font-family="Arial" font-size="12" text-anchor="end" fill="#2c3e50">+2°C</text>
    <text x="-20" y="105" font-family="Arial" font-size="12" text-anchor="end" fill="#2c3e50">+3°C</text>
    <text x="-20" y="5" font-family="Arial" font-size="12" text-anchor="end" fill="#2c3e50">+4°C</text>
    
    <!-- Y-axis label -->
    <text x="-50" y="200" font-family="Arial" font-size="13" font-weight="bold" text-anchor="middle" fill="#d73027" transform="rotate(-90, -50, 200)">
      Temperature Anomaly
    </text>
    
    <!-- Secondary Y-axis labels (Precipitation) -->
    <text x="920" y="205" font-family="Arial" font-size="12" text-anchor="start" fill="#8c510a">0%</text>
    <text x="920" y="255" font-family="Arial" font-size="12" text-anchor="start" fill="#8c510a">-5%</text>
    <text x="920" y="305" font-family="Arial" font-size="12" text-anchor="start" fill="#8c510a">-10%</text>
    <text x="920" y="355" font-family="Arial" font-size="12" text-anchor="start" fill="#8c510a">-15%</text>
    
    <!-- Secondary Y-axis label -->
    <text x="960" y="280" font-family="Arial" font-size="13" font-weight="bold" text-anchor="middle" fill="#8c510a" transform="rotate(90, 960, 280)">
      Precipitation Change
    </text>
    
    <!-- Key events and thresholds -->
    <line x1="450" y1="0" x2="450" y2="400" stroke="#ff0000" stroke-width="2"/>
    <text x="450" y="-10" font-family="Arial" font-size="11" font-weight="bold" text-anchor="middle" fill="#ff0000">Present</text>
    
    <!-- Paris Agreement targets -->
    <line x1="0" y1="280" x2="900" y2="280" stroke="#22aa22" stroke-width="1" stroke-dasharray="5,5" opacity="0.5"/>
    <text x="910" y="283" font-family="Arial" font-size="10" fill="#22aa22">+1.5°C target</text>
    
    <line x1="0" y1="200" x2="900" y2="200" stroke="#ff8800" stroke-width="1" stroke-dasharray="5,5" opacity="0.5"/>
    <text x="910" y="203" font-family="Arial" font-size="10" fill="#ff8800">+2.0°C target</text>
  </g>
  
  <!-- Scenario Legend -->
  <g transform="translate(1050, 150)">
    <rect x="-10" y="-10" width="140" height="150" fill="white" stroke="#cccccc" stroke-width="1" rx="5"/>
    
    <text x="60" y="10" font-family="Arial" font-size="14" font-weight="bold" text-anchor="middle" fill="#2c3e50">
      Scenarios
    </text>
    
    <line x1="10" y1="30" x2="40" y2="30" stroke="#333333" stroke-width="3"/>
    <text x="45" y="35" font-family="Arial" font-size="12" fill="#2c3e50">Historical</text>
    
    <line x1="10" y1="55" x2="40" y2="55" stroke="#4575b4" stroke-width="2" stroke-dasharray="5,3"/>
    <text x="45" y="60" font-family="Arial" font-size="12" fill="#4575b4">SSP1-2.6</text>
    <text x="45" y="75" font-family="Arial" font-size="10" fill="#666">(Sustainable)</text>
    
    <line x1="10" y1="90" x2="40" y2="90" stroke="#fdae61" stroke-width="2"/>
    <text x="45" y="95" font-family="Arial" font-size="12" fill="#fdae61">SSP2-4.5</text>
    <text x="45" y="110" font-family="Arial" font-size="10" fill="#666">(Middle Road)</text>
    
    <line x1="10" y1="125" x2="40" y2="125" stroke="#d73027" stroke-width="2" stroke-dasharray="8,4"/>
    <text x="45" y="130" font-family="Arial" font-size="12" fill="#d73027">SSP5-8.5</text>
    <text x="45" y="145" font-family="Arial" font-size="10" fill="#666">(Fossil-fueled)</text>
  </g>
  
  <!-- Impact Boxes -->
  <g transform="translate(100, 550)">
    <!-- Temperature Impacts -->
    <rect x="0" y="0" width="280" height="150" fill="#fff7ec" stroke="#d73027" stroke-width="2" rx="5"/>
    <text x="140" y="25" font-family="Arial" font-size="14" font-weight="bold" text-anchor="middle" fill="#d73027">
      Temperature Impacts by 2050
    </text>
    <text x="15" y="50" font-family="Arial" font-size="12" fill="#2c3e50">• Heat waves: +20-30 days/year</text>
    <text x="15" y="70" font-family="Arial" font-size="12" fill="#2c3e50">• Growing season: -10 to -20 days</text>
    <text x="15" y="90" font-family="Arial" font-size="12" fill="#2c3e50">• Evapotranspiration: +15-25%</text>
    <text x="15" y="110" font-family="Arial" font-size="12" fill="#2c3e50">• Heat stress days: Double</text>
    <text x="15" y="130" font-family="Arial" font-size="11" font-style="italic" fill="#666">Regional average under SSP2-4.5</text>
  </g>
  
  <g transform="translate(420, 550)">
    <!-- Precipitation Impacts -->
    <rect x="0" y="0" width="280" height="150" fill="#fef0d9" stroke="#8c510a" stroke-width="2" rx="5"/>
    <text x="140" y="25" font-family="Arial" font-size="14" font-weight="bold" text-anchor="middle" fill="#8c510a">
      Precipitation Impacts by 2050
    </text>
    <text x="15" y="50" font-family="Arial" font-size="12" fill="#2c3e50">• Drought frequency: +40%</text>
    <text x="15" y="70" font-family="Arial" font-size="12" fill="#2c3e50">• Flood intensity: +25%</text>
    <text x="15" y="90" font-family="Arial" font-size="12" fill="#2c3e50">• Dry spells: +15-20 days</text>
    <text x="15" y="110" font-family="Arial" font-size="12" fill="#2c3e50">• Seasonal shift: 2-4 weeks</text>
    <text x="15" y="130" font-family="Arial" font-size="11" font-style="italic" fill="#666">Higher variability expected</text>
  </g>
  
  <g transform="translate(740, 550)">
    <!-- Compound Impacts -->
    <rect x="0" y="0" width="280" height="150" fill="#f0f9ff" stroke="#4575b4" stroke-width="2" rx="5"/>
    <text x="140" y="25" font-family="Arial" font-size="14" font-weight="bold" text-anchor="middle" fill="#4575b4">
      Compound Risks by 2050
    </text>
    <text x="15" y="50" font-family="Arial" font-size="12" fill="#2c3e50">• Crop yields: -20% to -30%</text>
    <text x="15" y="70" font-family="Arial" font-size="12" fill="#2c3e50">• Water availability: -25%</text>
    <text x="15" y="90" font-family="Arial" font-size="12" fill="#2c3e50">• Migration risk: High</text>
    <text x="15" y="110" font-family="Arial" font-size="12" fill="#2c3e50">• GDP impact: -5% to -8%</text>
    <text x="15" y="130" font-family="Arial" font-size="11" font-style="italic" fill="#666">Without adaptation measures</text>
  </g>
  
  <!-- Attribution -->
  <text x="600" y="760" font-family="Arial" font-size="10" text-anchor="middle" fill="#999">
    Data: IPCC AR6 WGI/II, CMIP6 Multi-model Ensemble, SADC Regional Climate Projections
  </text>
</svg>'''
    
    with open("southern_africa_temporal_climate_change.svg", "w") as f:
        f.write(svg_content)
    print("Created: southern_africa_temporal_climate_change.svg")

# Main execution
if __name__ == "__main__":
    print("Creating Southern Africa Climate Data Visualizations...")
    print("=" * 50)
    
    create_temperature_anomaly_map()
    create_precipitation_change_map()
    create_vulnerability_index_map()
    create_integrated_climate_risk_diagram()
    create_temporal_change_visualization()
    
    print("=" * 50)
    print("All visualizations created successfully!")
    print("\nFiles created:")
    print("1. southern_africa_temperature_anomaly.svg")
    print("2. southern_africa_precipitation_change.svg")
    print("3. southern_africa_vulnerability_index.svg")
    print("4. southern_africa_integrated_climate_risk.svg")
    print("5. southern_africa_temporal_climate_change.svg")
    print("\nThese SVG files can be imported directly into Figma for further refinement.")