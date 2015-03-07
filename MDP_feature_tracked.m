% extract features for tracked state
function [tracker, f] = MDP_feature_tracked(frame_id, dres_image, dres_det, tracker)

% LK tracking
tracker = LK_tracking(frame_id, dres_image, dres_det, tracker);
% extract features
f = zeros(tracker.fnum_tracked, 1);
w = compute_frame_weights(tracker);
num = tracker.num;
frame_ids = tracker.frame_ids;
[~, index] = sort(frame_ids);
f(1:num) = w(index) .* exp(-tracker.medFBs(index) / tracker.fb_factor);
f(num+1:2*num) = w(index) .* tracker.medNCCs(index);
f(2*num+1:3*num) = w(index) .* tracker.overlaps(index);
f(3*num+1:4*num) = w(index) .* tracker.angles(index);
f(4*num+1) = -1;