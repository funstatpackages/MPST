#' Bivariate Spline Basis Function
#'
#' This function generates the basis for bivariate spline over triangulation.
#'
#' @importFrom Matrix Matrix
#' @importFrom pracma isempty
#' @importFrom Rcpp evalCpp
#' @param V The \code{N} by two matrix of vertices of a triangulation, where \code{N} is the number of vertices. Each row is the coordinates for a vertex.
#' \cr
#' @param Tr The triangulation matrix of dimention \code{nT} by three, where \code{nT} is the number of triangles in the triangulation. Each row is the indices of vertices in \code{V}.
#' \cr
#' @param d The degree of piecewise polynomials -- default is 5, and usually \code{d} is greater than one. -1 represents piecewise constant.
#' \cr
#' @param r The smoothness parameter -- default is 1, and 0 \eqn{\le} \code{r} \eqn{<} \code{d}.
#' \cr
#' @param Z The cooridinates of dimension \code{n} by two. Each row is the coordinates of a point.
#' \cr
#' @param Hmtx The indicator of whether the smoothness matrix \code{H} need to be generated -- default is \code{TRUE}.
#' \cr
#' @param Kmtx The indicator of whether the energy matrix \code{K} need to be generated -- default is \code{TRUE}.
#' \cr
#' @param QR The indicator of whether a QR decomposition need to be performed on the smoothness matrix -- default is \code{TRUE}.
#' \cr
#' @param TA The indicator of whether the area of the triangles need to be calculated -- default is \code{TRUE}.
#' \cr
#' @return A list of vectors and matrice, including:
#' \item{B}{The spline basis function of dimension \code{n} by \code{nT}*\code{{(d+1)(d+2)/2}}, where \code{n} is the number of observationed points, \code{nT} is the number of triangles in the given triangulation, and \code{d} is the degree of the spline. If some points do not fall in the triangulation, the generation of the spline basis will not take those points into consideration.}
#' \item{ind.inside}{A vector contains the indexes of all the points which are inside the triangulation.}
#' \item{H}{The smoothness matrix.}
#' \item{Q2}{The Q2 matrix after QR decomposition of the smoothness matrix \code{H}.}
#' \item{K}{The thin-plate energy function.}
#' \item{tria.all}{The area of each triangle within the given triangulation.}
#'
#' @details This R program is modified based on the Matlab program written by Ming-Jun Lai from the University of Georgia and Li Wang from the Iowa State University.
#'
#' @examples
#' # example 1
#' xx = c(-0.25, 0.75, 0.25, 1.25)
#' yy = c(-0.25, 0.25, 0.75,1 .25)
#' Z = cbind(xx, yy)
#' d = 4; r = 1;
#' V0 = rbind(c(0, 0), c(1, 0), c(1, 1), c(0, 1))
#' Tr0 = rbind(c(1, 2, 3), c(1, 3, 4))
#' basis(V0, Tr0, d, r, Z)
#' 
#' @export

basis <- function(V, Tr, d = 5, r = 1, Z){
  V <- as.matrix(V); Tr <- as.matrix(Tr);
  Z <- matrix(Z, ncol = 2)
  nz <- nrow(Z)
  
  if(d >= 1){
    sfold <- 100; nfold <- ceiling(nz/sfold);
    if(nz%%sfold == 1 & nfold > 1) nfold <- nfold - 1;
    B <- c(); Bi <- c(); ind <- c();
    for(ii in 1:nfold){
      if(ii < nfold){
        idi <- ((ii-1)*sfold + 1):(ii*sfold);
      }
      if(ii == nfold){
        idi <- ((ii-1)*sfold + 1):nz;
      }
      Zi <- matrix(Z[idi, ], ncol = 2)
      bsi <- BSpline(V, Tr, d, r, Zi[, 1], Zi[, 2])
      Bii <- bsi$Bi
      Bii <- Matrix(Bii, sparse = TRUE)
      indi <- bsi$Ind
      if(!isempty(Bii)){
        Bi <- rbind(Bi, Bii); ind <- c(ind, idi[indi]);
      }
    }
    
    ind.inside <- sort(unique(ind))
    if(length(ind.inside) < nz){
      warning("Warning: some location points are out of the triangulation, so the number of the rows of the B matrix is smaller than the number of locations.")
    }
    B <- matrix(0, nrow = max(ind), ncol = ncol(Bi))
    B[ind, ] <- as.matrix(Bi)
    B <- B[apply(B, 1, function(x) !all(x == 0)), ]
    B <- Matrix(B, sparse = TRUE)
  }
  
  basis.list = list(B = B, Bi = Bi, 
                    ind = ind, ind.inside = ind.inside)
  return(basis.list)
}
