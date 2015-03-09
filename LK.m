% Estimates motion from bounding box BB1 in frame I to bounding box BB2 in frame J
function [BB3, xFJ, flag, medFB, medNCC] = LK(I, J, BB1, BB2, level)

% initialize output variables
BB3 = []; % estimated bounding

% exit function if BB1 or BB2 is not defined
if isempty(BB1) || ~bb_isdef(BB1)
    return;
end

% estimate BB3
xFI  = bb_points(BB1,10,10,5); % generate 10x10 grid of points within BB1 with margin 5 px
if isempty(BB2) || ~bb_isdef(BB2)
    xFII = xFI;
else
    xFII = bb_points(BB2,10,10,5);
end
% track all points by Lucas-Kanade tracker from frame I to frame J, 
% estimate Forward-Backward error, and NCC for each point
xFJ    = lk(2, I, J, xFI, xFII, level);

medFB  = median2(xFJ(3,:)); % get median of Forward-Backward error
medNCC = median2(xFJ(4,:)); % get median for NCC
idxF   = xFJ(3,:) <= medFB & xFJ(4,:)>= medNCC; % get indexes of reliable points
BB3    = bb_predict(BB1, xFI(:,idxF), xFJ(1:2,idxF)); % estimate BB2 using the reliable points only

% LK_show(I, J, xFI, BB1, xFJ, BB3);
% pause(0.5);

% save selected points (only for display purposes)
xFJ = xFJ(:, idxF);

flag = 1;
% detect failures
% bounding box out of image
if ~bb_isdef(BB3) || bb_isout(BB3, size(J))
    flag = 2;
    return;
end
% too unstable predictions
if medFB > 10
    flag = 3;
    return;
end