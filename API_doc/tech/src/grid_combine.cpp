// #include <Rcpp.h>
// [[Rcpp::plugins(cpp14)]]
// using namespace Rcpp;

#include <RcppArmadillo.h>
// [[Rcpp::depends(RcppArmadillo)]]

#include <Rcpp.h>
#include <vector>
#include <algorithm>
using namespace Rcpp;
using namespace std;
using namespace arma;

// [[Rcpp::export]]
Rcpp::List grid_combineC (SEXP x, SEXP y, int grd_sel) {
  NumericVector xi(x);
  NumericVector yi(y);
  IntegerVector sgnx = sign(xi);
  IntegerVector sgny = sign(yi);
  NumericVector xs = abs(xi);
  NumericVector ys = abs(yi);
  
  vec xt = floor( xs * 100.00 + 0.5 ) / 100.00;
  vec yt = floor( ys * 100.00 + 0.5 ) / 100.00;
  vec xl = floor(xt);
  vec yl = floor(yt);
  colvec lon(xl.begin(), xl.size(), false);
  colvec lat(yl.begin(), yl.size(), false);
  if (!is_finite(grd_sel) || grd_sel>3 || grd_sel<0) {
    return Rcpp::List::create(Named("lon") = as<vec>(xi), Named("lat") = as<vec>(yi));
  }
  
  if (grd_sel==3) {
    lon = floor(xl/2)*2;
    lat = floor(yl/2)*2;
  } else if (grd_sel==1) {
    int n = lon.size();
    for(int j = 0; j < n; j++) {
      lon[j] = (xt[j]-lon[j])>=0.5? lon[j]+0.5: lon[j];
      lat[j] = (yt[j]-lat[j])>=0.5? lat[j]+0.5: lat[j];
    }
  } else if (grd_sel==0) {
    int n = lon.size();
    for(int j = 0; j < n; j++) {
      lon[j] = (xt[j]-lon[j])>=0.5? lon[j]+0.5: lon[j];
      lat[j] = (yt[j]-lat[j])>=0.5? lat[j]+0.5: lat[j];
      lon[j] = (xt[j]-lon[j])>=0.25? lon[j]+0.25: lon[j];
      lat[j] = (yt[j]-lat[j])>=0.25? lat[j]+0.25: lat[j];
    }
  }
  return Rcpp::List::create(Named("lon") = lon % as<vec>(sgnx), Named("lat") = lat % as<vec>(sgny));
}