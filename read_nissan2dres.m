% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
%
% read KITTI file
function dres = read_nissan2dres(seq_name, camera_set)

filename = sprintf('/capri5/Projects/3DVP_RCNN/fast-rcnn/output/nissan/nissan_%s/vgg16_fast_rcnn_multiscale_6k8k_kitti_iter_80000/detections.txt', seq_name);

threshold_det_car = 0.1;
threshold_det_people = 0.6;

% <frame str>, <type>, <bb_left>, <bb_top>, <bb_right>, <bb_bottom>, <subcls id>, <conf>
fid = fopen(filename, 'r');
C = textscan(fid, '%s %s %f %f %f %f %d %f');
fclose(fid);

% select detections
N = numel(C{1});
flag = zeros(N, 1);
idx = strfind(C{1}, camera_set);
flag(cellfun(@isempty, idx) == 0) = 1;

% substraction
type = C{2};
r = C{8};
index_car = find(r > threshold_det_car & strcmp('Car', type) & flag);
index_other = find(r > threshold_det_people & ~strcmp('Car', type) & flag);
index = [index_car; index_other];
num = numel(index);

% build the dres structure for detections
dres.fr = zeros(num, 1);
for i = 1:num
    str = C{1}(index(i));
    dres.fr(i) = str2num(str{1}(end-4:end));
end
dres.id = -1 * ones(num, 1);  % 1-based id
dres.type = C{2}(index);
dres.x = C{3}(index);
dres.y = C{4}(index);
dres.w = C{5}(index) - C{3}(index) + 1;
dres.h = C{6}(index) - C{4}(index) + 1;
dres.r = C{8}(index);