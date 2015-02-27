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

function [tld, valid] = LK_update(tld, bb, img)

% Check consistency -------------------------------------------------------

pPatt = tldGetPattern(img, bb, tld.patchsize); % get current patch
[pConf1, ~, pIsin] = tldNN(pPatt, tld); % measure similarity to model

% too fast change of appearance
if pConf1 < 0.5
    disp('Fast change.');
    valid = 0;
    return;
end

% too low variance of the patch
if var(pPatt) < tld.var
    disp('Low variance.');
    valid = 0;
    return;
end

% patch is in negative data
if pIsin(3) == 1
    disp('In negative data.');
    valid = 0;
    return;
end

% Update ------------------------------------------------------------------

% generate positive data
% measure overlap of the current bounding box with the bounding boxes on the grid
overlap = bb_overlap(bb, tld.grid);
% generate positive examples from all bounding boxes that are highly overlappipng with current bounding box
pEx = tldGeneratePositiveData(tld, overlap, img);

% generate negative data
nEx = tldGenerateNegativeData(tld, overlap, img);

% update nearest neighbour 
tld = tldTrainNN(pEx, nEx, tld);