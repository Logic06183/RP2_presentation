# World Bank Climate Data Metadata

## Data Sources

### CRU TS v4.08 (Historical Observations)
- **Resolution**: 0.5° x 0.5° grid
- **Coverage**: Global land areas except Antarctica
- **Time Period**: 1901-2023
- **Variables**: Temperature (tas, tasmax, tasmin), Precipitation (pr)
- **Reference Periods**: 1901-1930, 1931-1960, 1961-1990, 1985-2014, 1991-2020

### ERA5 (Reanalysis)
- **Resolution**: 0.25° x 0.25° grid  
- **Coverage**: Global
- **Time Period**: 1950-2023
- **Variables**: Comprehensive atmospheric parameters
- **Best for**: Areas with limited station coverage

### CMIP6 (Future Projections)
- **Resolution**: 0.25° x 0.25° (bias-corrected and downscaled)
- **Time Period**: 1950-2100
- **Scenarios**: SSP1-1.9, SSP1-2.6, SSP2-4.5, SSP3-7.0, SSP5-8.5
- **Models**: 30 GCMs
- **Projection Periods**: 2020-2039, 2040-2059, 2060-2079, 2080-2099

## Key Climate Indicators for Southern Africa

### Temperature Indicators
- `tas` - Average mean surface air temperature (°C)
- `tasmax` - Average maximum surface air temperature (°C)
- `tasmin` - Average minimum surface air temperature (°C)
- `txx` - Maximum of daily max-temperature (°C)
- `tnn` - Minimum of daily min-temperature (°C)

### Heat Stress Indicators
- `hd30` - Number of hot days (Tmax > 30°C)
- `hd35` - Number of hot days (Tmax > 35°C)
- `hd40` - Number of hot days (Tmax > 40°C)
- `tr` - Number of tropical nights (Tmin > 20°C)
- `hi35` - Number of days with heat index > 35°C
- `wbt` - Wet bulb temperature (°C)

### Precipitation Indicators
- `pr` - Accumulated precipitation (mm)
- `prpercnt` - Precipitation percent change (%)
- `rx1day` - Largest 1-day precipitation (mm)
- `rx5day` - Largest 5-day cumulative precipitation (mm)
- `r20mm` - Days with precipitation >20mm
- `r50mm` - Days with precipitation >50mm

### Drought Indicators
- `spei12` - Annual SPEI drought index
- `cdd` - Consecutive dry days
- `cwd` - Consecutive wet days

### Extreme Events
- `wsdi` - Warm spell duration index (days)
- `csdi` - Cold spell duration index (days)
- `fd` - Frost days (Tmin < 0°C)

## Vulnerability Indicators
- `popcount` - Population count
- `popdensity` - Population density
- `pov190` - Population below $1.90/day (%)
- `pov320` - Population below $3.20/day (%)
- `hdtrpopdensitycat` - Heat + population risk categorization

## Data Products

### Time Series
Full temporal data at pixel and aggregated levels

### Climatology
20-year averages for historical and future periods

### Anomaly
Changes relative to 1995-2014 baseline

### Trends
Decadal changes with significance testing

### Natural Variability
Historical climate variability thresholds

## SSP Scenarios

| Scenario | Description | Warming by 2100 |
|----------|-------------|-----------------|
| SSP1-1.9 | Most optimistic, Paris Agreement | ~1.5°C |
| SSP1-2.6 | Strong mitigation | ~2°C |
| SSP2-4.5 | Middle of the road | ~2.7°C |
| SSP3-7.0 | Regional rivalry | ~3.6°C |
| SSP5-8.5 | Fossil-fueled development | ~4.4°C |

## Data Quality Notes

- CRU TS data quality varies with station density
- ERA5 recommended for areas with limited observations
- CMIP6 projections bias-corrected using quantile mapping
- Extreme precipitation available at 1.0° resolution
- Uncertainty increases with projection time horizon