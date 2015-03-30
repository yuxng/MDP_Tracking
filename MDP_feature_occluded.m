% extract features for occluded state
function [feature, flag] = MDP_feature_occluded(frame_id, dres_image, dres, tracker)

f = zeros(1, tracker.fnum_occluded);
m = numel(dres.fr);
feature = zeros(m, tracker.fnum_occluded);
flag = zeros(m, 1);
for i = 1:m
    dres_one = sub(dres, i);
    tracker = LK_associate(frame_id, dres_image, dres_one, tracker);
    
    % design features
    index = find(tracker.flags ~= 2);
    if isempty(index) == 0
        f(1) = mean(exp(-tracker.medFBs(index) / tracker.fb_factor));
        f(2) = mean(tracker.medNCCs(index));
        f(3) = mean(tracker.overlaps(index));
        f(4) = mean(tracker.nccs(index));
        f(5) = mean(tracker.ratios(index));
        f(6) = tracker.scores(1) / tracker.max_score;
        f(7) = dres_one.ratios(1);
        f(8) = exp(-dres_one.distances(1));
    else
        f = zeros(1, tracker.fnum_occluded);
    end
    
    % f(5) = mean(tracker.angles);
    feature(i,:) = f;
    
    if isempty(find(tracker.flags ~= 2, 1)) == 1
        flag(i) = 0;
    else
        flag(i) = 1;
    end
end