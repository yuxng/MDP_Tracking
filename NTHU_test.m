% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
%
% test on the NTHU benchmark
function NTHU_test

% set is_train to 0 if testing trained trackers only
is_train = 1;
opt = globals();

idx_train = 1:numel(opt.nthu_train_seqs);
idx_test  = 1:numel(opt.nthu_test_seqs);

% training
if is_train
    % number of training sequences
    num = numel(idx_train);
    tracker = [];

    % online training
    for j = 1:num
        tic;
        fprintf('Online training on sequence: %s\n', opt.nthu_train_seqs{idx_train(j)});
        tracker = MDP_train_NTHU(idx_train(j), tracker);
        if isempty(tracker) == 0
            fprintf('%d training examples after online training\n', size(tracker.f_occluded, 1));
        end
        toc;
    end
else
    % load tracker from file
    filename = sprintf('%s/nthu_train_%s_tracker.mat', opt.results_nthu, opt.nthu_train_seqs{idx_train(end)});
    object = load(filename);
    tracker = object.tracker;
    fprintf('load tracker from file %s\n', filename);
end

% testing
num = numel(idx_test);
for j = 1:num
    fprintf('Testing on test sequence: %s\n', opt.nthu_test_seqs{idx_test(j)});
    MDP_test_NTHU(idx_test(j), 'test', tracker);
end

% test training set
num = numel(idx_train);
for j = 1:num
    fprintf('Testing on train sequence: %s\n', opt.nthu_train_seqs{idx_train(j)});
    MDP_test_NTHU(idx_train(j), 'train', tracker);
end