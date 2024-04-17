/*! @file NavierStokes2DComputeCFL.c
    @author Debojyoti Ghosh
    @brief Compute the maximum CFL.
*/
#include <stdlib.h>
#include <math.h>
#include <basic.h>
#include <arrayfunctions.h>
#include <mathfunctions.h>
#include <physicalmodels/navierstokes2d.h>
#include <hypar.h>

/*! Computes the maximum CFL number over the domain. Note that the CFL
    is computed over the local domain on this processor only.
*/
double NavierStokes2DComputeCFL(
                                void    *s, /*!< Solver object of type #HyPar */
                                void    *m, /*!< MPI object of type #MPIVariables */
                                double  dt, /*!< Time step size for which to compute the CFL */
                                double  t   /*!< Time */
                               )
{
  HyPar   *solver = (HyPar*)   s;
  NavierStokes2D *param  = (NavierStokes2D*) solver->physics;
  _DECLARE_IERR_;

  int *dim    = solver->dim_local;
  int ghosts  = solver->ghosts;
  int ndims   = solver->ndims;
  int index[ndims];
  double *u   = solver->u;

  double max_cfl = 0;
  int done = 0; _ArraySetValue_(index,ndims,0);
  while (!done) {
    int p; _ArrayIndex1D_(ndims,dim,index,ghosts,p);
    double rho,vx,vy,e,P,c,dxinv,dyinv,local_cfl[2];
    _NavierStokes2DGetFlowVar_((u+_MODEL_NVARS_*p),rho,vx,vy,e,P,param->gamma);

    c = sqrt(param->gamma*P/rho); /* speed of sound */
    _GetCoordinate_(_XDIR_,index[_XDIR_],dim,ghosts,solver->dxinv,dxinv); /* 1/dx */
    _GetCoordinate_(_YDIR_,index[_YDIR_],dim,ghosts,solver->dxinv,dyinv); /* 1/dy */

    local_cfl[_XDIR_] = (absolute(vx)+c)*dt*dxinv; /* local cfl for this grid point (x) */
    local_cfl[_YDIR_] = (absolute(vy)+c)*dt*dyinv; /* local cfl for this grid point (y) */
    if (local_cfl[_XDIR_] > max_cfl) max_cfl = local_cfl[_XDIR_];
    if (local_cfl[_YDIR_] > max_cfl) max_cfl = local_cfl[_YDIR_];

    _ArrayIncrementIndex_(ndims,dim,index,done);
  }

  return(max_cfl);
}
