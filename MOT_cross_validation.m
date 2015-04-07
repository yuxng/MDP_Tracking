% cross_validation
function MOT_cross_validation

mot2d_train_seqs = {'TUD-Stadtmitte', 'TUD-Campus', 'PETS09-S2L1', ...
   'ETH-Bahnhof', 'ETH-Sunnyday', 'ETH-Pedcross2', 'ADL-Rundle-6', ...
   'ADL-Rundle-8', 'KITTI-13', 'KITTI-17', 'Venice-2'};

seq_idx_train = {{1}, {4},    {7},     {9}};
seq_idx_test  = {{2}, {5, 6}, {8, 11}, {10}};
seq_set_test = 'train';
N = numel(seq_idx_train);

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
        fprintf('Testing on sequence: %s\n', mot2d_train_seqs{idx_test{j}});
        MDP_test(idx_test{j}, seq_set_test, tracker);
    end    
end

% evaluation for all test sequences
opt = globals();
benchmark_dir = fullfile(opt.mot, opt.mot2d, seq_set_test, filesep);
seqs = {'TUD-Campus', 'ETH-Sunnyday', 'ETH-Pedcross2', ...
   'ADL-Rundle-8', 'Venice-2', 'KITTI-17'};
evaluateTracking(seqs, opt.results, benchmark_dir);