/*
function [assignment, cost] = assignmentsuboptimal1(distMatrix)
*/

#include <mex.h>
#include <matrix.h>

#define CHECK_FOR_INF
#define ONE_INDEXING

void assignmentsuboptimal1(double *assignment, double *cost, double *distMatrix, int nOfRows, int nOfColumns);

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
	assignmentsuboptimal1(assignment, cost, distMatrix, nOfRows, nOfColumns);	
}

void assignmentsuboptimal1(double *assignment, double *cost, double *distMatrixIn, int nOfRows, int nOfColumns)
{
	bool infiniteValueFound, finiteValueFound, repeatSteps, allSinglyValidated, singleValidationFound;
	int n, row, col, tmpRow, tmpCol, nOfElements;
	int *nOfValidObservations, *nOfValidTracks;
	double value, minValue, *distMatrix, inf;
	
	inf = mxGetInf();
	
	/* make working copy of distance Matrix */
	nOfElements   = nOfRows * nOfColumns;
	distMatrix    = (double *)mxMalloc(nOfElements * sizeof(double));
	for(n=0; n<nOfElements; n++)
		distMatrix[n] = distMatrixIn[n];
	
	/* initialization */
	*cost = 0;
#ifdef ONE_INDEXING
	for(row=0; row<nOfRows; row++)
		assignment[row] =  0.0;
#else
	for(row=0; row<nOfRows; row++)
		assignment[row] = -1.0;
#endif
	
	/* allocate memory */
	nOfValidObservations  = (int *)mxCalloc(nOfRows,    sizeof(int));
	nOfValidTracks        = (int *)mxCalloc(nOfColumns, sizeof(int));
		
	/* compute number of validations */
	infiniteValueFound = false;
	finiteValueFound  = false;
	for(row=0; row<nOfRows; row++)
		for(col=0; col<nOfColumns; col++)
			if(mxIsFinite(distMatrix[row + nOfRows*col]))
			{
				nOfValidTracks[col]       += 1;
				nOfValidObservations[row] += 1;
				finiteValueFound = true;
			}
			else
				infiniteValueFound = true;
				
	if(infiniteValueFound)
	{
		if(!finiteValueFound)
			return;
			
		repeatSteps = true;
		
		while(repeatSteps)
		{
			repeatSteps = false;

			/* step 1: reject assignments of multiply validated tracks to singly validated observations		 */
			for(col=0; col<nOfColumns; col++)
			{
				singleValidationFound = false;
				for(row=0; row<nOfRows; row++)
					if(mxIsFinite(distMatrix[row + nOfRows*col]) && (nOfValidObservations[row] == 1))
					{
						singleValidationFound = true;
						break;
					}
					
				if(singleValidationFound)
				{
					for(row=0; row<nOfRows; row++)
						if((nOfValidObservations[row] > 1) && mxIsFinite(distMatrix[row + nOfRows*col]))
						{
							distMatrix[row + nOfRows*col] = inf;
							nOfValidObservations[row] -= 1;							
							nOfValidTracks[col]       -= 1;	
							repeatSteps = true;				
						}
					}
			}
			
			/* step 2: reject assignments of multiply validated observations to singly validated tracks */
			if(nOfColumns > 1)			
			{	
				for(row=0; row<nOfRows; row++)
				{
					singleValidationFound = false;
					for(col=0; col<nOfColumns; col++)
						if(mxIsFinite(distMatrix[row + nOfRows*col]) && (nOfValidTracks[col] == 1))
						{
							singleValidationFound = true;
							break;
						}
						
					if(singleValidationFound)
					{
						for(col=0; col<nOfColumns; col++)
							if((nOfValidTracks[col] > 1) && mxIsFinite(distMatrix[row + nOfRows*col]))
							{
								distMatrix[row + nOfRows*col] = inf;
								nOfValidObservations[row] -= 1;
								nOfValidTracks[col]       -= 1;
								repeatSteps = true;								
							}
						}
				}
			}
		} /* while(repeatSteps) */
	
		/* for each multiply validated track that validates only with singly validated  */
		/* observations, choose the observation with minimum distance */
		for(row=0; row<nOfRows; row++)
		{
			if(nOfValidObservations[row] > 1)
			{
				allSinglyValidated = true;
				minValue = inf;
				for(col=0; col<nOfColumns; col++)
				{
					value = distMatrix[row + nOfRows*col];
					if(mxIsFinite(value))
					{
						if(nOfValidTracks[col] > 1)
						{
							allSinglyValidated = false;
							break;
						}
						else if((nOfValidTracks[col] == 1) && (value < minValue))
						{
							tmpCol   = col;
							minValue = value;
						}
					}
				}
				
				if(allSinglyValidated)
				{
	#ifdef ONE_INDEXING
					assignment[row] = tmpCol + 1;
	#else
					assignment[row] = tmpCol;
	#endif
					*cost += minValue;
					for(n=0; n<nOfRows; n++)
						distMatrix[n + nOfRows*tmpCol] = inf;
					for(n=0; n<nOfColumns; n++)
						distMatrix[row + nOfRows*n] = inf;
				}
			}
		}

		/* for each multiply validated observation that validates only with singly validated  */
		/* track, choose the track with minimum distance */
		for(col=0; col<nOfColumns; col++)
		{
			if(nOfValidTracks[col] > 1)
			{
				allSinglyValidated = true;
				minValue = inf;
				for(row=0; row<nOfRows; row++)
				{
					value = distMatrix[row + nOfRows*col];
					if(mxIsFinite(value))
					{
						if(nOfValidObservations[row] > 1)
						{
							allSinglyValidated = false;
							break;
						}
						else if((nOfValidObservations[row] == 1) && (value < minValue))
						{
							tmpRow   = row;
							minValue = value;
						}
					}
				}
				
				if(allSinglyValidated)
				{
	#ifdef ONE_INDEXING
					assignment[tmpRow] = col + 1;
	#else
					assignment[tmpRow] = col;
	#endif
					*cost += minValue;
					for(n=0; n<nOfRows; n++)
						distMatrix[n + nOfRows*col] = inf;
					for(n=0; n<nOfColumns; n++)
						distMatrix[tmpRow + nOfRows*n] = inf;
				}
			}
		}	
	} /* if(infiniteValueFound) */
	
	
	/* now, recursively search for the minimum element and do the assignment */
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
	
	/* free allocated memory */
	mxFree(nOfValidObservations);
	mxFree(nOfValidTracks);


}

