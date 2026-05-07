# quadcopula: Binary Quadratic Copula Models

## Overview

`quadcopula` is an R package implementing binary quadratic copula models for modeling complex nonlinear dependence structures in high-dimensional binary data. The package is based on the paper:

> **Binary Quadratic Copulas with Genomic Applications** 
> Bahraoui et al. (2026)

## Key Features

- **Model Definition**: Binary quadratic copula model based on latent Gaussian variables transformed via quadratic forms
- **Full Identifiability**: Theoretical guarantees for identifiability under high-dimensional scaling
- **Oracle Properties**: Penalized pseudolikelihood estimation achieves oracle properties with Frobenius error $O_P(s\log d/n)$
- **Bootstrap Inference**: Multiplier bootstrap for confidence bands and hypothesis testing
- **Goodness-of-Fit Testing**: Parametric bootstrap test for quadratic vs Gaussian copula
- **Power Analysis**: Empirical power surface as function of interaction strength and marginal probabilities
- **Computational Efficiency**: Coordinate descent algorithm with $O(nd^2)$ complexity per iteration
- **Genomic Applications**: Designed for gene expression and single-cell RNA-seq data

## Installation

```r
# From GitHub
devtools::install_github("TBahraoui/quadcopula")

# Or from source
install.packages("path/to/quadcopula_0.1.0.tar.gz", repos = NULL, type = "source")
```

## Quick Start

### Simulate Data

```r
library(quadcopula)

# Define parameters
d <- 20  # number of variables
n <- 500  # sample size

# Correlation matrix
rho <- diag(d)
rho[1:2, 1:2] <- 0.5

# Interaction matrix (quadratic form)
Omega <- diag(1, d)
Omega[1, 2] <- Omega[2, 1] <- 0.3  # nonlinear interaction

# Generate data
X <- simulate_qcopula(
  n = n, d = d,
  rho = rho, Omega = Omega,
  a = rep(-1, d),
  b = rep(1.5, d),
  thresholds = rep(0, d)
)
```

### Fit Model

```r
# Estimate parameters
fit <- fit_qcopula(X, lambda = 0.1, verbose = TRUE)

# Extract estimated interactions
edges <- extract_edges(fit)
head(edges)

# Compute metrics
metrics <- support_recovery_metrics(Omega, fit$theta$Omega)
print(metrics)
```

### Bootstrap Inference

```r
# Bootstrap confidence bands
boot_result <- bootstrap_inference(X, fit, n_bootstrap = 1000)

# Plot confidence band
plot(boot_result$confidence_band$x, boot_result$confidence_band$F,
     type = "l", main = "Quadratic Form CDF with 95% Confidence Bands")
lines(boot_result$confidence_band$x, boot_result$confidence_band$lower, 
      lty = 2, col = "red")
lines(boot_result$confidence_band$x, boot_result$confidence_band$upper, 
      lty = 2, col = "red")
```

### Goodness-of-Fit Test

```r
# Test quadratic copula vs Gaussian copula
gof_result <- goodness_of_fit_test(X, fit, n_bootstrap = 1000)
print(paste("p-value:", gof_result$p_value))

# Visualize bootstrap test statistics
hist(gof_result$bootstrap_statistics, main = "Bootstrap Test Statistics")
abline(v = gof_result$test_statistic, col = "red", lwd = 2)
```

### Power Analysis

```r
# Compute power surface
power <- compute_power_surface(
  omega_seq = seq(0.05, 0.5, 0.05),
  p_seq = seq(0.1, 0.9, 0.1),
  d = 100, n = 500, n_sims = 50
)

# Visualize
plot_power_surface(power, contour_levels = c(0.5, 0.8, 0.95))
```

### Cross-Validation

```r
# Model selection via cross-validation
cv_result <- cv_qcopula(X, 
                        lambda_seq = exp(seq(-4, -1, 0.5)),
                        n_folds = 5)

print(paste("Selected lambda:", cv_result$lambda_best))
plot_cv(cv_result)
```

## Theoretical Properties

### Model

For latent Gaussian $\mathbf{Z} \sim \mathcal{N}_d(\mathbf{0}, \rho)$:

$$Y_j = a_j + b_j Z_j + c_j Z_j^2$$

Observed binary outcomes:

$$X_j = \mathbf{1}\{Y_j > \tau_j\}$$

The joint distribution is characterized by:

