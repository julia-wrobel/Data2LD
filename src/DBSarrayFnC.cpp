#include <R.h>
#include <Rinternals.h>

extern "C" {
  SEXP DBSarrayFnC(SEXP nXbasisw, SEXP nWbasisw, SEXP nUbasisj, SEXP nAbasisj,  
                   SEXP nrep,     SEXP AVECJ,    SEXP UCOEFJ,   SEXP BATENS)
  {
    int nDBSarray;
    SEXP DBSarray;
    int nXw = *INTEGER(nXbasisw);
    int nWw = *INTEGER(nWbasisw);
    int nUj = *INTEGER(nUbasisj);
    int nAj = *INTEGER(nAbasisj);
    int nRp = *INTEGER(nrep);
    double* Avecj  = REAL(AVECJ);
    double* Ucoefj = REAL(UCOEFJ);
    double* BAtens = REAL(BATENS);
    double* rDBSarray;
    nDBSarray = nXw*nRp*nAj;
    DBSarray  = PROTECT(allocVector(REALSXP, nDBSarray));
    rDBSarray = REAL(DBSarray);
    /* assign 0 to all positions */
    for (int p = 0; p < nDBSarray; p++)
    {
      rDBSarray[p]=0;
    }
    /* loop through all columns of all four input matrices */
    for (int r = 0; r < nRp; r++)
    {
      for (int i = 0; i < nXw; i++)
      {
        for (int j = 0; j < nWw; j++)
        {
          for (int k = 0; k < nUj; k++)
          {
            for (int l = 0; l < nAj; l++)
            {
              int ijkl = i*nAj*nUj*nWw + j*nAj*nUj + k*nAj + l;
              /*  increment value at index by the product */
              rDBSarray[i+r*nXw+j*nRp*nXw] +=
              Avecj[l] * Ucoefj[k+r*nUj] * BAtens[ijkl];
            }
          }
        }
      }
    }
    UNPROTECT(1);
    return DBSarray;
  }
}
