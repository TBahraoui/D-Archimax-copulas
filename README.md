# Diagonal-Based Inference for Archimax Copulas

This repository is intended for Archimax copula methods. The self-contained example below illustrates a bivariate Archimax copula using a CDF heatmap, density heatmap/contours, simulated pseudo-observations, and a diagonal-section comparison.

> **Repository status:** the R package metadata and several legacy `R/` files in this repository still describe a binary quadratic copula, and `todo-app/` is unrelated. The Archimax visualization script below is standalone and does not use those files. The repository has not yet been fully cleaned or converted into an Archimax R package.

## Run the Archimax visualization example

Requires base R only (no extra packages). From the repository root, run:

```sh
Rscript examples/archimax_visualizations.R
```

The script writes:

- `figures/archimax_cdf_heatmap_contour.png` — copula CDF heatmap with contour lines.
- `figures/archimax_density_heatmap_contour.png` — numerically approximated copula density heatmap with density contours.
- `figures/archimax_pseudo_observations_diagonal.png` — simulated pseudo-observations and empirical/theoretical diagonal sections.
- `results/archimax_pseudo_observations.csv` — simulated observations transformed to rank-based pseudo-observations.
- `results/archimax_diagonal.csv` — theoretical and empirical diagonal values on the plotting grid.

The figures are generated when you run the script; they are not precomputed image files in the repository.

## Model used in the example

For `u, v` in `(0, 1]`, the bivariate Archimax CDF is

```text
C(u,v) = phi((psi(u) + psi(v)) A(psi(u) / (psi(u) + psi(v))))
```

The illustration uses the Gumbel generator and inverse

```text
psi(u) = (-log u)^theta,       phi(x) = exp(-x^(1/theta))
```

and the Gumbel-Hougaard Pickands dependence function

```text
A(w) = (w^kappa + (1-w)^kappa)^(1/kappa),  0 <= w <= 1.
```

The example sets `theta = 2` and `kappa = 2`. The diagonal section is `delta(t) = C(t,t)`. In the pseudo-observation panel, the sample diagonal estimator is `C_n(t,t) = mean(U_i <= t, V_i <= t)` and is compared with the theoretical diagonal. Simulated copula observations are converted to rank-based pseudo-observations using `rank(x)/(n+1)`.

### Reading the plots

- **CDF heatmap and contours:** color and contour levels show the value of `C(u,v)`, the joint probability `P(U <= u, V <= v)`. These are not density contours.
- **Density heatmap and contours:** colors show a finite-difference approximation to `c(u,v) = partial^2 C(u,v)/(partial u partial v)`. A high percentile is used as the color-scale limit so that peaks do not wash out the rest of the plot; the script clips colors, not the underlying calculation. Numerical differentiation can be noisy near the boundaries, so interpret edge values cautiously.
- **Pseudo-observations and diagonal:** each point is a rank-transformed simulated observation. The right panel compares the empirical diagonal from that sample with the theoretical diagonal; this is a simulation illustration, not observed-data inference.

All plots are theoretical/simulation examples. They do not use empirical data or estimate parameters from a dataset.

## Existing examples

`BQC.R` is a separate standalone CDF heatmap/contour script. `examples/archimax_figure_results.R` illustrates theoretical diagonal curves for several generator choices and writes a CSV of its illustrative parameter values.
