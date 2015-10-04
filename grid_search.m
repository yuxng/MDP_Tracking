% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
%
% find parameters by grid search
function opt = grid_search(seq_idx)

% basic parameters
opt = globals();

% 1. search for rescale box (very important for optical flow tracking)
fname = 'rescale_box';
values = {[1, 1], [0.8, 1], [0.6, 1], [0.6, 0.8]};
opt = search_parameter(seq_idx, opt, fname, values);

% 2. search for enlarge box
fname = 'enlarge_box';
values = {2, 3, 4, 5};
opt = search_parameter(seq_idx, opt, fname, values);

% 3. search for max ratio changed allowed in LK
fname = 'max_ratio';
values = {0.6, 0.7, 0.8, 0.9};
opt = search_parameter(seq_idx, opt, fname, values);

% 4. search for weight tracking
fname = 'weight_tracking';
values = {1, 3, 5, 7};
opt = search_parameter(seq_idx, opt, fname, values);

% 5. search for threshold ratio
fname = 'threshold_ratio';
values = {0.6, 0.7, 0.8, 0.9};
opt = search_parameter(seq_idx, opt, fname, values);

% 6. search for threshold dis
fname = 'threshold_dis';
values = {1, 3, 5, 7};
opt = search_parameter(seq_idx, opt, fname, values);

% save parameters
seq_name = opt.mot2d_train_seqs{seq_idx};
filename = sprintf('%s/%s_opt.mat', opt.results, seq_name);
fprintf('save parameters to %s\n', filename);
save(filename, 'opt');


% search a specific parameter
function opt = search_parameter(seq_idx, opt, fname, values)

num = numel(values);
mota = zeros(num, 1);
for i = 1:num
    fprintf('Test parameter %s: ', fname);
    disp(values{i});
    
    opt.(fname) = values{i};
    tracker = MDP_train(seq_idx, opt);
    metrics = MDP_test(seq_idx, 'train', tracker);
    mota(i) = metrics.mets2d.m(12);
    
    fprintf('Test parameter %s, mota %.2f, ', fname, mota(i));
    disp(values{i});    
end
[m, ind] = max(mota);
opt.(fname) = values{ind};
fprintf('Final parameter %s with max mota %f, ', fname, m);
disp(opt.(fname));