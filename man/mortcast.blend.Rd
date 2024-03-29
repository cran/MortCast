% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/other_methods.R
\name{mortcast.blend}
\alias{mortcast.blend}
\title{Mortality Prediction by Method Blending}
\usage{
mortcast.blend(
  e0m,
  e0f,
  meth1 = "lc",
  meth2 = "mlt",
  weights = c(1, 0.5),
  nx = 5,
  apply.kannisto = TRUE,
  min.age.groups = 28,
  match.e0 = TRUE,
  keep.lt = FALSE,
  meth1.args = NULL,
  meth2.args = NULL,
  kannisto.args = NULL,
  ...
)
}
\arguments{
\item{e0m}{A time series of future male life expectancy.}

\item{e0f}{A time series of future female life expectancy.}

\item{meth1}{Character string giving the name of the first method to blend. It is one of 
\dQuote{lc}, \dQuote{pmd}, \dQuote{mlt} or \dQuote{logquad}, corresponding to Coherent Lee-Carter (function \code{\link{mortcast}}), 
 Pattern Mortality Decline (function \code{\link{copmd}}), Log-Quadratic model (function \code{\link{logquadj}}), and 
 Model Life Tables (function \code{\link{mltj}}), respectively. The \dQuote{logquad} method can only be used 
 with 5-year age groups.}

\item{meth2}{Character string giving the name of the second method to blend. 
One of the same choices as \code{meth1}.}

\item{weights}{Numeric vector with values between 0 and 1 giving the weight of \code{meth1}.
If it is a single value, the same weight is applied for all time periods. 
If it is a vector of size two, it is assumed these are weights for the first and the last
time period. Remaining weights will be interpolated. Note that \code{meth2} is weighted 
by \code{1 - weights}.}

\item{nx}{Size of age groups. Should be either 5 or 1.}

\item{apply.kannisto}{Logical. If \code{TRUE} and if any of the methods results in less than 
\code{min.age.groups} age categories, the coherent Kannisto method (\code{\link{cokannisto}}) 
is applied to extend the age groups into old ages.}

\item{min.age.groups}{Minimum number of age groups. Triggers the application of Kannisto, see above. 
Change the default value if 1-year age groups are used (see Example).}

\item{match.e0}{Logical. If \code{TRUE} the blended mx is scaled so that it matches the input e0.}

\item{keep.lt}{Logical. If \code{TRUE} additional life table columns are kept in the 
resulting object. Only used if \code{match.e0} is \code{TRUE}.}

\item{meth1.args}{List of arguments passed to the function that corresponds to \code{meth1}.}

\item{meth2.args}{List of arguments passed to the function that corresponds to \code{meth2}.}

\item{kannisto.args}{List of arguments passed to the \code{\link{cokannisto}} function if Kannisto is applied. 
If 1-year age groups are used various defaults in the Kannisto function need to be changed (see Example).}

\item{\dots}{Additional life table arguments.}
}
\value{
List with elements \code{female} and \code{male}, each of which contains a matrix \code{mx}
    with the predicted mortality rates. If the result has been scaled (\code{match.e0} is \code{TRUE}), the element 
    \code{mx.rawblend} contains the mx before scaling. Also in such a case, if \code{keep.lt} is \code{TRUE}, it also 
    contains matrices \code{sr} (survival rates), and life table quantities \code{Lx} and \code{lx}.
    In addition, the return object contains elements \code{meth1res} and \code{meth2res}
    which contain the results of the functions corresponding to the two methods. 
    Elements \code{meth1} and \code{meth2} contain the names of the methods. 
    A vector \code{weights} contains the final (possibly interpolated) weights.
}
\description{
Predict age-specific mortality rates using a blend of two different methods (Coherent Lee-Carter, 
    Coherent Pattern Mortality Decline, Log-Quadratic model, or Model Life Tables). Weights can be applied to fine-tune the blending mix.
}
\details{
The function allows to combine two different methods using given weights.
    The weights can change over time - by default they are interpolated from the starting weight 
    to the end weight. As the blended mortality rates do not necessarily match the target life expectancy, 
    scaling is applied to improve the match, controlled by the \code{match.e0} argument. 
    The projection is done for both sexes, so that coherent methods can be applied.
}
\examples{
data(mxM, mxF, e0Fproj, e0Mproj, package = "wpp2017")
country <- "Brazil"
# estimate parameters from historical mortality data
mxm <- subset(mxM, name == country)[,4:16]
mxf <- subset(mxF, name == country)[,4:16]
rownames(mxm) <- rownames(mxf) <- c(0,1, seq(5, 100, by=5))
lcest <- lileecarter.estimate(mxm, mxf)
# project into future
e0f <- subset(e0Fproj, name == country)[-(1:2)]
e0m <- subset(e0Mproj, name == country)[-(1:2)]

# Blend LC and MLT
pred1 <- mortcast.blend(e0m, e0f, meth1 = "lc", meth2 = "mlt",
    meth1.args = list(lc.pars = lcest),
    meth2.args = list(type = "CD_North"),
    weights = c(1,0.25))
    
# Blend PMD and MLT
pred2 <- mortcast.blend(e0m, e0f, meth1 = "pmd", meth2 = "mlt",
    meth1.args = list(mxm0 = mxm[, "2010-2015"],
                      mxf0 = mxf[, "2010-2015"]))
                      
# plot projection by time
plotmx <- function(pred, iage, main) 
    with(pred, {
        # blended projections 
        plot(female$mx[iage,], type="l", 
            ylim=range(meth1res$female$mx[iage,], 
                       meth2res$female$mx[iage,]),
            ylab="female mx", xlab="Time", main=main, col = "red")
        lines(meth1res$female$mx[iage,], lty = 2)
        lines(meth2res$female$mx[iage,], lty = 3)
        legend("topright", legend=c("blend", meth1, meth2),
               lty = 1:3, col = c("red", "black", "black"), bty = "n")
    })
age.group <- 3 # 5-9 years old
par(mfrow=c(1,2))
plotmx(pred1, age.group, "LC-MLT (age 5-9)")
plotmx(pred2, age.group, "PMD-MLT (age 5-9)")

# Blend LC and MLT for 1-year age groups
#########################################
# First interpolate e0 to get 1-year life expectancies (for first five years)
e0m1y <- approx(as.double(e0m[,1:2]), n = 5)$y
e0f1y <- approx(as.double(e0f[,1:2]), n = 5)$y
# derive toy mx in order to get some LC parameters
mxm1y <- mlt(seq(70, 72, length = 4), sex = "male", nx = 1)
mxf1y <- mlt(seq(78, 79, length = 4), sex = "female", nx = 1)
lcest1y <- lileecarter.estimate(mxm1y, mxf1y, nx = 1)

# projections
pred3 <- mortcast.blend(e0m1y, e0f1y, meth1 = "lc", meth2 = "mlt",
    weights = c(1,0.25), min.age.groups = 131, nx = 1, 
    meth1.args = list(lc.pars = lcest1y),
    kannisto.args = list(est.ages = 90:99, proj.ages = 100:130))
    
# plot results
par(mfrow=c(1,1))
plot(0:130, pred3$female$mx[,5], log = "y", type = "l", col = "red")
lines(0:130, pred3$male$mx[,5], col = "blue")

}
\seealso{
\code{\link{mortcast}}, \code{\link{copmd}}, \code{\link{mltj}}, \code{\link{logquad}},
    \code{\link{cokannisto}}
}
