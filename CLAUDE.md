# RP2 Climate Presentation Repository

Research Portfolio 2 (RP2) climate analysis and presentation materials for Southern Africa heat health studies.

## Repository Structure

```
RP2_presentation/
├── presentation_assets/      # Main assets directory
│   ├── data/                # Climate and vulnerability datasets
│   │   ├── climate/         # Climate data (World Bank API, CRU TS, Köppen)
│   │   └── vulnerability/   # Vulnerability indices (ND-GAIN, INFORM, IPCC)
│   │
│   ├── images/              # Visualizations and maps
│   │   ├── koppen_extracted/    # Köppen climate classification data
│   │   ├── high_res_koppen/     # High-resolution climate zones
│   │   └── *.svg/png           # Climate maps and diagrams
│   │
│   └── archive/             # Previous presentation versions
│
├── *.html                   # Interactive presentations
├── *.ipynb                  # Jupyter notebooks for analysis
└── *.pdf/pptx              # Final presentations
```

## Key Components

### Climate Data Analysis
- Köppen-Geiger climate classification for Southern Africa
- Temperature and precipitation trends
- Future climate projections (SSP scenarios)
- Urban heat island effects

### Study Locations
Primary cities:
- Johannesburg, South Africa
- Abidjan, Côte d'Ivoire
- Cape Town, South Africa
- Durban, South Africa

### Vulnerability Assessment
- Heat Vulnerability Index (HVI)
- ND-GAIN Country Index
- INFORM Risk Index
- IPCC regional assessments

## Data Sources

### Climate Data
- **World Bank Climate Change Knowledge Portal**: API access for temperature, precipitation, and extreme indices
- **CRU TS 4.08**: 0.5° gridded historical climate data
- **Köppen-Geiger**: Climate classification at multiple resolutions

### Vulnerability Indices
- **ND-GAIN**: Notre Dame Global Adaptation Initiative
- **INFORM**: EU Joint Research Centre risk assessment
- **IPCC AR6**: Regional climate risk assessments

## Quick Start

### Fetching Climate Data
```bash
cd presentation_assets/data/climate/worldbank_api
python fetch_climate_data.py
```

### Viewing Presentations
Open any `.html` file in a browser for interactive presentations.

### Running Analysis
Jupyter notebooks in `presentation_assets/images/` contain detailed analyses.

## Recent Updates
- Added World Bank Climate API integration
- Organized data structure for climate and vulnerability datasets
- Created condensed Köppen climate visualizations
- Integrated ND-GAIN vulnerability data

## Contact
Craig Parker - Urban heat health and climate vulnerability research