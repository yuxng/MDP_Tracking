% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
%
% read MOT file
function dres = read_results_nthu2dres(filename)

fid = fopen(filename, 'r');
% <frame>, <id>, <type>, <bb_left>, <bb_top>, <bb_right>, <bb_bottom>, <conf>
C = textscan(fid, '%d %d %s %f %f %f %f %f');
fclose(fid);

% build the dres structure for detections
dres.fr = C{1};
dres.id = C{2};
dres.type = C{3};
dres.x = C{4};
dres.y = C{5};
dres.w = C{6} - C{4} + 1;
dres.h = C{7} - C{5} + 1;
dres.r = C{8};