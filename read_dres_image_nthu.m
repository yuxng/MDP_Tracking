% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
%
% build the dres structure for images in NTHU
function dres_image = read_dres_image_nthu(opt, seq_set, seq_name, seq_num)

dres_image.x = zeros(seq_num, 1);
dres_image.y = zeros(seq_num, 1);
dres_image.w = zeros(seq_num, 1);
dres_image.h = zeros(seq_num, 1);
dres_image.I = cell(seq_num, 1);
dres_image.Igray = cell(seq_num, 1);

for i = 1:seq_num
    filename = fullfile(opt.nthu, seq_set, 'images', seq_name, sprintf('%06d.jpg', i));
    disp(filename);
    I = imread(filename);

    dres_image.x(i) = 1;
    dres_image.y(i) = 1;
    dres_image.w(i) = size(I, 2);
    dres_image.h(i) = size(I, 1);
    dres_image.I{i} = I;
    dres_image.Igray{i} = rgb2gray(I);
end