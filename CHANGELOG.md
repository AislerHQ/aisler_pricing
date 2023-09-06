# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.1.5] - 2023-09-07
### Changed:
- Explcitly init money prices to DEFAULT_CURRENCY (hence we set base our prices on EUROs)

### Fixed: 
- Exchange all prices to the requested currency if given.

## [2.0.0 - 2.1.4]
### Omitted

## [2.0.0] - 2023-06-01
### Changed:
- Removed AislerPricing.update_rates
- Breaking Change: Requires already set configuration of Money Gem