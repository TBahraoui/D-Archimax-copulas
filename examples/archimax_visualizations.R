# Standalone Archimax copula visualization example
# Run from the repository root with:
#   Rscript examples/archimax_visualizations.R
# Uses base R only. Outputs figures/ and results/ files.

set.seed(20251115)

theta <- 2
kappa <- 2

# Gumbel Archimedean generator and inverse combined with a
# Gumbel-Hougaard Pickands dependence function.
archimax_cdf <- function(u, v, theta = 2, kappa = 2) {
  if (!is.numeric(theta) || length(theta) != 1L || theta < 1 ||
      !is.numeric(kappa) || length(kappa) != 1L || kappa < 1) {
    stop("theta and kappa must be scalar values >= 1.")
  }
  u <- pmin(pmax(u, .Machine$double.xmin), 1)
  v <- pmin(pmax(v, .Machine$double.xmin), 1)
  psi_u <- (-log(u))^theta
  psi_v <- (-log(v))^theta
  total <- psi_u + psi_v
  weight <- ifelse(total > 0, psi_u / total, 0.5)
  pickands <- (weight^kappa + (1 - weight)^kappa)^(1 / kappa)
  exp(-(total * pickands)^(1 / theta))
}

# Conditional distribution F(V | U = u) = partial C(u,v) / partial u.
# Use a central finite difference for the derivative in u.
conditional_cdf_v_given_u <- function(v, u, theta, kappa) {
  h <- min(1e-5, u / 2, (1 - u) / 2)
  (archimax_cdf(u + h, v, theta, kappa) -
     archimax_cdf(u - h, v, theta, kappa)) / (2 * h)
}

# Simulate from the copula by conditional inversion: U is uniform and V is
# sampled from its conditional CDF given U. Then form rank pseudo-observations.
simulate_archimax <- function(n, theta, kappa) {
  u <- stats::runif(n, min = 0.002, max = 0.998)
  target <- stats::runif(n)
  v <- numeric(n)
  interval <- c(1e-8, 1 - 1e-8)

  for (i in seq_len(n)) {
    root <- stats::uniroot(
      function(value) conditional_cdf_v_given_u(value, u[i], theta, kappa) - target[i],
      interval = interval,
      tol = 1e-7
    )
    v[i] <- root$root
  }

  cbind(U = u, V = v)
}

# Evaluate CDF on an interior grid. Avoid exact boundaries for stable
# numerical density differentiation.
grid <- seq(0.01, 0.99, length.out = 121)
cdf <- outer(grid, grid, function(u, v) archimax_cdf(u, v, theta, kappa))

# Mixed central finite difference for c(u,v) = d^2 C / du dv.
step <- grid[2] - grid[1]
h <- step / 3
density <- matrix(NA_real_, nrow = length(grid), ncol = length(grid))
for (i in seq_along(grid)) {
  for (j in seq_along(grid)) {
    u <- grid[i]
    v <- grid[j]
    density[i, j] <- (
      archimax_cdf(u + h, v + h, theta, kappa) -
        archimax_cdf(u + h, v - h, theta, kappa) -
        archimax_cdf(u - h, v + h, theta, kappa) +
        archimax_cdf(u - h, v - h, theta, kappa)
    ) / (4 * h^2)
  }
}

# Plot helper: image and contour use the same matrix orientation.
plot_heatmap_contour <- function(x, y, z, title, color_limit, contour_values,
                                 palette) {
  graphics::image(
    x = x, y = y, z = z,
    col = palette, zlim = color_limit,
    xlab = "u", ylab = "v", main = title,
    useRaster = TRUE
  )
  graphics::contour(
    x = x, y = y, z = z,
    levels = contour_values, add = TRUE,
    drawlabels = TRUE, col = "#172b4d", lwd = 0.8,
    labcex = 0.7
  )
  graphics::box()
}

fig_dir <- "figures"
results_dir <- "results"
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(results_dir, showWarnings = FALSE, recursive = TRUE)
palette <- grDevices::colorRampPalette(
  c("#f7fbff", "#6baed6", "#08306b")
)(100)

# Figure 1: copula CDF heatmap with CDF contour levels.
grDevices::png(file.path(fig_dir, "archimax_cdf_heatmap_contour.png"),
               width = 1100, height = 850, res = 130)
