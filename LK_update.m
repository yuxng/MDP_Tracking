% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
%
% update the LK tracker
function tracker = LK_update(frame_id, tracker, img, dres_det, is_change_anchor)

medFBs = tracker.medFBs;
if is_change_anchor == 0
% find the template with max FB error but not the anchor
    medFBs(tracker.anchor) = -inf;
    [~, index] = max(medFBs);
else
    [~, index] = max(medFBs);
    tracker.anchor = index;    
end

% update
tracker.frame_ids(index) = frame_id;
tracker.x1(index) = tracker.bb(1);
tracker.y1(index) = tracker.bb(2);
tracker.x2(index) = tracker.bb(3);
tracker.y2(index) = tracker.bb(4);
tracker.patterns(:,index) = generate_pattern(img, tracker.bb, tracker.patchsize);

% update images and boxes
BB = [tracker.x1(index); tracker.y1(index); tracker.x2(index); tracker.y2(index)];
[I_crop, BB_crop] = LK_crop_image_box(img, BB, tracker);
tracker.Is{index} = I_crop;
tracker.BBs{index} = BB_crop;

% compute overlap
dres.x = tracker.bb(1);
dres.y = tracker.bb(2);
dres.w = tracker.bb(3) - tracker.bb(1);
dres.h = tracker.bb(4) - tracker.bb(2);
num_det = numel(dres_det.fr);
if isempty(dres_det.fr) == 0
    o = calc_overlap(dres, 1, dres_det, 1:num_det);
    tracker.bb_overlaps(index) = max(o);
else
    tracker.bb_overlaps(index) = 0;
end