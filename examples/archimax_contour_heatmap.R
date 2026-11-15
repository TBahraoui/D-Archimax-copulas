# Reproducible bivariate Archimax copula contour and heatmap
# Run from the repository root:
#   Rscript examples/archimax_contour_heatmap.R
# Writes PNG and PDF versions under figures/.
# This is a theoretical illustration, not an empirical fit.

# Gumbel Archimedean generator psi and its inverse phi.
archimax_cdf <- function(u, v, theta = 2, kappa = 2) {
  stopifnot(theta >= 1, kappa >= 1)
  u <- pmin(pmax(u, .Machine$double.xmin), 1)
  v <- pmin(pmax(v, .Machine$double.xmin), 1)

  psi_u <- (-log(u))^theta
  psi_v <- (-log(v))^theta
  total <- psi_u + psi_v
  weight <- ifelse(total > 0, psi_u / total, 0.5)
  pickands <- (weight^kappa + (1 - weight)^kappa)^(1 / kappa)

  exp(-(total * pickands)^(1 / theta))
}

u <- seq(0.01, 0.99, length.out = 121)
v <- seq(0.01, 0.99, length.out = 121)
C <- outer(u, v, function(uu, vv) archimax_cdf(uu, vv, theta = 2, kappa = 2))
levels <- seq(0.1, 0.9, by = 0.1)
palette <- grDevices::colorRampPalette(c("#f7fbff", "#6baed6", "#08306b"))(100)

plot_archimax <- function() {
  old_par <- graphics::par(mfrow = c(1, 2), mar = c(4.2, 4.2, 3.5, 1),
                           oma = c(0, 0, 2, 0))
  on.exit(graphics::par(old_par))

  graphics::image(
    x = u, y = v, z = C, col = palette,
    zlim = c(0, 1), axes = FALSE,
    xlab = "u", ylab = "v",
    main = "Archimax copula CDF: heatmap"
  )
  graphics::axis(1); graphics::axis(2); graphics::box()
  graphics::contour(u, v, C, levels = levels, add = TRUE,
                    drawlabels = FALSE, col = "white", lwd = 0.8)

  graphics::contour(
    x = u, y = v, z = C, levels = levels,
    xlab = "u", ylab = "v",
    main = "Archimax copula CDF: contours",
    col = "#24527a", lwd = 1.2, labcex = 0.75
  )
  graphics::axis(1); graphics::axis(2); graphics::box()

  graphics::mtext(
    expression(paste("Gumbel generator: ", theta, " = 2; Gumbel-Hougaard Pickands: ", kappa, " = 2")),
    outer = TRUE, cex = 0.95
  )
}

dir.create("figures", showWarnings = FALSE, recursive = TRUE)
grDevices::png("figures/archimax_contour_heatmap.png", width = 1400,
               height = 650, res = 140)
plot_archimax()
grDevices::dev.off()

grDevices::pdf("figures/archimax_contour_heatmap.pdf", width = 10,
               height = 4.8, onefile = TRUE)
plot_archimax()
grDevices::dev.off()

cat("Saved figures/archimax_contour_heatmap.png and .pdf\n")
