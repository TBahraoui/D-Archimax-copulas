# Reproducible Archimax diagonal figure and results example
# Run from the repository root with Rscript examples/archimax_figure_results.R.
# This is a theoretical diagonal illustration, not an empirical application.

options(stringsAsFactors = FALSE)

# Archimedean generators and inverses, parameterized as in the paper scripts.
psi_gumbel <- function(t, theta) (-log(t))^theta
phi_gumbel <- function(x, theta) exp(-x^(1 / theta))

psi_clayton <- function(t, theta) (t^(-theta) - 1) / theta
phi_clayton <- function(x, theta) (1 + theta * x)^(-1 / theta)

psi_frank <- function(t, theta) {
  -log((exp(-theta * t) - 1) / (exp(-theta) - 1))
}
phi_frank <- function(x, theta) {
  -log(1 - (1 - exp(-theta)) * exp(-x)) / theta
}

# For the Gumbel-Hougaard Pickands function, m = 2^(1/kappa), and
# delta(t) = phi(m * psi(t)). These parameters correspond to tau = 0.5
# in the calibration values supplied with the paper code.
models <- list(
  `Gumbel-Gumbel` = list(psi = psi_gumbel, phi = phi_gumbel,
                          theta = 3.21, kappa = 1.63),
  `Clayton-Gumbel` = list(psi = psi_clayton, phi = phi_clayton,
                           theta = 1.78, kappa = 1.63),
  `Frank-Gumbel` = list(psi = psi_frank, phi = phi_frank,
                         theta = 5.98, kappa = 1.63)
)

t_grid <- seq(0.005, 0.995, length.out = 500)
curves <- lapply(names(models), function(model_name) {
  pars <- models[[model_name]]
  m <- 2^(1 / pars$kappa)
  data.frame(
    t = t_grid,
    diagonal = pars$phi(m * pars$psi(t_grid, pars$theta), pars$theta),
    model = model_name
  )
})
curve_data <- do.call(rbind, curves)

results <- do.call(rbind, lapply(names(models), function(model_name) {
  pars <- models[[model_name]]
  m <- 2^(1 / pars$kappa)
  data.frame(
    model = model_name,
    tau_calibration = 0.5,
    theta = pars$theta,
    kappa = pars$kappa,
    m = m,
    diagonal_at_0.5 = pars$phi(m * pars$psi(0.5, pars$theta), pars$theta)
  )
}))

# Create output folders if needed.
dir.create("figures", showWarnings = FALSE, recursive = TRUE)
dir.create("results", showWarnings = FALSE, recursive = TRUE)

# Save a publication-friendly vector figure using base R graphics.
pdf("figures/example_diagonal.pdf", width = 7, height = 5)
plot(NA, xlim = c(0, 1), ylim = c(0, 1),
     xlab = "t", ylab = expression(delta(t)),
     main = "Archimax diagonal sections (tau calibration = 0.5)")
cols <- c("#0072B2", "#D55E00", "#009E73")
for (i in seq_along(models)) {
  d <- curve_data[curve_data$model == names(models)[i], ]
  lines(d$t, d$diagonal, col = cols[i], lwd = 2)
}
abline(0, 1, lty = 3, col = "grey50")
legend("topleft", legend = names(models), col = cols, lwd = 2,
       bty = "n", cex = 0.85)
dev.off()

write.csv(results, "results/example_diagonal.csv", row.names = FALSE)
cat("Saved figure: figures/example_diagonal.pdf\n")
cat("Saved theoretical diagonal results: results/example_diagonal.csv\n\n")
print(results, row.names = FALSE, digits = 4)
