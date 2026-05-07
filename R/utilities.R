#' Extract sparsity pattern
#'
#' Returns indices of nonzero off-diagonal interactions.
#'
#' @param fit Fitted model from fit_qcopula()
#' @param threshold Detection threshold (default: machine epsilon)
#'
#' @return Data frame with columns: i, j, Omega_ij, p_value
#'
#' @examples
#' \dontrun{
#' fit <- fit_qcopula(X, lambda = 0.1)
#' edges <- extract_edges(fit)
#' head(edges)
#' }
#'
#' @export
extract_edges <- function(fit, threshold = .Machine$double.eps) {
  
  d <- nrow(fit$theta$Omega)
  edges <- data.frame()
  
  for (i in 1:(d-1)) {
    for (j in (i+1):d) {
      omega_ij <- fit$theta$Omega[i, j]
      
      if (abs(omega_ij) > threshold) {
        edges <- rbind(edges, data.frame(
          i = i,
          j = j,
          Omega = omega_ij,
          sign = ifelse(omega_ij > 0, "positive", "negative")
        ))
      }
    }
  }
  
  # Sort by absolute value
  edges <- edges[order(abs(edges$Omega), decreasing = TRUE), ]
  rownames(edges) <- NULL
  
  return(edges)
}


#' Support recovery metrics
#'
#' Computes true positive rate, false positive rate, and F1 score.
#'
#' @param Omega_true True interaction matrix
#' @param Omega_est Estimated interaction matrix
#' @param threshold Detection threshold
#'
#' @return List with TPR, FPR, F1, precision, recall
#'
#' @examples
#' \dontrun{
#' metrics <- support_recovery_metrics(Omega_true, fit$theta$Omega)
#' }
#'
#' @export
support_recovery_metrics <- function(Omega_true, Omega_est, 
                                    threshold = 1e-6) {
  
  # Extract support (nonzero entries)
  true_support <- which(abs(Omega_true) > threshold & 
                        row(Omega_true) < col(Omega_true))
  est_support <- which(abs(Omega_est) > threshold & 
                       row(Omega_est) < col(Omega_est))
  
  tp <- length(intersect(true_support, est_support))
  fp <- length(setdiff(est_support, true_support))
  fn <- length(setdiff(true_support, est_support))
  
  tpr <- if (tp + fn > 0) tp / (tp + fn) else 0
  fpr <- if (fp > 0) fp / (fp + (nrow(Omega_true) * (nrow(Omega_true) - 1) / 2 - tp - fn)) else 0
  precision <- if (tp + fp > 0) tp / (tp + fp) else 0
  recall <- tpr
  f1 <- if (precision + recall > 0) 2 * precision * recall / (precision + recall) else 0
  
  list(
    TPR = tpr,
    FPR = fpr,
    precision = precision,
    recall = recall,
    F1 = f1,
    n_true = length(true_support),
    n_est = length(est_support),
    TP = tp, FP = fp, FN = fn
  )
}


#' Estimation error metrics
#'
#' Computes Frobenius norm and max-norm errors.
#'
#' @param Omega_true True interaction matrix
#' @param Omega_est Estimated interaction matrix
#'
#' @return List with Frobenius, spectral, and max errors
#'
#' @examples
#' \dontrun{
#' errors <- estimation_error_metrics(Omega_true, fit$theta$Omega)
#' }
#'
#' @export
estimation_error_metrics <- function(Omega_true, Omega_est) {
  
  diff <- Omega_est - Omega_true
  
  frob_error <- sqrt(sum(diff^2))
  max_error <- max(abs(diff))
  spectral_error <- svd(diff)$d[1]
  
  list(
    Frobenius = frob_error,
    Spectral = spectral_error,
    Max = max_error
  )
}


#' Cross-validation for model selection
#'
#' Splits data into folds and selects lambda based on out-of-sample pseudolikelihood.
#'
#' @param X Binary data
#' @param lambda_seq Sequence of lambda values
#' @param n_folds Number of cross-validation folds (default: 5)
#' @param verbose Verbose output
#'
#' @return Selected lambda and CV scores
#'
#' @examples
#' \dontrun{
#' cv_result <- cv_qcopula(X, lambda_seq = exp(seq(-5, 0, 0.5)))
#' }
#'
#' @export
cv_qcopula <- function(X, lambda_seq = exp(seq(-5, 0, 0.5)), 
                      n_folds = 5, verbose = FALSE) {
  
  n <- nrow(X)
  fold_ids <- sample(rep(1:n_folds, length.out = n))
  
  cv_scores <- matrix(NA, nrow = n_folds, ncol = length(lambda_seq))
  
  for (fold in 1:n_folds) {
    
    X_train <- X[fold_ids != fold, ]
    X_test <- X[fold_ids == fold, ]
    
    if (verbose) cat("Fold", fold, "of", n_folds, "\n")
    
    for (i in seq_along(lambda_seq)) {
      
      lambda <- lambda_seq[i]
      
      # Fit on training set
      fit <- fit_qcopula(X_train, lambda = lambda, 
                        max_iter = 50, n_restarts = 2, verbose = FALSE)
      
      # Evaluate on test set
      plik_test <- compute_pseudolikelihood(X_test, fit$theta)
      cv_scores[fold, i] <- plik_test
      
      if (verbose && fold == 1 && i %% 5 == 0) {
        cat("  Lambda:", lambda, "Test PL:", plik_test, "\n")
      }
    }
  }
  
  # Mean CV score
  mean_cv <- colMeans(cv_scores)
  se_cv <- apply(cv_scores, 2, sd) / sqrt(n_folds)
  
  # Select lambda with best CV score (one-SE rule)
  best_idx <- which.max(mean_cv)
  lambda_best <- lambda_seq[best_idx]
  se_rule_idx <- max(which(mean_cv >= mean_cv[best_idx] - se_cv[best_idx]))
  lambda_1se <- lambda_seq[se_rule_idx]
  
  list(
    lambda_best = lambda_best,
    lambda_1se = lambda_1se,
    cv_scores = cv_scores,
    mean_cv = mean_cv,
    se_cv = se_cv,
    lambda_seq = lambda_seq
  )
}


#' Plot cross-validation curve
#'
#' @param cv_result Result from cv_qcopula()
#'
#' @export
plot_cv <- function(cv_result) {
  
  plot(cv_result$lambda_seq, cv_result$mean_cv,
       type = "l", log = "x",
       xlab = "Lambda (log scale)",
       ylab = "Cross-validation Score",
       main = "Model Selection via Cross-validation")
  
  # Standard error bands
  lines(cv_result$lambda_seq, 
        cv_result$mean_cv + cv_result$se_cv, lty = 2, col = "gray")
  lines(cv_result$lambda_seq, 
        cv_result$mean_cv - cv_result$se_cv, lty = 2, col = "gray")
  
  # Mark selected lambdas
  abline(v = cv_result$lambda_best, col = "red", lty = 2)
  abline(v = cv_result$lambda_1se, col = "blue", lty = 2)
  
  legend("bottomright",
         c("Best", "One-SE Rule"),
         col = c("red", "blue"), lty = 2)
  
  invisible(cv_result)
}
