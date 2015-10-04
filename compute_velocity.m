% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
%
% compute velocity
function v = compute_velocity(tracker)

fr = double(unique(tracker.frame_ids));
num = numel(fr);

% only use the past 3 frames
if num > 3
    fr = fr(num-2:num);
    num = 3;
end

% compute centers
centers = zeros(num, 2);
for i = 1:num
    index = find(tracker.frame_ids == fr(i));
    for j = 1:numel(index)
        ind = index(j);
        c = [(tracker.x1(ind)+tracker.x2(ind))/2 (tracker.y1(ind)+tracker.y2(ind))/2];
        centers(i,:) = centers(i,:) + c;
    end
    if numel(index)
        centers(i,:) = centers(i,:) / numel(index);
    end
end

count = 0;
vx = 0;
vy = 0;
cx = centers(:,1);
cy = centers(:,2);
for j = 2:num
    vx = vx + (cx(j)-cx(j-1)) / (fr(j) - fr(j-1));
    vy = vy + (cy(j)-cy(j-1)) / (fr(j) - fr(j-1));
    count = count + 1;
end
if count
    vx = vx / count;
    vy = vy / count;
end
v = [vx, vy];