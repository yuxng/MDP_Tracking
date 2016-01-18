% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
function KITTI_make_gt_videos(seq_set, seq_idx)

close all;
hf = figure(1);
is_save = 1;

opt = globals();

% seq_set = 'training';
% seq_set = 'testing';

if strcmp(seq_set, 'training') == 1
    seq_name = opt.kitti_train_seqs{seq_idx};
    seq_num = opt.kitti_train_nums(seq_idx);
else
    seq_name = opt.kitti_test_seqs{seq_idx};
    seq_num = opt.kitti_test_nums(seq_idx);
end

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
% filename = fullfile(opt.kitti, seq_set, 'det_02', [seq_name '.txt']);
% dres_det = read_kitti2dres(filename);

% read ground truth
if strcmp(seq_set, 'training') == 1
    filename = fullfile(opt.kitti, seq_set, 'label_02', [seq_name '.txt']);
    dres_gt = read_kitti2dres(filename);
else
    dres_gt = [];
end

if is_save
    file_video = sprintf('GT/kitti_%s_%s.avi', seq_set, seq_name);
    aviobj = VideoWriter(file_video);
    aviobj.FrameRate = 9;
    open(aviobj);
    fprintf('save video to %s\n', file_video);
end

for fr = 1:seq_num
%     show_dres(fr, dres_image.I{fr}, '', dres_gt);
    imshow(dres_image.I{fr});
    if is_save
        writeVideo(aviobj, getframe(hf));
    else
        pause;
    end
end

if is_save
    close(aviobj);
end