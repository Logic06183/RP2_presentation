# World Bank Climate API Endpoints for Southern Africa

## Base URL
```
https://cckpapi.worldbank.org/cckp/v1/
```

## Country Codes (ISO3)
- **AGO** - Angola
- **BWA** - Botswana  
- **COM** - Comoros
- **SWZ** - Eswatini (Swaziland)
- **LSO** - Lesotho
- **MDG** - Madagascar
- **MWI** - Malawi
- **MUS** - Mauritius
- **MOZ** - Mozambique
- **NAM** - Namibia
- **SYC** - Seychelles
- **ZAF** - South Africa
- **TZA** - Tanzania
- **ZMB** - Zambia
- **ZWE** - Zimbabwe

## City/Sub-national Codes
- **Johannesburg**: ZAF.2593214
- **Cape Town**: ZAF.2593215
- **Durban**: ZAF.2593217
- **Pretoria**: ZAF.2593216

## Example API Calls

### Historical Temperature (CRU TS 0.5°)
```bash
# Annual mean temperature for South Africa (1991-2020)
https://cckpapi.worldbank.org/cckp/v1/cru-x0.5_climatology_tas_climatology_annual_1991-2020_mean_historical_mean/all/ZAF?_format=json

# Monthly temperature for Johannesburg
https://cckpapi.worldbank.org/cckp/v1/cru-x0.5_climatology_tas,tasmax,tasmin_climatology_monthly_1991-2020_mean_historical_mean/all/ZAF.2593214?_format=json
```

### Historical Precipitation
```bash
# Annual precipitation for Zimbabwe
https://cckpapi.worldbank.org/cckp/v1/cru-x0.5_climatology_pr_climatology_annual_1991-2020_mean_historical_mean/all/ZWE?_format=json

# Extreme precipitation (rx5day) for Mozambique
https://cckpapi.worldbank.org/cckp/v1/cru-x0.5_extremes_rx5day_absolute_model-median_annual_1991-2020_mean_historical_mean/all/MOZ?_format=json
```

### Future Projections (CMIP6 0.25°)
```bash
# Temperature projection for Botswana (SSP245, 2040-2059)
https://cckpapi.worldbank.org/cckp/v1/cmip6-x0.25_climatology_tas_anomaly_annual_2040-2059_median_ssp245_ensemble_all_mean/BWA?_format=json

# Precipitation change for Madagascar (SSP585, 2080-2099)
https://cckpapi.worldbank.org/cckp/v1/cmip6-x0.25_climatology_pr_anomaly_annual_2080-2099_median_ssp585_ensemble_all_mean/MDG?_format=json
```

### Heat Indices
```bash
# Hot days (>35°C) for Namibia
https://cckpapi.worldbank.org/cckp/v1/cmip6-x1.0_extremes_hd35_absolute_model-median_annual_2040-2059_mean_ssp245_mean/all/NAM?_format=json

# Heat index days for South Africa
https://cckpapi.worldbank.org/cckp/v1/cmip6-x1.0_extremes_hi35_absolute_model-median_annual_2040-2059_mean_ssp245_mean/all/ZAF?_format=json
```

### Drought Indices
```bash
# SPEI drought index for Zambia
https://cckpapi.worldbank.org/cckp/v1/cmip6-x0.25_drought_spei12_absolute_annual_2040-2059_median_ssp245_ensemble_all_mean/ZMB?_format=json

# Consecutive dry days for Lesotho
https://cckpapi.worldbank.org/cckp/v1/cmip6-x1.0_extremes_cdd_absolute_model-median_annual_2040-2059_mean_ssp245_mean/all/LSO?_format=json
```

## API Parameters

### Collections
- `cru-x0.5` - Historical observations (0.5° resolution)
- `cmip6-x0.25` - Future projections (0.25° resolution)
- `cmip6-x1.0` - Extreme indices (1.0° resolution)
- `era5-x0.25` - ERA5 reanalysis data

### Key Variables
- **Temperature**: tas, tasmax, tasmin
- **Precipitation**: pr, rx1day, rx5day, r20mm
- **Heat**: hd30, hd35, hd40, hi35, tr, tr23
- **Drought**: spei12, cdd, cwd

### Time Periods
- Historical: 1901-1930, 1931-1960, 1961-1990, 1991-2020
- Future: 2020-2039, 2040-2059, 2060-2079, 2080-2099

### SSP Scenarios
- `ssp119` - Very low emissions
- `ssp126` - Low emissions  
- `ssp245` - Medium emissions
- `ssp370` - Medium-high emissions
- `ssp585` - High emissions

### Aggregations
- `annual` - Yearly averages
- `monthly` - Monthly averages
- `seasonal` - DJF, MAM, JJA, SON

## Batch Downloads

For all countries in a region:
```bash
# All Southern Africa countries (use region codes)
https://cckpapi.worldbank.org/cckp/v1/cmip6-x0.25_climatology_tas_climatology_annual_2040-2059_median_ssp245_ensemble_all_mean/region_AFE?_format=json
```

## Output Formats
- `?_format=json` - JSON format (recommended)
- `?_format=xls` - Excel format
- `?_format=csv` - CSV format

## Rate Limits
- Respect API rate limits
- Add delays between requests (1-2 seconds recommended)
- Cache responses locally to avoid repeated calls

## Python Example
```python
import requests
import json

# Fetch temperature data for South Africa
url = "https://cckpapi.worldbank.org/cckp/v1/cru-x0.5_climatology_tas_climatology_annual_1991-2020_mean_historical_mean/all/ZAF"
response = requests.get(url, params={"_format": "json"})
data = response.json()

# Save to file
with open("south_africa_temperature.json", "w") as f:
    json.dump(data, f, indent=2)
```