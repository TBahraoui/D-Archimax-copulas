#' quadcopula: Binary Quadratic Copula Models
#'
#' Implements binary quadratic copula models for high-dimensional binary data
#' with nonlinear dependence structures. Provides:
#'
#' \itemize{
#'   \item Model definition and data simulation (\code{simulate_qcopula})
#'   \item Penalized pseudolikelihood estimation (\code{fit_qcopula})
#'   \item Bootstrap inference and goodness-of-fit testing
#'   \item Power analysis and visualization
#'   \item Genomic applications with biological validation
#' }
#'
#' @section Main Functions:
#' \itemize{
#'   \item \code{\link{simulate_qcopula}}: Generate data from quadratic copula
#'   \item \code{\link{fit_qcopula}}: Estimate model parameters
#'   \item \code{\link{bootstrap_inference}}: Bootstrap confidence bands
#'   \item \code{\link{goodness_of_fit_test}}: Test quadratic vs Gaussian copula
#'   \item \code{\link{compute_power_surface}}: Power surface computation
#'   \item \code{\link{extract_edges}}: Extract interaction network
#'   \item \code{\link{cv_qcopula}}: Cross-validation model selection
#' }
#'
#' @section Key Features:
#' \itemize{
#'   \item Full identifiability under sparsity constraints
#'   \item Oracle properties for penalized pseudolikelihood
#'   \item Multiplier bootstrap for nonasymptotic inference
#'   \item Computational efficiency via coordinate descent
#'   \item Power surface analysis as function of signal strength and margins
#' }
#'
#' @references
#' Bahraoui et al. (2026). Binary Quadratic Copulas with Genomic Applications.
#' Journal of Statistical Software, under review.
#'
#' @import mvtnorm
#' @import Matrix
#' @import stats
#' @import graphics
#'
#' @docType package
#' @name quadcopula
NULL
