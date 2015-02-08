/*=================================================================
 *
 * IMGaffine_c.c	This is a C code for Matlab.
 *	        
 *=================================================================*/
#include <math.h>
#include "mex.h"

void matrix_multiply(double *x, int x1, int x2, double *y, int y1, int y2, double *z)
{
    int i,j,k;
    if(x2!=y1)
        mexErrMsgTxt("Cannot mutiply such matrixs!");
    for(i=0;i<x1;i++)
    {
        for(j=0;j<y2;j++)
        {
            *(z+i+x1*j) = 0;
            for(k=0;k<x2;k++)
                *(z+i+x1*j) += *(x+i+x1*k) * *(y+k+y1*j);
        }
    }
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    double *AFNV, *OSIZE;
    double *Rp, *Pp, *Kp, *RINp, *ROUTp, *Ip;
    double value, value_1, value_2, total_value[3];
    int M, N;
    int M_in, N_in;
    int i, j, k;
    int dims[3], *d;
    double count;
    mxArray *R, *P, *K;
    
    if (nrhs != 3) 
    {
	    mexErrMsgTxt("Three input arguments required.");
    } 
    else if (nlhs > 2) 
    {
	    mexErrMsgTxt("Too many output arguments.");
    }
    
    M_in = mxGetDimensions(prhs[0])[0];
    N_in = mxGetDimensions(prhs[0])[1];
    RINp = mxGetPr(prhs[0]);
    AFNV = mxGetPr(prhs[1]);
    R = mxCreateDoubleMatrix(3, 3, mxREAL);
    Rp = mxGetPr(R);
    *Rp = *AFNV;
    *(Rp+1) = *(AFNV+2);
    *(Rp+2) = 0;
    *(Rp+3) = *(AFNV+1);
    *(Rp+4) = *(AFNV+3);
    *(Rp+5) = 0;
    *(Rp+6) = *(AFNV+4);
    *(Rp+7) = *(AFNV+5);
    *(Rp+8) = 1;  

    OSIZE = mxGetPr(prhs[2]);
    M = *OSIZE;
    N = *(OSIZE+1);

    P = mxCreateDoubleMatrix(3, M*N, mxREAL);
    Pp = mxGetPr(P);

    for(i = 0, j = 1, k = 1; i < M*N; i++)
    {
        *(Pp+i*3) = j; 
        j++;  
        *(Pp+1+i*3) = k;
        if(j == M+1)
        {
            j = 1;
            k++;
        }
        *(Pp+2+i*3) = 1;
    }

    K = mxCreateDoubleMatrix(3, M*N, mxREAL);
    Kp = mxGetPr(K);
    matrix_multiply(Rp,3,3,Pp,3,M*N,Kp);
    
    for(i=0;i<3*M*N;i++)
    {
        *(Kp+i) = round(*(Kp+i));
    }
    
    /* outputs */
    dims[0] = M;
    dims[1] = N;
    dims[2] = 3;
    plhs[0] = mxCreateNumericArray(3, dims, mxDOUBLE_CLASS, mxREAL);
    ROUTp = mxGetPr(plhs[0]);
    plhs[1] = mxCreateDoubleMatrix(1, 1, mxREAL);
    Ip = mxGetPr(plhs[1]);
    
    count = 0;
    value = 0;
    total_value[0] = 0;
    total_value[1] = 0;
    total_value[2] = 0;
    for(i = 0; i < M*N; i++)
    {
        *(ROUTp+i) = 0;
        *(ROUTp+i + M*N) = 0;
        *(ROUTp+i + 2*M*N) = 0;
        /* use the first M*N entries of P to restore j. */
        *(Pp+i) = 0;
        value_1 = *(Kp+0+i*3);
        value_2 = *(Kp+1+i*3);
        if((value_1 >= 1) & (value_1 <= M_in) & (value_2 >= 1) & (value_2 < N_in))
        {
            *(Pp+i) = 1;     
            count++;   
            value = *(RINp + (int)((value_2 - 1)*M_in + value_1) - 1);
            *(ROUTp+i) = value;
            total_value[0] += value;

            value = *(RINp + (int)((value_2 - 1)*M_in + value_1) - 1 + M_in*N_in);
            *(ROUTp+i + M*N) = value;
            total_value[1] += value;

            value = *(RINp + (int)((value_2 - 1)*M_in + value_1) - 1 + 2*M_in*N_in);
            *(ROUTp+i + 2*M*N) = value;
            total_value[2] += value;

        }
    }

    /* find mean value */
    total_value[0] /= count;
    total_value[1] /= count;
    total_value[2] /= count;
    for(i = 0; i < M*N; i++)
    {
        if(*(Pp+i) == 0)
        {
            *(ROUTp+i) = total_value[0];
            *(ROUTp+i + M*N) = total_value[1];
            *(ROUTp+i + 2*M*N) = total_value[2];
        }
    }

    if(count > 0)
        *Ip = 1;
    else 
        *Ip = 0;   
    mxDestroyArray(K);
    mxDestroyArray(R);
    mxDestroyArray(P);
    return;
}
