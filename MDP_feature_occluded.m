% extract features for occluded state
function feature = MDP_feature_occluded(frame_id, dres_image, dres, tracker)

f = zeros(1, tracker.fnum_occluded);
w = compute_frame_weights(tracker);
num = tracker.num;
frame_ids = tracker.frame_ids;
[~, index] = sort(frame_ids);    

m = numel(dres.fr);
feature = zeros(m, tracker.fnum_occluded);
for i = 1:m
    dres_one = sub(dres, i);
    tracker = LK_associate(frame_id, dres_image, dres_one, tracker);
    % extract features
    f(1:num) = w(index) .* exp(-tracker.medFBs(index) / tracker.fb_factor);
    f(num+1:2*num) = w(index) .* tracker.medNCCs(index);
    f(2*num+1:3*num) = w(index) .* tracker.nccs(index);
    f(3*num+1:4*num) = w(index) .* tracker.angles(index);
    f(4*num+1) = 1;
    feature(i,:) = f;
end