plot_heatmap_contour(
  grid, grid, cdf,
  title = sprintf("Archimax copula CDF (theta = %g, kappa = %g)", theta, kappa),
  color_limit = c(0, 1),
  contour_values = seq(0.1, 0.9, by = 0.1),
  palette = palette
)
grDevices::dev.off()

# Figure 2: density heatmap and contours. Use a robust upper color limit;
# keep density values themselves unchanged in the output calculation.
positive_density <- density[is.finite(density) & density > 0]
if (length(positive_density) < 10L) {
  stop("Too few positive finite density values; check the numerical grid.")
}
density_cap <- unname(stats::quantile(positive_density, 0.98))
density_plot <- pmax(density, 0)
density_levels <- unique(as.numeric(stats::quantile(
  positive_density, probs = c(0.25, 0.5, 0.75), na.rm = TRUE
)))
density_levels <- density_levels[density_levels > 0 & density_levels < density_cap]
if (!length(density_levels)) density_levels <- pretty(c(0, density_cap), n = 5)

grDevices::png(file.path(fig_dir, "archimax_density_heatmap_contour.png"),
               width = 1100, height = 850, res = 130)
plot_heatmap_contour(
  grid, grid, density_plot,
  title = "Archimax copula density (finite-difference approximation)",
  color_limit = c(0, density_cap),
  contour_values = density_levels,
  palette = palette
)
grDevices::dev.off()

# Figure 3: simulated rank pseudo-observations and diagonal section.
sample_size <- 400
sample_uv <- simulate_archimax(sample_size, theta, kappa)
pseudo <- cbind(
  U = rank(sample_uv[, "U"], ties.method = "average") / (sample_size + 1),
  V = rank(sample_uv[, "V"], ties.method = "average") / (sample_size + 1)
)
diagonal_grid <- seq(0.02, 0.98, length.out = 100)
theoretical_diagonal <- vapply(
  diagonal_grid,
  function(t) archimax_cdf(t, t, theta, kappa),
  numeric(1)
)
empirical_diagonal <- vapply(
  diagonal_grid,
  function(t) mean(pseudo[, "U"] <= t & pseudo[, "V"] <= t),
  numeric(1)
)

sample_csv <- data.frame(id = seq_len(sample_size), pseudo)
diagonal_csv <- data.frame(
  t = diagonal_grid,
  theoretical = theoretical_diagonal,
  empirical = empirical_diagonal
)
utils::write.csv(sample_csv,
                 file.path(results_dir, "archimax_pseudo_observations.csv"),
                 row.names = FALSE)
utils::write.csv(diagonal_csv,
                 file.path(results_dir, "archimax_diagonal.csv"),
                 row.names = FALSE)

grDevices::png(file.path(fig_dir, "archimax_pseudo_observations_diagonal.png"),
               width = 1200, height = 600, res = 130)
old_par <- graphics::par(mfrow = c(1, 2), mar = c(4.2, 4.2, 3.5, 1))
graphics::plot(
  pseudo[, "U"], pseudo[, "V"], pch = 16, cex = 0.65,
  col = grDevices::adjustcolor("#2b6f9c", alpha.f = 0.45),
  xlim = c(0, 1), ylim = c(0, 1), asp = 1,
  xlab = expression(U), ylab = expression(V),
  main = "Simulated pseudo-observations"
)
graphics::abline(0, 1, lty = 3, col = "grey55")
graphics::plot(
  diagonal_grid, theoretical_diagonal, type = "l", lwd = 2,
  col = "#0072B2", xlim = c(0, 1), ylim = c(0, 1),
  xlab = "t", ylab = expression(C(t, t)),
  main = "Diagonal section"
)
graphics::lines(diagonal_grid, empirical_diagonal, type = "s",
                lwd = 1.5, col = "#D55E00")
graphics::abline(0, 1, lty = 3, col = "grey75")
graphics::legend(
  "topleft", legend = c("Theoretical C(t,t)", "Empirical C_n(t,t)"),
  col = c("#0072B2", "#D55E00"), lwd = c(2, 1.5),
  bty = "n", cex = 0.85
)
graphics::par(old_par)
grDevices::dev.off()

cat("Created figures/archimax_cdf_heatmap_contour.png\n")
cat("Created figures/archimax_density_heatmap_contour.png\n")
cat("Created figures/archimax_pseudo_observations_diagonal.png\n")
cat("Created results/archimax_pseudo_observations.csv\n")
cat("Created results/archimax_diagonal.csv\n")
