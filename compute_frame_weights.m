% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
%
% compute weights for frame features
function w = compute_frame_weights(tracker)

num = tracker.num;
w = zeros(num, 1);

frame_ids = double(tracker.frame_ids);
fr_max = max(frame_ids);

for i = 1:num
    w(i) = tracker.frame_weight ^ (fr_max - frame_ids(i));
end