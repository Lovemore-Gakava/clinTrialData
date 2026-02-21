# Clinical Trial Datasets

The clinTrialData package contains clinical trial datasets from multiple
sources, stored in Parquet format. Data is accessed using connector
functions.

## Source

CDISC Pilot 01 Study Data Various clinical trial data sources

## Available Data Sources

### CDISC Pilot 01 Study

The CDISC Pilot 01 study data includes both ADaM and SDTM domains.

**ADaM datasets include:**

- ADSL: Subject-Level Analysis Dataset

- ADAE: Adverse Events Analysis Dataset

- ADLB: Laboratory Analysis Dataset (combined)

- ADLBC: Laboratory Analysis Dataset (Chemistry)

- ADLBH: Laboratory Analysis Dataset (Hematology)

- ADLBHY: Laboratory Analysis Dataset (Hy's Law)

- ADQSADAS: ADAS-Cog Questionnaire Analysis Dataset

- ADQSCIBC: CIBC Questionnaire Analysis Dataset

- ADQSNPIX: NPI-X Questionnaire Analysis Dataset

- ADTTE: Time-to-Event Analysis Dataset

- ADVS: Vital Signs Analysis Dataset

**SDTM datasets include:**

- DM: Demographics

- AE: Adverse Events

- VS: Vital Signs

- LB: Laboratory Test Results

- And 18 additional domains (see
  [`list_data_sources()`](https://lovemore-gakava.github.io/clinTrialData/reference/list_data_sources.md)
  for details)

## Usage

Data sources are discovered by scanning the package directory structure.
List available datasets with
[`list_data_sources()`](https://lovemore-gakava.github.io/clinTrialData/reference/list_data_sources.md).

Access data using the connection function:

    # Connect to any data source (e.g., CDISC Pilot data)
    db <- connect_clinical_data("cdisc_pilot")

    # List available datasets
    db$adam$list_content_cnt()

    # Read a dataset
    adsl <- db$adam$read_cnt("adsl")

    # See all available data sources
    list_data_sources()

## Data Format

Datasets are stored in Parquet format:

- Columnar storage

- Fast reads

- Compression

- Cross-platform compatibility

## References

CDISC. Clinical Data Interchange Standards Consortium.
<https://www.cdisc.org/>
