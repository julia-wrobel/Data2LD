\name{Data2LD.opt}
\alias{Data2LD.opt}
\title{
  Optimize the mean of squared errors data-fitting criterion for a system of linear 
  differential equations.
}
\description{
  This function calls function \code{Data2LD} in each iteration of a quasi-Newton 
  type optimization algorithm, allowing for a set of linear restrictions on the 
  parameter vector.
}  
\usage{
Data2LD.opt(yList, XbasisList, modelList, coefList, rhoMat, 
            convcrit = 1e-6, iterlim = 20, dbglev = 1, 
            parMap = diag(rep(1,npar)), wtvec = rep(1,nvar))
}
\arguments{
  \item{yList}{A list of length NVAR.  Each list contains in turn a struct object with                fields:
    \describe{
      \item{argvals}{is a vector of length \eqn{n_i} of observation times}
      \item{y}{is a matrix with \eqn{n_i} rows and \emph{N} columns.
      The number of columns must be the same for all variables,
      except that, if a list is empty, that variable is taken to be not observed.}
    }
  }
  \item{XbasisList}{A list array of length \emph{d}.  Each member contains in turn
   a functional data object or a functional basis object.}
  \item{modelList}{A list each member of which specifies one of linear differential 
  equations in the system.  These can be    
   constructed using function \code{make.variable}.  See the help file for that 
   function for further details.}
  \item{coefList}{A list each member of which specifies one of the coefficients that 
  multiply one or more terms in the system. These can be constructed using function 
  \code{make.coef}.  
  See the help file for that function for further details.}
  \item{rhoMat}{A real number in the half-open interval \eqn{[0,T)]}.  Its value 
  determines the relative emphasis on fitting the data versus being a solution of 
  the differential equation.  The smaller the value, the more the emphasis on data 
  fitting.}
  \item{convcrit}{A one- or two-part convergence criterion.  The first part is 
  for testing the convergence of the criterion values, and the second part, if 
  present in a vector of length 2, is for testing the norm of the gradient.}
  \item{iterlim}{Maximum number of iterations allowed.}
  \item{dbglev}{Control the output on each iteration.  If 0, no output is displayed.  
  If 1, the criterion and gradient norm at each iteration.  
  If 2, the stepsize, slope and criterion at each step in the line search.
  if 3, displays, in addition to 2, a plot of the criterion values and slope after each 
  line search followed by a pause.}
  \item{parMap}{A rectangular matrix with number of rows equal to the
  number of parameters to be estimated, and number of columns equal to the number of 
  parameters less the number of linear constraints on the estimated parameters.  
  The columns of PARMAP must be orthnormal so that the crossproduct is an identity 
  matrix. The crossproduct of \code{t(PARMAP)} and \code{THETA} maps unconstrained 
  parameters and the corresponding gradient into  constrained parameter space.
  \code{PARMAP} will usually be set up using the full QR decomposition of a linear 
  constraint coefficient matrix \code{t(A)} where the constraints are of the form 
  A P = B, A and B being known matrices.  An example of such a constraint
  that arises often is one where two estimated coefficients are constrained to be equal.  
  For example, if a variable X involved in an equation the form a(x - x.0), where x.0
  is a fixed set point or defined target level for variable X, then this would be set 
  up as a.1 x + a.2 x.0, where coefficients a.1 and a.2 are constrained to be equal in
  magnitude but opposite in sign, or a.1 + a.2 = 0. }
  \item{wtvec}{A vector of length \emph{d} containing positive weighting values for 
  variable weighting of the contributions of equations to the fitting criterion and 
  its gradient.}
}                                      
\value{A named list object containing these results of the analysis:
    \item{theta.opt:}{A vector containing the optimal parameter values.}
    \item{coefList.opt:}{The coefficient list containing the optimal parameter values.}
}
\references{
    J. O. Ramsay and G. Hooker (2017) \emph{Dynamic Data Analysis}. Springer.
}
\seealso{
  \code{\link{Data2LD}}
}
\examples{
#
#  Example 1:  The refinery data
#
# The single equation requires two coefficients:
# 1. A constant coefficient for the speed of reaction
# 2. A constant coefficient for the single forcing function
#  Set up the observation times and range 
TimeData <- RefineryData[,"Time"]
TimeRng  <- range(TimeData)
# Defne a constant basis object
conbasis <- create.constant.basis(TimeRng)
#  Define the two coefficient functions and
#  store these in a coefficient function list
TrayCoefList <- vector("list",2)
# Both coefficients are estimated and both have initial value 0.
TrayCoefList[[1]] <- make.coef(fun=conbasis, parvec=0, estimate=TRUE)
TrayCoefList[[2]] <- make.coef(fun=conbasis, parvec=0, estimate=TRUE)
#  Run a check on the coefficient List array, 
#  which also counts the number of estimated parameters
TraycoefResult <- coefCheck(TrayCoefList)
TrayCoefList   <- TraycoefResult$coefList
TrayNtheta     <- TraycoefResult$ntheta
print(paste("ntheta = ",TrayNtheta))
#  Define single homogeneous term with order zero derivative, 
#  constant multiplier -1, and defined by the first coeffcient
XTerm <- make.Xterm(variable=1, derivative=0, ncoef=1, factor=-1)
XList <- vector("list", 1)
XList[[1]] <- XTerm
#  Define the step forcing function for the valve setting
Valvebreaks <- c(0,67,193)
Valvenbasis <- 2
Valvenorder <- 1
ValveBasis  <- create.bspline.basis(TimeRng, Valvenbasis, Valvenorder, Valvebreaks)
#  smooth the valve setting data to define the step forcing function
ValveData <- RefineryData[,"Valve.setting"]
Valvefd   <- smooth.basis(TimeData, ValveData, ValveBasis)$fd
#  Define the FList object for the single forcing function
FTerm <- make.Fterm(ncoef=2, Ufd=Valvefd)
FList <- vector("list", 1)
FList[[1]] <- FTerm
#  Define the single differential equation in the first order model
TrayVariable <- make.variable(name="Tray level", order=1, XList=XList, FList=FList)
#  check the object for internal consistency
TrayList=vector("list",1)
TrayList[[1]] <- TrayVariable
#  check the object for internal consistency
TrayModelList <- modelCheck(TrayList, TrayCoefList)
#  Define the List array containing the tray data
Tray.yList <- list(argvals=RefineryData[,"Time"], 
                   y      =RefineryData[,"Tray.level"])
TrayDataList  <- vector("list",1)
TrayDataList[[1]] <- Tray.yList
# Construct the basis object for tray variable
#  Order 5 spline basis with four knots at the 67
#   to allow discontinuity in the first derivative
#  and 15 knots between 67 and 193
Traynorder <- 5
Traybreaks <- c(0, rep(67,3), seq(67, 193, len=15))
Traynbasis <- 22
TrayBasis  <- create.bspline.basis(c(0,193), Traynbasis, Traynorder, Traybreaks)
#  Set up the basis list for the tray variable
TrayBasisList    <- vector("list",1)
TrayBasisList[[1]] <- TrayBasis
#  Set smoothing constant rho to a value specifying light smoothing
rhoVec <- 0.5 
#  Evaluate the fit to the data given the initial parameter estimates (0 and 0)
#  This also initializes the four-way tensors so that they are not re-computed
#  for subsquent analyses.
Data2LDList <- Data2LD(TrayDataList, TrayBasisList, TrayModelList, TrayCoefList, rhoVec)
MSE  <- Data2LDList$MSE    # Mean squared error for fit to data
DMSE <- Data2LDList$DpMSE  #  gradient with respect to parameter values
#  The use of Data2LD.opt requires setting up one of the example codes for 
#  function make.variable, setting up value to variable rho within [0,1) 
#  (0.5 is a typical choice), invoking function Data2LD in order to compute the 
#  four-way tensors required for fast computation, and then setting up code like 
#  this from the RefineryDemo.R code in the demo folder.  
#  This code calls Data2LD.opt repeatedly over an increasing sequence of values of rho,
#  feeding in the estimates of parameters from the previous values.
#  These parameters control the optimization.
dbglev   <-  1    #  debugging level
iterlim  <- 50    #  maximum number of iterations
convrg   <- c(1e-8, 1e-4)  #  convergence criterion
#  This sets up an increasing sequence of rho values
gammavec <- 0:7
rhoMat   <- exp(gammavec)/(1+exp(gammavec))
nrho    <- length(rhoMat)
dfesave <- matrix(0,nrho,1)
gcvsave <- matrix(0,nrho,1)
MSEsave <- matrix(0,nrho,1)
thesave <- matrix(0,nrho,TrayNtheta)
#  This initializes the list object containing coefficient estimates
TrayCoefList.opt <- TrayCoefList
# Loop through values of rho.  
# for test purposes, only the first value rho = 0.5 is used here
for (irho in 1:1) {
  rhoi <- rhoMat[irho]
  print(paste("rho <- ",round(rhoi,5)))
  Data2LDResult <- 
    Data2LD.opt(TrayDataList, TrayBasisList, TrayModelList, TrayCoefList.opt, 
                rhoi, convrg, iterlim, dbglev)
  theta.opti <- Data2LDResult$thetastore
  TrayCoefList.opti <- modelVec2List(theta.opti, TrayCoefList)
  Data2LDList <- Data2LD(TrayDataList, TrayBasisList, TrayModelList, 
                         TrayCoefList.opti, rhoi)
  MSE       <- Data2LDList$MSE 
  df        <- Data2LDList$df
  gcv       <- Data2LDList$gcv 
  ISE       <- Data2LDList$ISE 
  Var.theta <- Data2LDList$Var.theta
  thesave[irho,] <- theta.opti
  dfesave[irho]   <- df
  gcvsave[irho]   <- gcv
  MSEsave[irho]   <- MSE
}
}
