function [assignment, cost] = assignmentsuboptimal2(distMatrix)
%ASSIGNMENTSUBOPTIMAL2    Compute suboptimal assignment
%		ASSIGNMENTSUBOPTIMAL2(DISTMATRIX) computes a suboptimal assignment
%		(minimum overall costs) for the given rectangular distance or cost
%		matrix, for example the assignment of tracks (in rows) to observations
%		(in columns). The result is a column vector containing the assigned
%		column number in each row (or 0 if no assignment could be done).
%
%		[ASSIGNMENT, COST] = ASSIGNMENTSUBOPTIMAL2(DISTMATRIX) returns the 
%		assignment vector and the overall cost.
%
%		The algorithm searches the matrix for the minimum element and makes the
%		corresponding row-column assignment. After setting all elements in the
%		given row and column to infinity (i.e. forbidden assignment), the
%		search procedure is repeated until all assignments are done or only
%		infinite values are found.
%
%		This function and the corresponding mex-function can further be
%		improved by first sorting all elements instead of searching for the
%		minimum of all elements many times.
%
%		<a href="assignment.html">assignment.html</a>  <a href="http://www.mathworks.com/matlabcentral/fileexchange/6543">File Exchange</a>  <a href="https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=EVW2A4G2HBVAU">Donate via PayPal</a>
%
%		Markus Buehren
%		Last modified 05.07.2011

% initialize
nOfRows = size(distMatrix, 1);
assignment = zeros(nOfRows,1);
cost       = 0;

for n=1:nOfRows
	
	% find minimum distance observation-to-track pair
	[minDist, index1] = min(distMatrix, [], 1);
	[minDist, index2] = min(minDist);
	row = index1(index2);
	col = index2;
	
	if isfinite(minDist)
		
		% make the assignment
		assignment(row) = col;
		cost = cost + minDist;
		
		% delete observation-to-track pair
		distMatrix(row, :) = inf;
		distMatrix(:, col) = inf;
		
	else
		return		
	end
	
end
