#' Binary Quadratic Copula Model Functions
#'
#' Core functions for defining and working with binary quadratic copula models.
#'
#' @import mvtnorm
#' @import Matrix
#' @import stats

#' Generate data from binary quadratic copula model
#'
#' Simulates observations from a binary quadratic copula model with latent
#' Gaussian variables transformed via quadratic forms.
#'
#' @param n Number of observations
#' @param d Number of dimensions
#' @param rho Correlation matrix of latent Gaussian variables (d x d)
#' @param Omega Symmetric interaction matrix (d x d) with diagonal c_j > 0
#' @param a Intercept parameters (d-dimensional)
#' @param b Slope parameters (d-dimensional, b_j >= 0)
#' @param thresholds Threshold parameters tau_j (d-dimensional)
#'
#' @return n x d matrix of binary observations
#'
#' @examples
#' # Simple 3-variable example
#' rho <- diag(3)
#' rho[1,2] <- rho[2,1] <- 0.3
#' Omega <- diag(c(1, 1, 1))
#' Omega[1,2] <- Omega[2,1] <- 0.2
#' X <- simulate_qcopula(n = 100, d = 3, rho = rho, Omega = Omega,
#'                       a = rep(-1, 3), b = rep(1.5, 3),
#'                       thresholds = rep(0, 3))
#'
#' @export
simulate_qcopula <- function(n, d, rho, Omega, a, b, thresholds) {
  
  stopifnot(
    is.numeric(n), n > 0,
    is.numeric(d), d > 0,
    nrow(rho) == d, ncol(rho) == d,
    nrow(Omega) == d, ncol(Omega) == d,
    length(a) == d, length(b) == d, length(thresholds) == d,
    all(b >= 0), all(diag(Omega) > 0)
  )
  
  # Generate latent Gaussian variables
  Z <- mvtnorm::rmvnorm(n, mean = rep(0, d), sigma = rho)
  
  # Transform: Y_j = a_j + b_j Z_j + c_j Z_j^2
  Y <- matrix(NA, nrow = n, ncol = d)
  for (j in 1:d) {
    c_j <- Omega[j, j]
    Y[, j] <- a[j] + b[j] * Z[, j] + c_j * Z[, j]^2
  }
  
  # Binarize: X_j = 1{Y_j > tau_j}
  X <- (Y > matrix(thresholds, nrow = n, ncol = d, byrow = TRUE)) * 1
  
  return(X)
}


#' Compute marginal quadratic CDF
#'
#' Evaluates the closed-form CDF F_j(y) for marginal Y_j following
#' a quadratic transformation of Gaussian variable.
#'
#' @param y Evaluation point(s)
#' @param a Intercept parameter
#' @param b Slope parameter
#' @param c Quadratic coefficient (c > 0)
#'
#' @return CDF values at y
#'
#' @keywords internal
marginal_cdf <- function(y, a, b, c) {
  
  y_min <- a - b^2 / (4 * c)
  result <- rep(0, length(y))
  valid <- y >= y_min
  
  if (any(valid)) {
    y_valid <- y[valid]
    discriminant <- b^2 - 4 * c * (a - y_valid)
    sqrt_disc <- sqrt(discriminant)
    
    # F_j(y) = Phi((-b + sqrt(disc))/(2c)) - Phi((-b - sqrt(disc))/(2c))
    upper <- pnorm((-b + sqrt_disc) / (2 * c))
    lower <- pnorm((-b - sqrt_disc) / (2 * c))
    result[valid] <- upper - lower
  }
  
  return(result)
}


#' Solve for root in quadratic transformation
#'
#' For Y_j = a_j + b_j Z_j + c_j Z_j^2, solves for Z_j when Y_j = tau_j.
#'
#' @param tau Threshold
#' @param a Intercept
#' @param b Slope
#' @param c Quadratic coefficient
#' @param which Which root ("lower" or "upper")
#'
#' @return Root Z_j value
#'
#' @keywords internal
solve_for_root <- function(tau, a, b, c, which = "lower") {
  
  disc <- b^2 - 4 * c * (a - tau)
  
  if (disc < 0) return(NA_real_)
  
  sqrt_disc <- sqrt(disc)
  if (which == "lower") {
    (-b - sqrt_disc) / (2 * c)
  } else if (which == "upper") {
    (-b + sqrt_disc) / (2 * c)
  } else {
    stop("which must be 'lower' or 'upper'")
  }
}