$$P(\mathbf{X} = \mathbf{x}) = \sum_{\boldsymbol{\epsilon} \in \{-1,1\}^d} \prod_{j=1}^d \epsilon_j \cdot \Phi_{\rho}(\mathbf{h}(\boldsymbol{\epsilon}, \mathbf{F}^{-1}(\mathbf{q}(\mathbf{x}))))$$

### Identifiability

**Theorem (Global Identifiability)**: Under Assumption A (full rank $\rho$, $c_j > 0$, $b_j \geq 0$, $0 < p_j < 1$), the parameter vector $\boldsymbol{\theta} = (\text{vech}(\rho)^\top, \text{vec}(\Omega)^\top, \mathbf{a}^\top, \mathbf{b}^\top)^\top$ is globally identifiable.

### Oracle Properties

**Theorem (Oracle Inequality)**: Under high-dimensional conditions (sparsity $s \ll d^2$, restricted eigenvalue condition, mutual incoherence), the penalized pseudolikelihood estimator satisfies:

$$\|\hat{\Omega}_n^\lambda - \Omega_0\|_F^2 \leq C \frac{s \log d}{n} \quad \text{w.h.p.}$$

with probability at least $1 - 3\exp(-c\log d)$.

### Bootstrap Consistency

**Theorem (Multiplier Bootstrap)**: Under estimation quality assumptions, the multiplier bootstrap process converges weakly to the same tight Gaussian limit as the empirical process, conditional on the data, almost surely.

## Genomic Applications

The package includes tools for analyzing genomic data:

### Arabidopsis thaliana (Microarray)

```r
# Load and analyze gene expression data
data(arabidopsis)  # 118 arrays, 39 genes

fit_arab <- fit_qcopula(X_arab, lambda = 0.15, n_restarts = 20)
edges_arab <- extract_edges(fit_arab)

# Biological validation
# - STRING database annotation (>65% validation)
# - GO enrichment analysis
# - Promoter motif co-occurrence (>50%)
# - Replication in independent data (>59%)
```

### Single-Cell RNA-seq (Human Cell Atlas)

```r
# Load and analyze scRNA-seq data
data(hca_bonemarrow)  # 8,234 cells, 500 genes

fit_hca <- fit_qcopula(X_hca, lambda = select_lambda_hbic(X_hca),
                       n_restarts = 20)

# Comparison with single-cell methods (PIDC, SCENIC, WGCNA)
validation_score <- validate_with_string(extract_edges(fit_hca))
print(paste("STRING validation:", round(validation_score, 3)))
```

## Performance

### Scalability

Computation time (minutes) for full pipeline:

| d   | n   | Time |
|-----|-----|------|
| 50  | 500 | 2.1  |
| 100 | 500 | 8.7  |
| 200 | 500 | 31.4 |
| 500 | 500 | 187.2|

For $d > 500$, recommend marginal screening or parallel computing.

### Simulation Results (d=100, n=500, DGP1)

| Method            | TPR  | FPR  | Frob. Error |
|-------------------|------|------|-------------|
| Quadratic Copula  | 0.94 | 0.03 | 0.24        |
| t-Copula          | 0.42 | 0.07 | 0.52        |
| Ising Model       | 0.63 | 0.09 | 0.51        |
| RBM               | 0.58 | 0.16 | 0.59        |
| MGM               | 0.71 | 0.12 | 0.45        |
| Gaussian Copula   | 0.00 | 0.01 | 0.89        |

## Documentation

Full documentation available via:

```r
?quadcopula  # Package overview
?fit_qcopula  # Main fitting function
?bootstrap_inference  # Inference methods
vignette("quadcopula")  # Usage vignette
```

## Citation

If you use this package in your research, please cite:

```bibtex
@article{Bahraoui2026,
  title={Binary Quadratic Copulas with Genomic Applications},
  author={Bahraoui, Tarik and others},
  journal={Journal of Statistical Software},
  year={2026},
  volume={TBD},
  pages={TBD}
}
```

## References

- Bahraoui, T., et al. (2026). Binary Quadratic Copulas with Genomic Applications.
- Joe, H. (2014). Dependence Modeling with Copulas. CRC Press.
- Nelsen, R. B. (2006). An Introduction to Copulas. Springer.

## License

MIT License - see LICENSE file for details.

## Contact

For issues, questions, or contributions, please visit:
https://github.com/TBahraoui/quadcopula
