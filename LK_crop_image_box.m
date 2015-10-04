% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
%
% crop canonical image and bounding box
function [I_crop, BB_crop, bb_crop, s] = LK_crop_image_box(I, BB, tracker)

s = [tracker.std_box(1)/bb_width(BB), tracker.std_box(2)/bb_height(BB)];
bb_scale = round([BB(1)*s(1); BB(2)*s(2); BB(3)*s(1); BB(4)*s(2)]);
bb_scale(3) = bb_scale(1) + tracker.std_box(1) - 1;
bb_scale(4) = bb_scale(2) + tracker.std_box(2) - 1;    
imsize = round([size(I,1)*s(2), size(I,2)*s(1)]);
I_scale = imResample(I, imsize, 'bilinear');
bb_crop = bb_rescale_relative(bb_scale, tracker.enlarge_box);
I_crop = im_crop(I_scale, bb_crop);
BB_crop = bb_shift_absolute(bb_scale, [-bb_crop(1) -bb_crop(2)]);