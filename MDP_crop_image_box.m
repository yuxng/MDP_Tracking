% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
%
% add cropped image and box to dres
function dres = MDP_crop_image_box(dres, I, tracker)

num = numel(dres.fr);
dres.I_crop = cell(num, 1);
dres.BB_crop = cell(num, 1);
dres.bb_crop = cell(num, 1);
dres.scale = cell(num, 1);

for i = 1:num
    BB = [dres.x(i); dres.y(i); dres.x(i) + dres.w(i); dres.y(i) + dres.h(i)];
    [I_crop, BB_crop, bb_crop, s] = LK_crop_image_box(I, BB, tracker);
    
    dres.I_crop{i} = I_crop;
    dres.BB_crop{i} = BB_crop;
    dres.bb_crop{i} = bb_crop;
    dres.scale{i} = s;
end