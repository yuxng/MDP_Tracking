#ifndef _ASSIGNMENT_H_
#define _ASSIGNMENT_H_

#define ONE_INDEXING
//#define WORK_IN_PLACE
#define ASSIGNMENT_INF 9999999

void assignmentsuboptimal1(int *assignment, double *cost, double *distMatrix, int *nOfValidObservations, int *nOfValidTracks, int nOfRows, int nOfColumns);

void          *myMalloc(int sz);
void           myFree(void *ptr);
unsigned char  myIsFinite(double value);
double         myGetInf();

#endif /* _ASSIGNMENT_H_ */

