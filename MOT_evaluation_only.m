% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
function MOT_evaluation_only

opt = globals();
benchmark_dir = fullfile(opt.mot, opt.mot2d, 'train', filesep);
seqs = {'TUD-Campus', 'ETH-Sunnyday', 'ETH-Pedcross2', ...
   'ADL-Rundle-8', 'Venice-2', 'KITTI-17'};
opt.tracked = 5;

for i = 1:numel(seqs)
    seq_name = seqs{i};
    
    % load tracking results
    filename = sprintf('%s/%s_results.mat', opt.results, seq_name);
    object = load(filename, 'dres_track');
    dres_track = object.dres_track;
    
    % write tracking results
    filename = sprintf('%s/%s.txt', opt.results, seq_name);
    fprintf('write results: %s\n', filename);
    write_tracking_results(filename, dres_track, opt.tracked);    
end

evaluateTracking(seqs, opt.results, benchmark_dir);