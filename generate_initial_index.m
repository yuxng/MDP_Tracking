% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
%
% find detections for initialization
function [dres_det, index_det] = generate_initial_index(trackers, dres_det)

if isempty(dres_det) == 1
    index_det = [];
    return;
end

% collect dres from trackers
dres_track = [];
for i = 1:numel(trackers)
    tracker = trackers{i};
    dres = sub(tracker.dres, numel(tracker.dres.fr));
    
    if tracker.state == 2
        if isempty(dres_track)
            dres_track = dres;
        else
            dres_track = concatenate_dres(dres_track, dres);
        end
    end
end

% nms
% bbox = [dres_det.x dres_det.y dres_det.x+dres_det.w dres_det.y+dres_det.h dres_det.r];
% index_nms = nms(bbox, 0.5);
% dres_det = sub(dres_det, index_nms);

% compute overlaps
num_det = numel(dres_det.fr);
if isempty(dres_track)
    num_track = 0;
else
    num_track = numel(dres_track.fr);
end
if num_track
    o1 = zeros(num_det, 1);
    o2 = zeros(num_det, 1);
    for i = 1:num_det
        [o, oo] = calc_overlap(dres_det, i, dres_track, 1:num_track);
        o1(i) = max(o);
        o2(i) = sum(oo);
    end
    index_det = find(o1 < 0.5 & o2 < 0.5);
else
    index_det = 1:num_det;
end