% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
%
% find detections for association
function [dres_det, index_det, ctrack] = generate_association_index(tracker, frame_id, dres_det)

num_det = numel(dres_det.fr);
cdets = [dres_det.x + dres_det.w/2, dres_det.y + dres_det.h/2];

ctrack = apply_motion_prediction(frame_id, tracker);

% compute distances and aspect ratios
distances = zeros(num_det, 1);
ratios = zeros(num_det, 1);
ratios_w = zeros(num_det, 1);
for i = 1:num_det
    distances(i) = norm(cdets(i,:) - ctrack) / tracker.dres.w(end);

    ratio = tracker.dres.h(end) / dres_det.h(i);
    ratios(i) = min(ratio, 1/ratio);
    
    ratio_w = tracker.dres.w(end) / dres_det.w(i);
    ratios_w(i) = min(ratio_w, 1/ratio_w);    
end

if isfield(tracker.dres, 'type')
    cls = tracker.dres.type{end};
    cls_index = strcmp(cls, dres_det.type);
    index_det = find(distances < tracker.threshold_dis & ratios > tracker.threshold_ratio & ...
        ratios_w > tracker.threshold_ratio & cls_index == 1);
else
    index_det = find(distances < tracker.threshold_dis & ratios > tracker.threshold_ratio);
end
dres_det.ratios = ratios;
dres_det.distances = distances;