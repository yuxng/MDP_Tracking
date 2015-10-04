% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
%
% extract features for active state
function f = MDP_feature_active(tracker, dres)

num = numel(dres.fr);
f = zeros(num, tracker.fnum_active);
f(:,1) = dres.x / tracker.image_width;
f(:,2) = dres.y / tracker.image_height;
f(:,3) = dres.w / tracker.max_width;
f(:,4) = dres.h / tracker.max_height;
f(:,5) = dres.r / tracker.max_score;
f(:,6) = 1;