% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
%
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
        f(2) = mean(exp(-tracker.medFBs_left(index) / tracker.fb_factor));
        f(3) = mean(exp(-tracker.medFBs_right(index) / tracker.fb_factor));
        f(4) = mean(exp(-tracker.medFBs_up(index) / tracker.fb_factor));
        f(5) = mean(exp(-tracker.medFBs_down(index) / tracker.fb_factor));
        f(6) = mean(tracker.medNCCs(index));
        f(7) = mean(tracker.overlaps(index));
        f(8) = mean(tracker.nccs(index));
        f(9) = mean(tracker.ratios(index));
        f(10) = tracker.scores(1) / tracker.max_score;
        f(11) = dres_one.ratios(1);
        f(12) = exp(-dres_one.distances(1));
    else
        f = zeros(1, tracker.fnum_occluded);
    end
    
    feature(i,:) = f;
    
    if isempty(find(tracker.flags ~= 2, 1)) == 1
        flag(i) = 0;
    else
        flag(i) = 1;
    end
end