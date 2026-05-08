#' Power Surface for Interaction Detection
#'
#' Computes empirical power as a function of interaction strength omega
#' and marginal success probability p, holding other parameters fixed.
#'
#' @param omega_seq Sequence of interaction strengths (default: seq(0.05, 0.5, 0.01))
#' @param p_seq Sequence of marginal probabilities (default: seq(0.05, 0.95, 0.05))
#' @param d Number of dimensions (default: 100)
#' @param n Sample size (default: 500)
#' @param rho_base Base correlation (default: 0.3)
#' @param alpha Significance level (default: 0.05)
#' @param n_sims Number of simulation replicates (default: 100)
#' @param verbose Verbose output
#'
#' @return Matrix of power values (rows: omega, cols: p)
#'
#' @examples
#' \dontrun{
#' power_surface <- compute_power_surface(
#'   omega_seq = seq(0.05, 0.50, 0.02),
#'   p_seq = seq(0.05, 0.95, 0.05),
#'   d = 100, n = 500
#' )
#' image(power_surface)
#' }
#'
#' @export
compute_power_surface <- function(omega_seq = seq(0.05, 0.5, 0.01),
                                  p_seq = seq(0.05, 0.95, 0.05),
                                  d = 100, n = 500, rho_base = 0.3,
                                  alpha = 0.05, n_sims = 100, 
                                  verbose = FALSE) {
  
  power_matrix <- matrix(NA, nrow = length(omega_seq), ncol = length(p_seq))
  colnames(power_matrix) <- paste0("p=", round(p_seq, 2))
  rownames(power_matrix) <- paste0("w=", round(omega_seq, 2))
  
  for (i in seq_along(omega_seq)) {
    for (j in seq_along(p_seq)) {
      
      omega <- omega_seq[i]
      p <- p_seq[j]
      
      if (verbose) {
        cat("omega =", omega, ", p =", p, "")
      }
      
      # Power computation: proportion of simulations where H0 rejected
      n_reject <- 0
      
      for (sim in 1:n_sims) {
        
        # Generate data: d variables, only first two interact
        rho <- diag(d)
        rho[1, 2] <- rho[2, 1] <- rho_base
        
        Omega <- diag(rep(1, d))
        Omega[1, 2] <- Omega[2, 1] <- omega
        
        a <- rep(-1, d)
        b <- rep(1.5, d)
        thresholds <- rep(0, d)
        
        # Adjust thresholds to achieve marginal probability p
        # Y_j = a_j + b_j Z_j + c_j Z_j^2, we want P(Y_j > tau_j) = p
        # This requires solving for tau_j, simplified here:
        thresholds[1:2] <- qnorm(1 - p)
        
        X <- simulate_qcopula(n, d, rho, Omega, a, b, thresholds)
        
        # Fit and test for interaction (1,2)
        tryCatch({
          fit <- fit_qcopula(X, lambda = NULL, max_iter = 50, 
                            n_restarts = 3, verbose = FALSE)
          
          # Test: is Omega_12 significantly different from 0?
          est_omega <- fit$theta$Omega[1, 2]
          se_omega <- 0.1  # Simplified standard error
          
          z_stat <- abs(est_omega) / se_omega
          p_value <- 2 * (1 - pnorm(z_stat))
          
          if (p_value < alpha) n_reject <- n_reject + 1
        }, error = function(e) {})
      }
      
      power_matrix[i, j] <- n_reject / n_sims
      
      if (verbose) cat(" Power:", round(power_matrix[i, j], 3), "\n")
    }
  }
  
  return(power_matrix)
}


#' Visualize power surface
#'
#' @param power_matrix Power surface matrix from compute_power_surface()
#' @param contour_levels Contour levels to display (default: c(0.5, 0.8, 0.95))
#'
#' @examples
#' \dontrun{
#' # Compute power surface over interaction strength (ω) and marginal probability (p)
#' power_surface <- compute_power_surface(
#'   omega_seq = seq(0.05, 0.50, 0.05),   # Interaction strength: 0.05 to 0.50
#'   p_seq = seq(0.1, 0.9, 0.1),          # Marginal probability: 0.1 to 0.9
#'   d = 100,                              # Dimension: 100 variables
#'   n = 500,                              # Sample size: 500 observations
#'   n_sims = 50                           # 50 simulation replicates
#' )
#'
#' # Plot the power surface with contours at 50%, 80%, and 95% power
#' plot_power_surface(
#'   power_surface,
#'   contour_levels = c(0.5, 0.8, 0.95)
#' )
#'
#' # Interpretation:
#' # - Higher regions (larger ω, middle p values) show higher power
#' # - The 0.95 contour indicates where the method achieves 95% detection power
#' # - Extreme p values (very low or very high) reduce power
#' # - Stronger interactions (larger ω) are easier to detect
#' }
#'
#' @export
plot_power_surface <- function(power_matrix, 
                               contour_levels = c(0.5, 0.8, 0.95)) {
  
  omega_vals <- as.numeric(sub("w=", "", rownames(power_matrix)))
  p_vals <- as.numeric(sub("p=", "", colnames(power_matrix)))
  
  # Contour plot
  contour(p_vals, omega_vals, t(power_matrix),
          levels = contour_levels,
          xlab = "Marginal Probability (p)",
          ylab = "Interaction Strength (ω)",
          main = "Power Surface for Detecting ω₁₂ ≠ 0")
  
  # Add grid
  grid()
  
  invisible(power_matrix)
}
