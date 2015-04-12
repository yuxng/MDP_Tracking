function [assignment, cost] = assignmentsuboptimal1(distMatrix)
%ASSIGNMENTSUBOPTIMAL1    Compute suboptimal assignment
%		ASSIGNMENTSUBOPTIMAL1(DISTMATRIX) computes a suboptimal assignment
%		(minimum overall costs) for the given rectangular distance or cost
%		matrix, for example the assignment of tracks (in rows) to observations
%		(in columns). The result is a column vector containing the assigned
%		column number in each row (or 0 if no assignment could be done).
%
%		[ASSIGNMENT, COST] = ASSIGNMENTSUBOPTIMAL1(DISTMATRIX) returns the 
%		assignment vector and the overall cost. 
%
%		The algorithm is designed for distance matrices with many forbidden and 
%		singly validated assignments, (rows or columns containing only one
%		finite element). The algorithm first searches the matrix for singly
%		validated columns and rejects all assignments with multiply validated
%		row. Afterwards, singly validated rows are searched and assignments to
%		multiply validated columns are rejected. Then, for each row that
%		validates only with singly validated columns (and the other way
%		around), the minimum elements is chosen and the assignment is made. If
%		there are still assignments open, the minimum element in the distMatrix
%		is searched and the corresponding assignment is made.
%
%		In scenarios without any forbidden assignments, the algorithm reduceds
%		to the last step is will give the same result as ASSIGNMENTOPTIMAL2. If
%		there are only some assignments forbidden, the algorithm will perform
%		poorly because singly validated assignments are preferred.
%
%		The last step can still be optimized, see the comments in
%		ASSIGNMENTOPTIMAL2.
%
%		<a href="assignment.html">assignment.html</a>  <a href="http://www.mathworks.com/matlabcentral/fileexchange/6543">File Exchange</a>  <a href="https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=EVW2A4G2HBVAU">Donate via PayPal</a>
%
%		Markus Buehren
%		Last modified 05.07.2011

% initialize
[nOfRows, nOfColumns] = size(distMatrix);
nOfValidObservations  = zeros(nOfRows,1);
nOfValidTracks        = zeros(1,nOfColumns);
assignment            = zeros(nOfRows,1);
cost                  = 0;

% compute number of validations for each track
for row=1:nOfRows
	nOfValidObservations(row) = length(find(isfinite(distMatrix(row,:))));
end

if any(nOfValidObservations < nOfColumns)
	
	if all(nOfValidObservations == 0)
		return
	end
	
	repeatSteps = 1;
	while repeatSteps
		
		repeatSteps = 0;
		
		% step 1: reject assignments of multiply validated tracks to singly validated observations		
		for col=1:nOfColumns
			index = isfinite(distMatrix(:,col));
			nOfValidTracks(col) = length(find(index));
			if any(nOfValidObservations(index) == 1)
				index = index & (nOfValidObservations > 1);
				if any(index)
					distMatrix(index, col)      = inf;
					nOfValidObservations(index) = nOfValidObservations(index) - 1;
					nOfValidTracks(col)         = nOfValidTracks(col) - length(find(index));
					repeatSteps = 1;
				end
			end
		end
		
		% step 2: reject assignments of multiply validated observations to singly validated tracks
		if nOfColumns > 1
			for row=1:nOfRows
				index = isfinite(distMatrix(row,:));
				if any(nOfValidTracks(index) == 1)
					index = index & (nOfValidTracks > 1);
					if any(index)
						distMatrix(row, index)    = inf;
						nOfValidTracks(index)     = nOfValidTracks(index) - 1;
						nOfValidObservations(row) = nOfValidObservations(row) - length(find(index));
						repeatSteps = 1;
					end
				end
			end
		end
		
	end % while repeatSteps
	%disp(sprintf('xx = %d', xx));

	% for each multiply validated track that validates only with singly validated 
	% observations, choose the observation with minimum distance
	for row=1:nOfRows
		if nOfValidObservations(row) > 1
			index = isfinite(distMatrix(row,:));
			if all(nOfValidTracks(index) == 1)
				[minDist, col] = min(distMatrix(row,:));
				assignment(row)    = col;
				cost               = cost + minDist;
				distMatrix(row,:)  = inf;
				distMatrix(:,col)  = inf;
			end
		end
	end
	
	% for each multiply validated observation that validates only with singly validated 
	% track, choose the track with minimum distance
	for col=1:nOfColumns
		if nOfValidTracks(col) > 1
			index = isfinite(distMatrix(:,col));
			if all(nOfValidObservations(index) == 1)
				[minDist, row] = min(distMatrix(:,col));
				assignment(row)    = col;
				cost               = cost + minDist;
				distMatrix(row,:)  = inf;
				distMatrix(:,col)  = inf;
			end
		end
	end
	
end

% now, recursively search for the minimum element and do the assignment
while 1
	
	% find minimum distance observation-to-track pair
	[minDist, index1] = min(distMatrix, [], 1);
	[minDist, index2] = min(minDist);
	row = index1(index2);
	col = index2;
	
	if isfinite(minDist)
		
		% make the assignment
		assignment(row)    = col;
		cost               = cost + minDist;
		distMatrix(row, :) = inf;
		distMatrix(:, col) = inf;
		
	else
		break
	end
	
end
