% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
%
% generate training data from KITTI
function [dres_train, dres_det, labels] = generate_training_data_kitti(seq_idx, dres_image, opt)

is_show = 0;

seq_name = opt.kitti_train_seqs{seq_idx};
seq_set = 'training';

% read detections
filename = fullfile(opt.kitti, seq_set, 'det_02', [seq_name '.txt']);
dres_det = read_kitti2dres(filename);

% read ground truth
filename = fullfile(opt.kitti, seq_set, 'label_02', [seq_name '.txt']);
dres_gt = read_kitti2dres(filename);
y_gt = dres_gt.y + dres_gt.h;

% collect true positives and false alarms from detections
num = numel(dres_det.fr);
labels = zeros(num, 1);
overlaps = zeros(num, 1);
for i = 1:num
    fr = dres_det.fr(i);
    index = find(dres_gt.fr == fr);
    if isempty(index) == 0
        overlap = calc_overlap(dres_det, i, dres_gt, index);
        o = max(overlap);
        if o < opt.overlap_neg
            labels(i) = -1;
        elseif o > opt.overlap_pos
            labels(i) = 1;
        else
            labels(i) = 0;
        end
        overlaps(i) = o;
    else
        overlaps(i) = 0;
        labels(i) = -1;
    end
end

% build the training sequences
ids = unique(dres_gt.id);
dres_train = [];
count = 0;
for i = 1:numel(ids)
    index = find(dres_gt.id == ids(i));
    dres = sub(dres_gt, index);
    
    % check if the target is occluded or not
    num = numel(dres.fr);
    dres.occluded = zeros(num, 1);
    dres.covered = zeros(num, 1);
    dres.overlap = zeros(num, 1);
    dres.r = zeros(num, 1);
    dres.area_inside = zeros(num, 1);
    y = dres.y + dres.h;
    for j = 1:num
        fr = dres.fr(j);
        index = find(dres_gt.fr == fr & dres_gt.id ~= ids(i));
        
        if isempty(index) == 0
            [~, ov] = calc_overlap(dres, j, dres_gt, index);
            ov(y(j) > y_gt(index)) = 0;
            dres.covered(j) = max(ov);
        end
        
        if dres.covered(j) > opt.overlap_occ
            dres.occluded(j) = 1;
        end
        
        % overlap with detections
        index = find(dres_det.fr == fr);
        if isempty(index) == 0
            overlap = calc_overlap(dres, j, dres_det, index);
            [o, ind] = max(overlap);
            dres.overlap(j) = o;
            dres.r(j) = dres_det.r(index(ind));
            
            % area inside image
            [~, overlap] = calc_overlap(dres_det, index(ind), dres_image, fr);
            dres.area_inside(j) = overlap;
        end
    end
    
    % start with bounding overlap > opt.overlap_pos and non-occluded box
    index = find(dres.overlap > opt.overlap_pos & dres.covered == 0 & dres.area_inside > opt.exit_threshold);
    
    if isempty(index) == 0
        index_start = index(1);
        count = count + 1;
        dres_train{count} = sub(dres, index_start:num);
        
        % show gt
         if is_show
            disp(count);
            for j = 1:numel(dres_train{count}.fr)
                fr = dres_train{count}.fr(j);
                I = dres_image.I{fr};
                figure(1);
                show_dres(fr, I, 'GT', dres_train{count});
                pause;
            end
         end 
    end
end

fprintf('%s: %d positive sequences\n', seq_name, numel(dres_train));