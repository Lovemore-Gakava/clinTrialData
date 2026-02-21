# Package index

## Data Access Functions

Functions for connecting to and accessing clinical trial data

- [`connect_clinical_data()`](https://lovemore-gakava.github.io/clinTrialData/reference/connect_clinical_data.md)
  : Connect to Clinical Data by Source
- [`list_data_sources()`](https://lovemore-gakava.github.io/clinTrialData/reference/list_data_sources.md)
  : List Available Clinical Data Sources
- [`dataset_info()`](https://lovemore-gakava.github.io/clinTrialData/reference/dataset_info.md)
  : Inspect a Clinical Trial Dataset Without Downloading

## Download & Cache

Functions for downloading studies from GitHub Releases

- [`download_study()`](https://lovemore-gakava.github.io/clinTrialData/reference/download_study.md)
  : Download a Clinical Trial Study Dataset
- [`list_available_studies()`](https://lovemore-gakava.github.io/clinTrialData/reference/list_available_studies.md)
  : List Studies Available for Download
- [`cache_dir()`](https://lovemore-gakava.github.io/clinTrialData/reference/cache_dir.md)
  : Get the Local Cache Directory

## Datasets

Clinical trial datasets included in the package

- [`clinTrialData-data`](https://lovemore-gakava.github.io/clinTrialData/reference/clinTrialData-data.md)
  [`clinical-data`](https://lovemore-gakava.github.io/clinTrialData/reference/clinTrialData-data.md)
  [`cdisc-pilot`](https://lovemore-gakava.github.io/clinTrialData/reference/clinTrialData-data.md)
  : Clinical Trial Datasets

## Lock Protection

Internal functions for data protection

- [`remove_cnt(`*`<ConnectorLockedFS>`*`)`](https://lovemore-gakava.github.io/clinTrialData/reference/remove_cnt.ConnectorLockedFS.md)
  : Remove Content with Lock Check
- [`write_cnt(`*`<ConnectorLockedFS>`*`)`](https://lovemore-gakava.github.io/clinTrialData/reference/write_cnt.ConnectorLockedFS.md)
  : Write Content with Lock Check
