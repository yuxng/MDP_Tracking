% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
function show_groundtruth

opt = globals();
seq_idx = 3;
seq_name = opt.mot2d_train_seqs{seq_idx};
seq_num = opt.mot2d_train_nums(seq_idx);
seq_set = 'train';

% build the dres structure for images
filename = sprintf('results/%s_dres_image.mat', seq_name);
if exist(filename, 'file') ~= 0
    object = load(filename);
    dres_image = object.dres_image;
    fprintf('load images from file %s done\n', filename);
else
    dres_image = read_dres_image(opt, seq_set, seq_name, seq_num);
    fprintf('read images done\n');
    save(filename, 'dres_image', '-v7.3');
end

% read detections
filename = fullfile(opt.mot, opt.mot2d, seq_set, seq_name, 'det', 'det.txt');
dres_det = read_mot2dres(filename);

% read ground truth
filename = fullfile(opt.mot, opt.mot2d, seq_set, seq_name, 'gt', 'gt.txt');
dres_gt = read_mot2dres(filename);
dres_gt = fix_groundtruth(seq_name, dres_gt);


figure(1);
for fr = 1:seq_num
    fprintf('frame %d\n', fr);
    
    % show ground truth
    subplot(1, 2, 1);
    show_dres(fr, dres_image.I{fr}, 'GT', dres_gt);

    % show detections
    subplot(1, 2, 2);
    show_dres(fr, dres_image.I{fr}, 'Detections', dres_det);
    
    pause;
end