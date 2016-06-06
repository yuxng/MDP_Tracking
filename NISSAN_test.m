% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
%
% cross_validation on the KITTI benchmark
function NISSAN_test

opt = globals();
idx_test  = {1};

% load the kitti tracker for testing
filename = sprintf('%s/kitti_training_%s_tracker.mat', opt.results_kitti, opt.kitti_train_seqs{21});
object = load(filename);
tracker = object.tracker;
fprintf('load tracker from file %s\n', filename);

% testing
% number of testing sequences
num = numel(idx_test);
for j = 1:num
    fprintf('Testing on sequence: %s\n', opt.kitti_test_seqs{idx_test{j}});
    MDP_test_NISSAN(idx_test{j}, 'test', 'Center', tracker);
    MDP_test_NISSAN(idx_test{j}, 'test', 'Left', tracker);
    MDP_test_NISSAN(idx_test{j}, 'test', 'Right', tracker);
end