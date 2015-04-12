/*
function [assignment, cost] = assignmentsuboptimal2(distMatrix)
*/

#include <mex.h>
#include <matrix.h>

#define CHECK_FOR_INF
#define ONE_INDEXING

void assignmentsuboptimal2(double *assignment, double *cost, double *distMatrix, int nOfRows, int nOfColumns);

void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[] )
{
	double *assignment, *cost, *distMatrix;
	int nOfRows, nOfColumns;
	
	/* Input arguments */
	nOfRows    = mxGetM(prhs[0]);
	nOfColumns = mxGetN(prhs[0]);
	distMatrix = mxGetPr(prhs[0]);
	
	/* Output arguments */
	plhs[0]    = mxCreateDoubleMatrix(nOfRows, 1, mxREAL);
	plhs[1]    = mxCreateDoubleScalar(0);
	assignment = mxGetPr(plhs[0]);
	cost       = mxGetPr(plhs[1]);
	
	/* Call C-function */
	assignmentsuboptimal2(assignment, cost, distMatrix, nOfRows, nOfColumns);	
}

void assignmentsuboptimal2(double *assignment, double *cost, double *distMatrixIn, int nOfRows, int nOfColumns)
{
	int n, row, col, tmpRow, tmpCol, nOfElements;
	double value, minValue, *distMatrix, inf;

	inf = mxGetInf();
	
	/* make working copy of distance Matrix */
	nOfElements   = nOfRows * nOfColumns;
	distMatrix    = (double *)mxMalloc(nOfElements * sizeof(double));
	for(n=0; n<nOfElements; n++)
		distMatrix[n] = distMatrixIn[n];
	
	/* initialization */
	*cost = 0;
	for(row=0; row<nOfRows; row++)
#ifdef ONE_INDEXING
		assignment[row] =  0.0;
#else
		assignment[row] = -1.0;
#endif
	
	/* recursively search for the minimum element and do the assignment */
	while(true)
	{
		/* find minimum distance observation-to-track pair */
		minValue = inf;
		for(row=0; row<nOfRows; row++)
			for(col=0; col<nOfColumns; col++)
			{
				value = distMatrix[row + nOfRows*col];
				if(mxIsFinite(value) && (value < minValue))
				{
					minValue = value;
					tmpRow   = row;
					tmpCol   = col;
				}
			}
		
		if(mxIsFinite(minValue))
		{
#ifdef ONE_INDEXING
			assignment[tmpRow] = tmpCol+ 1;
#else
			assignment[tmpRow] = tmpCol;
#endif
			*cost += minValue;
			for(n=0; n<nOfRows; n++)
				distMatrix[n + nOfRows*tmpCol] = inf;
			for(n=0; n<nOfColumns; n++)
				distMatrix[tmpRow + nOfRows*n] = inf;			
		}
		else
			break;
			
	} /* while(true) */
	
	free(distMatrix);
}

