% use LK trackers for association
function tracker = LK_associate(frame_id, dres_image, dres_det, tracker)

% current frame
J = dres_image.Igray{frame_id};
BB2 = [dres_det.x; dres_det.y; dres_det.x + dres_det.w; dres_det.y + dres_det.h];
BB2 = bb_rescale_relative(BB2, tracker.rescale_box);

for i = 1:tracker.num
    I = dres_image.Igray{tracker.frame_ids(i)};
    BB1 = [tracker.x1(i); tracker.y1(i); tracker.x2(i); tracker.y2(i)];    
    BB1 = bb_rescale_relative(BB1, tracker.rescale_box);
    [BB3, xFJ, flag, medFB, medNCC] = LK(BB1, BB2, I, J);
    BB3 = bb_rescale_relative(BB3, 1./tracker.rescale_box);
    
    if isnan(medFB) || isnan(medNCC) || ~bb_isdef(BB3)
        medFB = inf;
        medNCC = 0;
        o = 0;
        ind = 1;
        angle = 0;
    else
        % compute overlap
        dres.x = BB3(1);
        dres.y = BB3(2);
        dres.w = BB3(3) - BB3(1);
        dres.h = BB3(4) - BB3(2);
        o = calc_overlap(dres, 1, dres_det, 1);
        ind = 1;
        
        % compute angle
        centerI = [(BB1(1)+BB1(3))/2 (BB1(2)+BB1(4))/2];
        centerJ = [(BB3(1)+BB3(3))/2 (BB3(2)+BB3(4))/2];
        v = compute_velocity(tracker);
        v_new = [centerJ(1)-centerI(1), centerJ(2)-centerI(2)] / double(frame_id - tracker.frame_ids(i));
        if norm(v) && norm(v_new)
            angle = dot(v, v_new) / (norm(v) * norm(v_new));
        else
            angle = 1;
        end        
    end
    
    tracker.bbs{i} = BB3;
    tracker.points{i} = xFJ;
    tracker.flags(i) = flag;
    tracker.medFBs(i) = medFB;
    tracker.medNCCs(i) = medNCC;
    tracker.overlaps(i) = o;
    tracker.indexes(i) = ind;
    tracker.angles(i) = angle;
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

% compute pattern similarity
pattern = generate_pattern(dres_image.Igray{frame_id}, tracker.bb, tracker.patchsize);
nccs = distance(pattern, tracker.patterns, 1); % measure NCC to positive examples
tracker.nccs = nccs';

fprintf('LK association, target %d detection %.2f, medFBs ', ...
    tracker.target_id, dres_det.r);
for i = 1:tracker.num
    fprintf('%.2f ', tracker.medFBs(i))
end
fprintf('\n');

fprintf('LK association, target %d detection %.2f, nccs ', ...
    tracker.target_id, dres_det.r);
for i = 1:tracker.num
    fprintf('%.2f ', tracker.nccs(i))
end
fprintf('\n');

fprintf('LK association, target %d detection %.2f, angles ', ...
    tracker.target_id, dres_det.r);
for i = 1:tracker.num
    fprintf('%.2f ', tracker.angles(i))
end
fprintf('\n');


% Estimates motion from bounding box BB1 in frame I to bounding box BB2 in frame J
function [BB3, xFJ, flag, medFB, medNCC] = LK(BB1, BB2, I, J)

% initialize output variables
BB3 = []; % estimated bounding

% exit function if BB1 or BB2 is not defined
if isempty(BB1) || ~bb_isdef(BB1) || isempty(BB2) || ~bb_isdef(BB2)
    return;
end 

% estimate BB3
xFI  = bb_points(BB1,10,10,5); % generate 10x10 grid of points within BB1 with margin 5 px
xFII = bb_points(BB2,10,10,5);
% track all points by Lucas-Kanade tracker from frame I to frame J, 
% estimate Forward-Backward error, and NCC for each point
xFJ    = lk(2, I, J, xFI, xFII, 1);

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