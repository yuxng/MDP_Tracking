% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
function evaluate_cem

opt = globals();
seq_set = 'train';
seq_name = 'TUD-Campus';
results = '/home/yuxiang/Projects/Multitarget_Tracking/MOTbenchmark/devkit/res/data';

% evaluation
benchmark_dir = fullfile(opt.mot, opt.mot2d, seq_set, filesep);
evaluateTracking({seq_name}, results, benchmark_dir);