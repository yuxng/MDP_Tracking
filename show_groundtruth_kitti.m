% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
function show_groundtruth_kitti(seq_idx)

opt = globals();
seq_name = opt.kitti_train_seqs{seq_idx};
seq_num = opt.kitti_train_nums(seq_idx);
seq_set = 'training';

% build the dres structure for images
filename = sprintf('%s/kitti_%s_%s_dres_image.mat', opt.results_kitti, seq_set, seq_name);
if exist(filename, 'file') ~= 0
    object = load(filename);
    dres_image = object.dres_image;
    fprintf('load images from file %s done\n', filename);
else
    dres_image = read_dres_image_kitti(opt, seq_set, seq_name, seq_num);
    fprintf('read images done\n');
    save(filename, 'dres_image', '-v7.3');
end

% read detections
filename = fullfile(opt.kitti, seq_set, 'det_02', [seq_name '.txt']);
dres_det = read_kitti2dres(filename);

% read ground truth
filename = fullfile(opt.kitti, seq_set, 'label_02', [seq_name '.txt']);
dres_gt = read_kitti2dres(filename);

figure(1);
for fr = 1:seq_num
    fprintf('frame %d\n', fr);
    
    % show ground truth
    subplot(1, 2, 1);
    show_dres(fr, dres_image.I{fr}, 'GT', dres_gt);

    % show detections
    subplot(1, 2, 2);
    show_dres(fr, dres_image.I{fr}, 'Detections', dres_det);
    
    pause(0.1);
end