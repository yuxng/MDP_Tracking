% extract features for tracked state
function [tracker, f] = MDP_feature_tracked(frame_id, dres_image, dres_det, tracker)

% LK tracking
tracker = LK_tracking(frame_id, dres_image, dres_det, tracker);
% extract features
f = zeros(tracker.fnum_tracked, 1);
% extract minimal FB error
[~, index] = min(tracker.medFBs);
f(1) = exp(-tracker.medFBs(index) / tracker.fb_factor);
f(2) = tracker.medNCCs(index);
f(3) = tracker.overlaps(index);
f(4) = tracker.nccs(index);
f(5) = tracker.angles(index);
f(6) = -1;