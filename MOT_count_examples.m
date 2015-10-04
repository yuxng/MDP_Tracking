% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
%
% cross_validation
function MOT_count_examples

mot2d_train_seqs = {'TUD-Stadtmitte', 'TUD-Campus', 'PETS09-S2L1', ...
   'ETH-Bahnhof', 'ETH-Sunnyday', 'ETH-Pedcross2', 'ADL-Rundle-6', ...
   'ADL-Rundle-8', 'KITTI-13', 'KITTI-17', 'Venice-2'};

seq_idx_train = {{1, 2}, {3}, {4, 5, 6}, {7, 8}, {9, 10}, {11}};

N = numel(seq_idx_train);
count_det = 0;
count_mdp = 0;
for i = 1:N
    % training
    idx_train = seq_idx_train{i};
    
    % load tracker from file
    filename = sprintf('results_MOT/%s_tracker.mat', mot2d_train_seqs{idx_train{end}});
    object = load(filename);
    tracker = object.tracker;
    fprintf('load tracker from file %s\n', filename);
    count_mdp = count_mdp + size(tracker.f_occluded, 1);
    
    % load tracker from file
    filename = sprintf('results_MOT/%s_tracker_det.mat', mot2d_train_seqs{idx_train{end}});
    object = load(filename);
    tracker = object.tracker;
    fprintf('load tracker from file %s\n', filename);
    count_det = count_det + size(tracker.f_occluded, 1);
end

fprintf('%d examples for online learning\n', count_mdp);
fprintf('%d examples for offline learning\n', count_det);