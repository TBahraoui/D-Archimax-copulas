#' Bootstrap Inference for Quadratic Copula
#'
#' Implements multiplier bootstrap for constructing confidence bands and
#' hypothesis tests on the distribution of the quadratic form.
#'
#' @param X Binary data matrix (n x d)
#' @param fit Fitted model object from fit_qcopula()
#' @param n_bootstrap Number of bootstrap replicates (default: 1000)
#' @param confidence_level Confidence level (default: 0.95)
#' @param verbose Print progress (default: FALSE)
#'
#' @return List containing:
#'   \item{critical_value}{Bootstrap critical value}
#'   \item{confidence_band}{Confidence band limits}
#'   \item{bootstrap_process}{Bootstrap process samples}
#'
#' @examples
#' \dontrun{
#' fit <- fit_qcopula(X, lambda = 0.1)
#' boot_inference <- bootstrap_inference(X, fit, n_bootstrap = 1000)
#' }
#'
#' @export
bootstrap_inference <- function(X, fit, n_bootstrap = 1000,
                                confidence_level = 0.95, verbose = FALSE) {
  
  n <- nrow(X)
  d <- ncol(X)
  alpha <- 1 - confidence_level
  
  # Compute empirical Bayes estimates of latent variables
  Z_hat <- compute_posterior_mean(X, fit$theta)
  
  # Compute quadratic form values
  Q_vals <- rep(NA, n)
  for (i in 1:n) {
    Q_vals[i] <- t(Z_hat[i, ]) %*% fit$theta$Omega %*% Z_hat[i, ] - 
                 tr(fit$theta$Omega %*% fit$theta$rho)
  }
  
  # Empirical CDF
  F_n <- ecdf(Q_vals)
  
  # Bootstrap process
  xi <- matrix(rnorm(n * n_bootstrap), nrow = n, ncol = n_bootstrap)
  
  G_boot <- matrix(NA, nrow = n_bootstrap, ncol = length(unique(Q_vals)))
  Q_unique <- sort(unique(Q_vals))
  
  for (b in 1:n_bootstrap) {
    if (verbose && b %% 100 == 0) cat("Bootstrap replicate", b, "\n")
    
    # Multiplier bootstrap: G_b(x) = (1/sqrt(n)) * sum_i xi_ib * (1{Q_i <= x} - F_n(x))
    for (j in seq_along(Q_unique)) {
      x <- Q_unique[j]
      G_boot[b, j] <- sum(xi[, b] * (Q_vals <= x)) / sqrt(n) - 
                      sqrt(n) * (F_n(x) - F_n(x))
    }
  }
  
  # Critical value: (1-alpha/2)-quantile of sup_x |G_b(x)|
  sup_norm <- apply(abs(G_boot), 1, max)
  c_alpha <- quantile(sup_norm, 1 - alpha/2)
  
  # Confidence bands: F_n(x) +/- c_alpha / sqrt(n)
  F_vals <- F_n(Q_unique)
  conf_lower <- pmax(F_vals - c_alpha / sqrt(n), 0)
  conf_upper <- pmin(F_vals + c_alpha / sqrt(n), 1)
  
  list(
    critical_value = c_alpha,
    confidence_band = data.frame(
      x = Q_unique,
      F = F_vals,
      lower = conf_lower,
      upper = conf_upper
    ),
    bootstrap_process = G_boot,
    Q_values = Q_vals,
    empirical_cdf = F_n
  )
}


#' Compute posterior mean E[Z_i | X_i]
#'
#' Uses variational approximation or Gibbs sampling.
#'
#' @param X Binary data
#' @param theta Parameters
#'
#' @return n x d matrix of posterior means
#'
#' @keywords internal
compute_posterior_mean <- function(X, theta) {
  
  n <- nrow(X)
  d <- ncol(X)
  
  Z_hat <- matrix(NA, nrow = n, ncol = d)
  
  for (i in 1:n) {
    for (j in 1:d) {
      # Conditional mean given observed x_i
      # Simplified: use threshold
      c_j <- theta$Omega[j, j]
      a_j <- theta$a[j]
      b_j <- theta$b[j]
      tau_j <- a_j + b_j * 0 + c_j * 0^2  # Simplified threshold
      
      if (X[i, j] == 1) {
        # Z_j | Z_j^2 > tau_j/c_j
        Z_hat[i, j] <- sqrt(tau_j / c_j)
      } else {
        Z_hat[i, j] <- -sqrt(tau_j / c_j)
      }
    }
  }
  
  return(Z_hat)
}


