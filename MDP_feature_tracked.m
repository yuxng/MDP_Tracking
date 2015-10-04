% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
%
% extract features for tracked state
function [tracker, f] = MDP_feature_tracked(frame_id, dres_image, dres_det, tracker)

% LK tracking
tracker = LK_tracking(frame_id, dres_image, dres_det, tracker);

% extract features
f = zeros(1, tracker.fnum_tracked);

anchor = tracker.anchor;
f(1) = tracker.flags(anchor);
f(2) = mean(tracker.bb_overlaps);

if tracker.is_show
    fprintf('ftracked: ');
    for i = 1:numel(f)
        fprintf('%.2f ', f(i));
    end
    fprintf('\n');
    fprintf('anchor %d\n', tracker.anchor);
end