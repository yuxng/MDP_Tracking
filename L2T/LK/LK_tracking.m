% Copyright 2011 Zdenek Kalal
%
% This file is part of TLD.
% 
% TLD is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% TLD is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with TLD.  If not, see <http://www.gnu.org/licenses/>.

% Estimates motion of bounding box BB1 from frame I to frame J
function [BB2, xFJ, flag] = LK_tracking(tld, BB1, I, J)

% initialize output variables
BB2 = []; % estimated bounding

% exit function if BB1 is not defined
if isempty(BB1) || ~bb_isdef(BB1)
    return;
end 

% estimate BB2
xFI    = bb_points(BB1,10,10,5); % generate 10x10 grid of points within BB1 with margin 5 px
% track all points by Lucas-Kanade tracker from frame I to frame J, 
% estimate Forward-Backward error, and NCC for each point
xFJ    = lk(2, I, J, xFI, xFI); 
medFB  = median2(xFJ(3,:)); % get median of Forward-Backward error
medNCC = median2(xFJ(4,:)); % get median for NCC
idxF   = xFJ(3,:) <= medFB & xFJ(4,:)>= medNCC; % get indexes of reliable points
BB2    = bb_predict(BB1,xFI(:,idxF),xFJ(1:2,idxF)); % estimate BB2 using the reliable points only

LK_show(I, J, xFI, xFJ);

% save selected points (only for display purposes)
xFJ = xFJ(:, idxF);

flag = 1;
% detect failures
% bounding box out of image
if ~bb_isdef(BB2) || bb_isout(BB2, size(J))
    fprintf('bounding box out of image\n');
    flag = 2;
    return;
end
% too unstable predictions
if medFB > 10
    fprintf('too unstable predictions\n');
    flag = 3;
    return;
end

% estimate confidence and validity
% patchJ = tldGetPattern(J, BB2, tld.patchsize); % sample patch in current image
% estimate its Conservative Similarity (considering 50% of positive patches only)
% [~, Conf] = tldNN(patchJ, tld);