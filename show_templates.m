% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
function show_templates(tracker, dres_image)

pad = 10;
num = tracker.num;
frame_ids = tracker.frame_ids;
[frame_ids, index] = sort(frame_ids);
x1 = tracker.x1(index);
y1 = tracker.y1(index);
x2 = tracker.x2(index);
y2 = tracker.y2(index);
w = x2 - x1 + 1;
h = y2 - y1 + 1;
wmax = ceil(max(w)) + 2*pad;
hmax = ceil(max(h)) + 2*pad;

im = [];
for i = 1:num
    I = dres_image.I{frame_ids(i)};
    rect = [x1(i) y1(i) x2(i)-x1(i) y2(i)-y1(i)];
    T = imcrop(I, rect);
    if tracker.anchor == index(i)
        T = padarray(T, [pad pad 0], 128);
    else
        T = padarray(T, [pad pad 0], 255);
    end
    
    T1 = uint8(zeros([hmax, wmax, 3]));
    T1(1:size(T,1), 1:size(T,2), :) = T;
    if isempty(im)
        im = T1;
    else
        im = [im, T1]; 
    end
end
imshow(im);
title('Templates');