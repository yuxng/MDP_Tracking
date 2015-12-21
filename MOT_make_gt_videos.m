% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
function MOT_make_gt_videos

close all;
hf = figure(1);
is_save = 1;

opt = globals();

seq_idx = 1;
seq_name = opt.mot2d_train_seqs{seq_idx};
seq_num = opt.mot2d_train_nums(seq_idx);
seq_set = 'train';

% build the dres structure for images
filename = sprintf('%s/%s_dres_image.mat', opt.results, seq_name);
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

if is_save
    file_video = sprintf('GT/%s_det.avi', seq_name);
    aviobj = VideoWriter(file_video);
    aviobj.FrameRate = 9;
    open(aviobj);
    fprintf('save video to %s\n', file_video);
end

for fr = 1:seq_num
    show_dres_gt(fr, dres_image.I{fr}, dres_det, dres_gt);
    % imshow(dres_image.I{fr});
    if is_save
        writeVideo(aviobj, getframe(hf));
    else
        pause;
    end
end

if is_save
    close(aviobj);
end

function show_dres_gt(frame_id, I, dres, dres_gt)

imshow(I);
hold on;

if isempty(dres) == 1
    index = [];
else
    index = find(dres.fr == frame_id);
    index_gt = find(dres_gt.fr == frame_id);
end

for i = 1:numel(index)
    ind = index(i);
    
    x = dres.x(ind);
    y = dres.y(ind);
    w = dres.w(ind);
    h = dres.h(ind);
    r = dres.r(ind);
    
    ov = calc_overlap(dres, ind, dres_gt, index_gt);
    if max(ov) > 0.5
        c = 'g';
    else
        c = 'r';
    end
    str = sprintf('%.2f', r);
    s = '-';
   
    rectangle('Position', [x y w h], 'EdgeColor', c, 'LineWidth', 4, 'LineStyle', s);
    % text(x, y-size(I,1)*0.01, str, 'BackgroundColor', [.7 .9 .7], 'FontSize', 14);    
end
hold off;