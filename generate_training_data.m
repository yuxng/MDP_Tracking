function [dres_train, dres_det, labels] = generate_training_data(seq_idx, width, height, opt)

% is_show = 0;

seq_name = opt.mot2d_train_seqs{seq_idx};
seq_set = 'train';

% read detections
filename = fullfile(opt.mot, opt.mot2d, seq_set, seq_name, 'det', 'det.txt');
dres_det = read_mot2dres(filename);

% read ground truth
filename = fullfile(opt.mot, opt.mot2d, seq_set, seq_name, 'gt', 'gt.txt');
dres_gt = read_mot2dres(filename);
dres_gt = fix_groundtruth(seq_name, dres_gt);
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

% compute start conf
scores = sort(dres_det.r(labels == 1));
start_conf = scores(round(0.05*num));


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
        end
    end
    
    % start with bounding overlap > opt.overlap_pos
    index = find(dres.overlap > opt.overlap_pos & dres.r > start_conf & dres.covered == 0);
    if isempty(index) == 0
        index_start = index(1);
        count = count + 1;
        dres_train{count} = sub(dres, index_start:num);
    end
    
    % show gt
%      if is_show
%         for j = 1:numel(dres_train{i}.fr)
%             fr = dres_train{i}.fr(j);
%             filename = fullfile(opt.mot, opt.mot2d, seq_set, seq_name, 'img1', sprintf('%06d.jpg', fr));
%             disp(filename);
%             I = imread(filename);
%             figure(1);
%             show_dres(fr, I, 'GT', dres_train{i});
%             pause;
%         end
%     end
end
fprintf('%s: %d positive sequences\n', seq_name, numel(dres_train));


% extract false alarms and append to training sequences
index = find(overlaps < opt.overlap_neg);
if numel(index) > opt.max_neg
    ind = randi(numel(index), [1, opt.max_neg]);
    index = sort(index(ind));
end
dres = sub(dres_det, index);
num = numel(dres.fr);
dres.occluded = zeros(num, 1);
dres.covered = zeros(num, 1);
dres.overlap = ones(num, 1);
for i = 1:num
    dres_one = sub(dres, i);
    % ignore detections near the borders
    if dres_one.x > width*0.05 && dres_one.x+dres_one.w < width*0.95 && ...
            dres_one.y > height*0.05 && dres_one.y+dres_one.h < height*0.95
        dres_train{end+1} = dres_one;
    end
end
fprintf('%s: %d negative sequences\n', seq_name, numel(dres_train) - count);