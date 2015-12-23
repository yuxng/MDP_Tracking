% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
function write_tracking_results_kitti(filename, dres, threshold)

% compute target lengths
num = max(dres.id);
len = zeros(num, 1);
for i = 1:num
    len(i) = numel(find(dres.id == i & dres.state == 2));
end

fid = fopen(filename, 'w');

N = numel(dres.x);
for i = 1:N
    % <frame>, <id>, <type>, <truncated>, <occluded>, <alpha>, 
    % <bb_left>, <bb_top>, <bb_right>, <bb_bottom>, <3D height>, <3D width>, <3D length>
    % <3D x>, <3D y>, <3D z>, <rotation y>, <conf>
    if len(dres.id(i)) > threshold && dres.state(i) == 2
        fprintf(fid, '%d %d %s %d %d %f %f %f %f %f %f %f %f %f %f %f %f\n', ...
            dres.fr(i)-1, dres.id(i)-1, dres.type{i}, -1, -1, -1, ...
            dres.x(i), dres.y(i), dres.x(i)+dres.w(i), dres.y(i)+dres.h(i), ...
            -1, -1, -1, -1, -1, -1, -1);
    end
end

fclose(fid);