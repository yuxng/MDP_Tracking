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

function tracker = LK_tracking(frame_id, dres_image, dres_det, tracker)

% current frame
J = dres_image.Igray{frame_id};

num_det = numel(dres_det.x);
for i = 1:tracker.num
    I = dres_image.Igray{tracker.frame_ids(i)};
    BB1 = [tracker.x1(i); tracker.y1(i); tracker.x2(i); tracker.y2(i)];
    BB1 = bb_rescale_relative(BB1, tracker.rescale_box);
    [BB2, xFJ, flag, medFB, medNCC] = LK(BB1, I, J);
    BB2 = bb_rescale_relative(BB2, 1./tracker.rescale_box);
    
    % compute overlap
    dres.x = BB2(1);
    dres.y = BB2(2);
    dres.w = BB2(3) - BB2(1);
    dres.h = BB2(4) - BB2(2);
    overlap = calc_overlap(dres, 1, dres_det, 1:num_det);
    [o, ind] = max(overlap);
    
    tracker.bbs{i} = BB2;
    tracker.points{i} = xFJ;
    tracker.flags(i) = flag;
    tracker.medFBs(i) = medFB;
    tracker.medNCCs(i) = medNCC;
    tracker.overlaps(i) = o;
    tracker.indexes(i) = ind;
end

% combine tracking and detection results
[~, ind] = min(tracker.medFBs);
if tracker.overlaps(ind) > 0.7
    index = tracker.indexes(ind);
    bb_det = [dres_det.x(index); dres_det.y(index); ...
        dres_det.x(index)+dres_det.w(index); dres_det.y(index)+dres_det.h(index)];
    tracker.bb = mean([repmat(tracker.bbs{ind},1,10) bb_det], 2);
else
    tracker.bb = tracker.bbs{ind};
end

if tracker.flags(ind) == 1
    fprintf('target %d: medFB %.2f %.2f %.2f %.2f %.2f\n', tracker.target_id, tracker.medFBs);
elseif tracker.flags(ind) == 2
    fprintf('target %d: bounding box out of image\n', tracker.target_id);
elseif tracker.flags(ind) == 3
    fprintf('target %d: medFB %.2f, too unstable predictions\n', tracker.target_id, tracker.medFBs(ind));
end

% Estimates motion of bounding box BB1 from frame I to frame J
function [BB2, xFJ, flag, medFB, medNCC] = LK(BB1, I, J)

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

% LK_show(I, J, xFI, BB1, xFJ, BB2);

% save selected points (only for display purposes)
xFJ = xFJ(:, idxF);

flag = 1;
% detect failures
% bounding box out of image
if ~bb_isdef(BB2) || bb_isout(BB2, size(J))
    flag = 2;
    return;
end
% too unstable predictions
if medFB > 10
    flag = 3;
    return;
end