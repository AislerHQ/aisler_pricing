# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.6.0] - 2023-05-04
### Changed:
- Removed AislerPricing.update_rates
- Rates are updated on initialization if not set
- Requires already set configuration of Money Gem