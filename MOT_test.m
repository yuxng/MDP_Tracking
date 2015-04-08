% cross_validation
function MOT_test

mot2d_train_seqs = {'TUD-Stadtmitte', 'TUD-Campus', 'PETS09-S2L1', ...
   'ETH-Bahnhof', 'ETH-Sunnyday', 'ETH-Pedcross2', 'ADL-Rundle-6', ...
   'ADL-Rundle-8', 'KITTI-13', 'KITTI-17', 'Venice-2'};

mot2d_test_seqs = {'TUD-Crossing', 'PETS09-S2L2', 'ETH-Jelmoli', ...
    'ETH-Linthescher', 'ETH-Crossing', 'AVG-TownCentre', 'ADL-Rundle-1', ...
    'ADL-Rundle-3', 'KITTI-16', 'KITTI-19', 'Venice-1'};

seq_idx_train = {{1, 2}, {3},    {4, 5, 6}, {7, 8}, {9, 10}, {11}};
seq_idx_test  = {{1},    {2, 6}, {3, 4, 5}, {7, 8}, {9, 10}, {11}};
seq_set_test = 'test';
N = numel(seq_idx_train);

test_time = 0;
for i = 1:N
    % training
    idx_train = seq_idx_train{i};
    % number of training sequences
    num = numel(idx_train);
    tracker = [];
    for j = 1:num
        fprintf('Training on sequence: %s\n', mot2d_train_seqs{idx_train{j}});
        tracker = MDP_train(idx_train{j}, tracker);
    end
    
    % testing
    idx_test = seq_idx_test{i};
    % number of testing sequences
    num = numel(idx_test);
    for j = 1:num
        fprintf('Testing on sequence: %s\n', mot2d_test_seqs{idx_test{j}});
        tic;
        MDP_test(idx_test{j}, seq_set_test, tracker);
        test_time = test_time + toc;
    end
end

fprintf('Total time for testing: %f\n', test_time);