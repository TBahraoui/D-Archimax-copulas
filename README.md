# Diagonal-Based Inference for Archimax Copulas

This repository is intended for the Archimax copula project. It includes a reproducible theoretical example that plots a bivariate Archimax copula as both a heatmap and contour plot.

## Example: contour and heatmap

Run from the repository root with R:

```sh
Rscript examples/archimax_contour_heatmap.R
```

The script writes `figures/archimax_contour_heatmap.png` and `.pdf`. It uses a Gumbel Archimedean generator and a Gumbel-Hougaard Pickands dependence function, with parameters `theta = 2` and `kappa = 2`. The plotted quantity is the copula CDF `C(u, v)` on the unit square; contour lines show equal CDF values. This is a theoretical illustration, not a fit to empirical data.

The bivariate Archimax construction used is

`C(u,v) = phi((psi(u) + psi(v)) A(psi(u) / (psi(u) + psi(v))))`,

with `psi(u) = (-log(u))^theta`, `phi(x) = exp(-x^(1/theta))`, and `A(w) = (w^kappa + (1-w)^kappa)^(1/kappa)`.

## Repository cleanup note

The repository currently still contains legacy binary-quadratic-copula R source and an unrelated `todo-app/` directory. They are not used by the standalone Archimax plotting example. They need to be removed or replaced in a separate cleanup; the available repository-writing interface here cannot delete files or directories. Until that cleanup is completed, the repository should not be treated as a clean Archimax-only R package.
