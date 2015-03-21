function opt = globals()

opt.root = pwd;

% path for MOT benchmark
mot_paths = {'/home/yuxiang/Projects/Multitarget_Tracking/MOTbenchmark', ...
    '/scail/scratch/u/yuxiang/MOTbenchmark'};
for i = 1:numel(mot_paths)
    if exist(mot_paths{i}, 'dir')
        opt.mot = mot_paths{i};
        break;
    end
end

opt.mot2d = '2DMOT2015';
opt.results = 'results';

opt.mot2d_train_seqs = {'TUD-Stadtmitte', 'TUD-Campus', 'PETS09-S2L1', ...
    'ETH-Bahnhof', 'ETH-Sunnyday', 'ETH-Pedcross2', 'ADL-Rundle-6', ...
    'ADL-Rundle-8', 'KITTI-13', 'KITTI-17', 'Venice-2'};
opt.mot2d_train_nums = [179, 71, 795, 1000, 354, 840, 525, 654, 340, 145, 600];

opt.mot2d_test_seqs = {'TUD-Crossing', 'PETS09-S2L2', 'ETH-Jelmoli', ...
    'ETH-Linthescher', 'ETH-Crossing', 'AVG-TownCentre', 'ADL-Rundle-1', ...
    'ADL-Rundle-3', 'KITTI-16', 'KITTI-19', 'Venice-1'};
opt.mot2d_test_nums = [201, 436, 440, 1194, 219, 450, 500, 625, 209, 1059, 450];

addpath(fullfile(opt.mot, 'devkit', 'utils'));
addpath([opt.root '/3rd_party/libsvm-3.20/matlab']);

if exist(opt.results, 'dir') == 0
    mkdir(opt.results);
end

% tracking parameters
opt.num = 10;                 % number of templates in tracker
opt.fb_factor = 30;           % normalization factor for forward-backward error in optical flow
opt.threshold_ratio = 0.6;    % aspect ratio threshold in target association
opt.threshold_dis = 5;        % distance threshold in target association, multiple of the width of target
opt.rescale_box = [1 1];    % [width height], rescale the bounding box before computing flow
opt.rescale_img = 0.25;        % rescale the image before computing flow
opt.enlarge_box = 5;          % enlarge the box before computing flow
opt.level_track = 3;          % LK level in tracking
opt.level_lost =  1;          % LK level in association
opt.max_ratio = 0.8;          % max allowed aspect ratio change in LK
opt.min_vnorm = 0.2;          % min allowed velocity norm in LK
opt.overlap_box = 0.7;        % overlap with detection in LK
opt.patchsize = [24 12];      % patch size for target appearance
opt.weight_tracking = 3;      % weight for tracking box in tracked state
opt.weight_association = 1;   % weight for tracking box in lost state

% parameters for generating training data
opt.overlap_occ = 0.7;
opt.overlap_pos = 0.5;
opt.overlap_neg = 0.2;
opt.overlap_sup = 0.95;  % suppress target used in testing only
opt.max_neg = 100;

% training parameters
opt.max_iter = 100000;    % max iterations in total
opt.max_count = 20;      % max iterations per sequence

% parameters to transite to inactive
opt.max_occlusion = 50;
opt.exit_threshold = 0.2;
opt.tracked = 4;