# Diagonal-Based Inference for Archimax Copulas

This repository contains the R code reproducing all simulations, the
hydrological application, and the figures in the paper:

> Bahraoui, T. (2026). *Diagonal-Based Inference for Archimax Copulas.*
> Journal of Multivariate Analysis, under revision.

## Structure

| File | Purpose |
|------|---------|
| `00_install_packages.R` | Install and load required R packages |
| `01_archimax_utilities.R` | Core functions: generators, Pickands functions, cdf, sampling, empirical copula, c_A estimator, test statistic, bootstrap, scan statistic |
| `02_simulation_study.R` | Tables 1–3 (level, power, discrete component detection) |
| `03_hierarchical_simulation.R` | Table 5 / Table S3 (FWER and FDR) |
| `04_application_flood_data.R` | Section 7 (Châteauguay River application) |
| `05_figures.R` | All figures |
| `06_supplementary_tables.R` | Tables S2, S5 (multiplier robustness, oracle comparison) |

## Example figure and results

To create a small, reproducible example of the theoretical diagonal curves
and a corresponding results table, run this from the repository root:

```sh
Rscript examples/archimax_figure_results.R
```

The script writes `figures/example_diagonal.pdf` and
`results/example_diagonal.csv`. It compares the Gumbel, Clayton, and Frank
generator cases with the Gumbel-Hougaard Pickands function at the paper's
`tau = 0.5` calibration. The CSV reports the model parameters, the diagonal
multiplier `m`, and the theoretical diagonal value at `t = 0.5`. This is an
illustrative theoretical example, not a result computed from the flood data
or a Monte Carlo simulation.

## How to run

1. Clone or download this repository.
2. Open R or RStudio in the repository root.
3. Run `00_install_packages.R` once to install dependencies.
4. Run any of the numbered scripts. Each is self-contained (it sources
   `01_archimax_utilities.R` internally).

The full simulation study takes about 4 hours on a 12-core machine when
parallelised; individual cells run in under 30 seconds.

## Data

The hydrological data are not included in this repository; the file
`data/chateauguay_flood.csv` must have two columns, `Q_max` and `V`,
with 97 rows (spring flood peak and volume for 1935–2024). The raw data
are available from Environment and Climate Change Canada at
[wateroffice.ec.gc.ca](https://wateroffice.ec.gc.ca/), station 02OA054.

## Reproducibility

All scripts use the seed `20250428`. Results should be bit-for-bit
reproducible on the same R version and platform.

## License

MIT License (see LICENSE file).

## Citation

If you use this code, please cite the paper above.
