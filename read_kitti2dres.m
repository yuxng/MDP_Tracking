% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
%
% read KITTI file
function dres = read_kitti2dres(filename)

threshold_det_car = 0.4;
threshold_det_people = 0.6;

% count columns
fid = fopen(filename, 'r');
l = strtrim(fgetl(fid));
ncols = numel(strfind(l,' '))+1;
fclose(fid);

% <frame>, <id>, <type>, <truncated>, <occluded>, <alpha>, 
% <bb_left>, <bb_top>, <bb_right>, <bb_bottom>, <3D height>, <3D width>, <3D length>
% <3D x>, <3D y>, <3D z>, <rotation y>, <conf>
fid = fopen(filename);
try
    if ncols == 17 % ground truth file
        C = textscan(fid, '%d %d %s %d %d %f %f %f %f %f %f %f %f %f %f %f %f');
    elseif ncols == 18
        C = textscan(fid, '%d %d %s %d %d %f %f %f %f %f %f %f %f %f %f %f %f %f');
    else
        error('This file is not in KITTI tracking format.');
    end
catch
    error('This file is not in KITTI tracking format.');
end
fclose(fid);

% build the dres structure for detections
dres.fr = C{1} + 1;  % 1-based frame
dres.id = C{2} + 1;  % 1-based id
dres.type = C{3};
dres.x = C{7};
dres.y = C{8};
dres.w = C{9}-C{7}+1;
dres.h = C{10}-C{8}+1;
if ncols == 17
    dres.r = zeros(size(C{1}));
    % substraction
    index = find(dres.id > 0);
    dres = sub(dres, index);    
else
    dres.r = C{18};
    % substraction
    index_car = find(dres.r > threshold_det_car & strcmp('Car', dres.type));
    index_other = find(dres.r > threshold_det_people & ~strcmp('Car', dres.type));
    index = [index_car; index_other];
    dres = sub(dres, index);
    % remove pedestrian with wrong aspect ratios
    ratios = dres.h ./ dres.w;
    ind = ~(strcmp('Pedestrian', dres.type) & ratios < 0.9);
    index = find(ind == 1);
    dres = sub(dres, index);    
end