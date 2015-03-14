% extract features for occluded state
function feature = MDP_feature_occluded(frame_id, dres_image, dres, tracker)

f = zeros(1, tracker.fnum_occluded);
m = numel(dres.fr);
feature = zeros(m, tracker.fnum_occluded);
for i = 1:m
    dres_one = sub(dres, i);
    tracker = LK_associate(frame_id, dres_image, dres_one, tracker);
    % extract minimal left or right FB error
    [ml, indl] = min(tracker.medFBs_left);
    [mr, indr] = min(tracker.medFBs_right);
    if ml < mr
        index = indl;
        m = ml;
    else
        index = indr;
        m = mr;
    end
    
    % [~, index] = min(tracker.medFBs);
    
    f(1) = exp(-m / tracker.fb_factor);
    f(2) = tracker.medNCCs(index);
    f(3) = tracker.overlaps(index);
    f(4) = tracker.nccs(index);
    f(5) = tracker.angles(index);
    feature(i,:) = f;
end