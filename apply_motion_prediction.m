% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
%
% apply motion models to predict the next locations of the targets
function prediction = apply_motion_prediction(fr_current, tracker)

% apply motion model and predict next location
dres = tracker.dres;
index = find(dres.state == 2);
dres = sub(dres, index);
cx = dres.x + dres.w/2;
cy = dres.y + dres.h/2;
fr = double(dres.fr);

% only use the past 10 frames
num = numel(fr);
K = 10;
if num > K
    cx = cx(num-K+1:num);
    cy = cy(num-K+1:num);
    fr = fr(num-K+1:num);
end

fr_current = double(fr_current);

% compute velocity
vx = 0;
vy = 0;
num = numel(cx);
count = 0;
for j = 2:num
    vx = vx + (cx(j)-cx(j-1)) / (fr(j) - fr(j-1));
    vy = vy + (cy(j)-cy(j-1)) / (fr(j) - fr(j-1));
    count = count + 1;
end
if count
    vx = vx / count;
    vy = vy / count;
end

if isempty(cx) == 1
    dres = tracker.dres;
    cx_new = dres.x(end) + dres.w(end)/2;
    cy_new = dres.y(end) + dres.h(end)/2;
else
    cx_new = cx(end) + vx * (fr_current + 1 - fr(end));
    cy_new = cy(end) + vy * (fr_current + 1 - fr(end));
end
prediction = [cx_new cy_new];