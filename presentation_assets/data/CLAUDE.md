# Climate and Vulnerability Data Organization

This directory contains organized climate and vulnerability datasets for Southern Africa analysis.

## Directory Structure

```
data/
├── climate/              # Climate datasets
│   ├── worldbank_api/   # World Bank Climate Change Knowledge Portal data
│   ├── cru_ts/          # CRU TS gridded climate data (0.5° resolution)
│   └── koppen/          # Köppen-Geiger climate classification data
│
└── vulnerability/        # Vulnerability assessment datasets
    ├── nd_gain/         # Notre Dame GAIN Country Index
    ├── inform/          # INFORM Risk Index
    └── ipcc/            # IPCC vulnerability assessments
```

## Available Datasets

### Climate Data

1. **World Bank Climate API**
   - Historical temperature and precipitation (CRU TS)
   - Future projections (CMIP6)
   - Extreme climate indices
   - Access via `fetch_climate_data.py`

2. **Köppen-Geiger Classification**
   - Historical periods: 1901-2020 
   - Future projections: 2041-2099
   - Multiple SSP scenarios
   - Located in `images/koppen_extracted/`

### Vulnerability Data

1. **ND-GAIN Index**
   - Country-level vulnerability scores
   - Readiness indicators
   - 2004-2023 time series
   - Located in `vulnerability/nd_gain/`

## Quick Start

To fetch climate data from World Bank API:
```bash
cd data/climate/worldbank_api
python fetch_climate_data.py
```

## Data Sources

- World Bank CCKP: https://climateknowledgeportal.worldbank.org
- CRU TS: https://crudata.uea.ac.uk/cru/data/hrg/
- ND-GAIN: https://gain.nd.edu/
- INFORM: https://drmkc.jrc.ec.europa.eu/inform-index