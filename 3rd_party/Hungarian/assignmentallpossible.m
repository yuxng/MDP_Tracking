function [assignment, cost] = assignmentallpossible(distMatrix)
%ASSIGNMENTALLPOSSIBLE    Compute solution of assignment problem
%		ASSIGNMENTALLPOSSIBLE(DISTMATRIX) computes the optimal assignment
%		(minimum overall costs) for the given rectangular distance or cost
%		matrix, for example the assignment of tracks (in rows) to observations
%		(in columns). The result is a column vector containing the assigned
%		column number in each row (or 0 if no assignment could be done).
%
%		[ASSIGNMENTALLPOSSIBLE, COST] = ASSIGNMENTALLPOSSIBLE(DISTMATRIX)
%		returns the assignment vector and the overall cost.
%
%		The distance matrix may contain infinite values (forbidden
%		assignments). Internally, the infinite values are set to a very large
%		finite number, so that the algorithm itself works on finite-number
%		matrices. Before returning the assignment, all assignments with
%		infinite distance are deleted (i.e. set to zero).
%
%		The algorithm recursively steps over all possible assignment paths. It
%		is very slow especially for large matrix dimensions. With this, it is
%		only suited for computing a reference solution.
%
%		<a href="assignment.html">assignment.html</a>  <a href="http://www.mathworks.com/matlabcentral/fileexchange/6543">File Exchange</a>  <a href="https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=EVW2A4G2HBVAU">Donate via PayPal</a>
%
%		Markus Buehren
%		Last modified 05.07.2011

[nOfRows, nOfColumns] = size(distMatrix);

% check for infinite values
finiteIndex = isfinite(distMatrix);
if isempty(find(~finiteIndex, 1))
	% no infinite values contained in distMatrix
	% initialize maxCost with suboptimal algorithm
	[suboptimalassignment, maxCost] = assignmentsuboptimal2(distMatrix);
	infValue = inf;
	
else
	% distMatrix contains infinite values
	originalDistMatrix = distMatrix;
	finiteIndex = isfinite(distMatrix);
	index = find(~finiteIndex);
	if ~isempty(index)
		maxFiniteValue = max(max(distMatrix(finiteIndex)));
		if maxFiniteValue > 0
			infValue = abs(10 * maxFiniteValue * nOfRows * nOfColumns);
		else
			infValue = 10;
		end
		if isempty(infValue)
			% all elements are infinite
			assignment = zeros(nOfRows, 1);
			cost       = 0;
			return
		end			
		distMatrix(index) = infValue;
	end
	maxCost = inf;	
end

if nOfRows <= nOfColumns
	
	[assignment, cost] = checksubtree__(distMatrix, 0, maxCost, nOfRows, nOfColumns);
	
	if isempty(assignment)
		% suboptimal solution was equal to optimal solution
		assignment = suboptimalassignment;
	end

else
	
	% use transposed matrix
	[assignment, cost] = checksubtree__(distMatrix.', 0, maxCost, nOfColumns, nOfRows);
	
	if isempty(assignment)
		% suboptimal solution was equal to optimal solution
		assignment = suboptimalassignment;
	else
		% switch index
		assignment = switchindex__(assignment, nOfRows, nOfColumns);
	end
	
end

if cost >= infValue
	% remove invalid assignments
	distMatrix  = originalDistMatrix;
	rowIndex    = find(assignment);
	costVector  = distMatrix(rowIndex + nOfRows * (assignment(rowIndex)-1));
	finiteIndex = isfinite(costVector);
	cost = sum(costVector(finiteIndex));
	assignment(rowIndex(~finiteIndex)) = 0;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function newAssignment = switchindex__(assignment, nOfRows, nOfColumns)

newAssignment             = zeros(nOfRows, 1);
newAssignment(assignment) = (1:nOfColumns);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [newAssignment, newCost] = checksubtree__(distMatrix, curCost, maxCost, nOfRows, nOfColumns)

if nOfRows > 1
	
	newCost       = maxCost;
	newAssignment = [];
	for n=1:nOfColumns
		thisCost = distMatrix(1,n) + curCost;
		if thisCost <= newCost
			
			% recursively pass distMatrix except the current row and column
			colIndex = [1:n-1,n+1:nOfColumns]';
			[thisAssignment, thisCost] = checksubtree__(distMatrix(2:nOfRows, colIndex), thisCost, newCost, nOfRows-1, nOfColumns-1);
			
			if (thisCost <= newCost) && ~isempty(thisAssignment)
				newAssignment = [n; colIndex(thisAssignment)];
				newCost       = thisCost;
			end				
		end	
	end
	
else
	
	[minDist, newAssignment] = min(distMatrix(1,:));
	newCost = minDist + curCost;
	
	if newCost > maxCost
		newAssignment = [];
	end	
	
end
