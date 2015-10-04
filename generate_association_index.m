% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
%
% find detections for association
function [dres_det, index_det, ctrack] = generate_association_index(tracker, frame_id, dres_det)

ctrack = apply_motion_prediction(frame_id, tracker);

num_det = numel(dres_det.fr);
cdets = [dres_det.x + dres_det.w/2, dres_det.y + dres_det.h/2];

% compute distances and aspect ratios
distances = zeros(num_det, 1);
ratios = zeros(num_det, 1);
for i = 1:num_det
    distances(i) = norm(cdets(i,:) - ctrack) / tracker.dres.w(end);

    ratio = tracker.dres.h(end) / dres_det.h(i);
    ratios(i) = min(ratio, 1/ratio);
end

index_det = find(distances < tracker.threshold_dis & ratios > tracker.threshold_ratio);
dres_det.ratios = ratios;
dres_det.distances = distances;