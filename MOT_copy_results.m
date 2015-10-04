% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
function MOT_copy_results

% test sequences
seqs = {'TUD-Crossing', 'PETS09-S2L2', 'ETH-Jelmoli', ...
    'ETH-Linthescher', 'ETH-Crossing', 'AVG-TownCentre', 'ADL-Rundle-1', ...
    'ADL-Rundle-3', 'KITTI-16', 'KITTI-19', 'Venice-1'};

for i = 1:numel(seqs)
    % txt file
    file_src = sprintf('results/%s.txt', seqs{i});
    disp(file_src);
    file_dst = sprintf('results_MOT/%s.txt', seqs{i});
    copyfile(file_src, file_dst);
    
    % mat file
    file_src = sprintf('results/%s_results.mat', seqs{i});
    disp(file_src);
    file_dst = sprintf('results_MOT/%s_results.mat', seqs{i});
    copyfile(file_src, file_dst);
    
    % tracker
    file_src = sprintf('results/%s_results.mat', seqs{i});
    disp(file_src);
    file_dst = sprintf('results_MOT/%s_results.mat', seqs{i});
    copyfile(file_src, file_dst);    
end

fprintf('\n');
% copy tracker, training sequences
seqs = {'TUD-Stadtmitte', 'TUD-Campus', 'PETS09-S2L1', ...
   'ETH-Bahnhof', 'ETH-Sunnyday', 'ETH-Pedcross2', 'ADL-Rundle-6', ...
   'ADL-Rundle-8', 'KITTI-13', 'KITTI-17', 'Venice-2'};

for i = 1:numel(seqs)    
    % tracker
    file_src = sprintf('results/%s_tracker_det.mat', seqs{i});
    disp(file_src);
    file_dst = sprintf('results_MOT/%s_tracker_det.mat', seqs{i});
    copyfile(file_src, file_dst);    
end