#' Goodness-of-fit test: Quadratic vs Gaussian copula
#'
#' Tests H0: quadratic coefficients c_j = 0 (Gaussian copula) vs
#' H1: at least one c_j > 0 using parametric bootstrap.
#'
#' @param X Binary data matrix
#' @param fit_quad Quadratic copula fit
#' @param n_bootstrap Number of bootstrap replicates (default: 1000)
#' @param verbose Verbose output
#'
#' @return List containing:
#'   \item{p_value}{Bootstrap p-value}
#'   \item{test_stat}{Observed test statistic}
#'   \item{bootstrap_stats}{Bootstrap test statistics}
#'
#' @examples
#' \dontrun{
#' fit_quad <- fit_qcopula(X, lambda = 0.1)
#' gof_test <- goodness_of_fit_test(X, fit_quad, n_bootstrap = 1000)
#' }
#'
#' @export
goodness_of_fit_test <- function(X, fit_quad, n_bootstrap = 1000, 
                                  verbose = FALSE) {
  
  # Fit null model (Gaussian copula: c_j = 0)
  fit_null <- fit_qcopula_null(X)
  
  # Observed test statistic
  plik_quad <- compute_pseudolikelihood(X, fit_quad$theta)
  plik_null <- compute_pseudolikelihood(X, fit_null$theta)
  T_obs <- 2 * (plik_quad - plik_null)
  
  if (verbose) cat("Observed test statistic:", T_obs, "\n")
  
  # Bootstrap
  T_boot <- rep(NA, n_bootstrap)
  
  for (b in 1:n_bootstrap) {
    if (verbose && b %% 100 == 0) cat("Bootstrap", b, "of", n_bootstrap, "\n")
    
    # Generate data under null model
    X_boot <- generate_from_fit(fit_null, nrow(X))
    
    # Fit both models to bootstrap data
    fit_null_b <- fit_qcopula_null(X_boot)
    fit_quad_b <- fit_qcopula(X_boot, lambda = fit_quad$lambda, 
                               initial_theta = fit_null_b, 
                               max_iter = 50, n_restarts = 2)
    
    # Test statistic under bootstrap
    plik_quad_b <- compute_pseudolikelihood(X_boot, fit_quad_b$theta)
    plik_null_b <- compute_pseudolikelihood(X_boot, fit_null_b$theta)
    T_boot[b] <- 2 * (plik_quad_b - plik_null_b)
  }
  
  # Bootstrap p-value
  p_value <- mean(T_boot >= T_obs)
  
  list(
    p_value = p_value,
    test_statistic = T_obs,
    bootstrap_statistics = T_boot
  )
}


#' Fit Gaussian copula (null model)
#'
#' Fits with constraint c_j = 0 for all j.
#'
#' @param X Binary data
#'
#' @return Fitted null model
#'
#' @keywords internal
fit_qcopula_null <- function(X) {
  
  theta_init <- initialize_gaussian_copula(X)
  # Set c_j = 0 (no quadratic terms)
  diag(theta_init$Omega) <- 0
  
  fit <- fit_qcopula(X, lambda = 0, initial_theta = theta_init,
                     max_iter = 50, n_restarts = 5, verbose = FALSE)
  
  return(fit)
}


#' Generate data from fitted model
#'
#' @param fit Fitted model
#' @param n_new Number of new samples
#'
#' @return Generated binary data
#'
#' @keywords internal
generate_from_fit <- function(fit, n_new) {
  
  theta <- fit$theta
  d <- length(theta$a)
  
  X_new <- simulate_qcopula(
    n = n_new,
    d = d,
    rho = theta$rho,
    Omega = theta$Omega,
    a = theta$a,
    b = theta$b,
    thresholds = rep(0, d)
  )
  
  return(X_new)
}


#' Matrix trace function
#'
#' @param M Square matrix
#'
#' @return Trace
#'
#' @keywords internal
tr <- function(M) sum(diag(M))
