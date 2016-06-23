% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
%
% cross_validation on the KITTI benchmark
function KITTI_test

% set is_train to 0 if testing trained trackers only
is_train = 1;
is_kitti = 1;
opt = globals();

seq_idx_train = {{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21}};
seq_idx_test  = {{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29}};

seq_set_test = 'testing';
N = numel(seq_idx_train);

% for each training-testing pair
for i = 1:N
    % training
    idx_train = seq_idx_train{i};
    
    if is_train
        % number of training sequences
        num = numel(idx_train);
        tracker = [];
        
        % online training
        for j = 1:num
            fprintf('Online training on sequence: %s\n', opt.kitti_train_seqs{idx_train{j}});
            tracker = MDP_train(idx_train{j}, tracker, is_kitti);
        end
        fprintf('%d training examples after online training\n', size(tracker.f_occluded, 1));
        
    else
        % load tracker from file
        filename = sprintf('%s/kitti_training_%s_tracker.mat', opt.results_kitti, opt.kitti_train_seqs{idx_train{end}});
        object = load(filename);
        tracker = object.tracker;
        fprintf('load tracker from file %s\n', filename);
    end
    
    % testing
    idx_test = seq_idx_test{i};
    % number of testing sequences
    num = numel(idx_test);
    for j = 1:num
        fprintf('Testing on sequence: %s\n', opt.kitti_test_seqs{idx_test{j}});
        MDP_test(idx_test{j}, seq_set_test, tracker, is_kitti);
    end
end