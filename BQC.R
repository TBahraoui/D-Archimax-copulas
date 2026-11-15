# BQC.R — standalone Archimax copula contour and heatmap example
# Despite the filename, this script illustrates an Archimax copula,
# not a binary quadratic copula. It does not modify or depend on the
# other project files.
#
# Run with: Rscript BQC.R
# Output: figures/archimax_contour_heatmap.png

# Bivariate Archimax CDF with a Gumbel Archimedean generator and
# Gumbel-Hougaard Pickands dependence function.
archimax_cdf <- function(u, v, theta = 2, kappa = 2) {
  if (theta < 1 || kappa < 1) {
    stop("theta and kappa must both be at least 1.")
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

u <- seq(0.005, 0.995, length.out = 151)
v <- seq(0.005, 0.995, length.out = 151)
cdf <- outer(u, v, function(u, v) archimax_cdf(u, v, theta = 2, kappa = 2))
contour_levels <- seq(0.1, 0.9, by = 0.1)
colors <- grDevices::colorRampPalette(
  c("#f7fbff", "#6baed6", "#08306b")
)(100)

plot_archimax <- function() {
  old_par <- graphics::par(
    mfrow = c(1, 2),
    mar = c(4.2, 4.2, 3.8, 1),
    oma = c(0, 0, 2, 0)
  )
  on.exit(graphics::par(old_par))

  # Heatmap with contour lines overlaid.
  graphics::image(
    x = u, y = v, z = cdf,
    col = colors, zlim = c(0, 1), axes = FALSE,
    xlab = "u", ylab = "v",
    main = "Archimax CDF — heatmap"
  )
  graphics::axis(1)
  graphics::axis(2)
  graphics::box()
  graphics::contour(
    x = u, y = v, z = cdf, levels = contour_levels,
    add = TRUE, drawlabels = TRUE, col = "white", lwd = 0.9
  )

  # Contour-only view.
  graphics::contour(
    x = u, y = v, z = cdf, levels = contour_levels,
    xlab = "u", ylab = "v",
    main = "Archimax CDF — contours",
    col = "#24527a", lwd = 1.2
  )
  graphics::axis(1)
  graphics::axis(2)
  graphics::box()

  graphics::mtext(
    expression(paste("Gumbel parameters: ", theta, " = 2, ", kappa, " = 2")),
    outer = TRUE, cex = 0.95
  )
}

dir.create("figures", showWarnings = FALSE, recursive = TRUE)
grDevices::png(
  "figures/archimax_contour_heatmap.png",
  width = 1400, height = 650, res = 140
)
plot_archimax()
grDevices::dev.off()

cat("Saved figures/archimax_contour_heatmap.png\n")
