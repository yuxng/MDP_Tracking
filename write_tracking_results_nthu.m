% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
function write_tracking_results_nthu(filename, dres, threshold)

% compute target lengths
num = max(dres.id);
len = zeros(num, 1);
for i = 1:num
    len(i) = numel(find(dres.id == i & dres.state == 2));
end

fid = fopen(filename, 'w');

N = numel(dres.x);
for i = 1:N
    % <frame>, <id>, <type>, <bb_left>, <bb_top>, <bb_right>, <bb_bottom>, <conf>
    if len(dres.id(i)) > threshold && dres.state(i) == 2
        fprintf(fid, '%d %d %s %f %f %f %f %f\n', ...
            dres.fr(i), dres.id(i), dres.type{i}, ...
            dres.x(i), dres.y(i), dres.x(i)+dres.w(i), dres.y(i)+dres.h(i), ...
            dres.r(i));
    end
end

fclose(fid);