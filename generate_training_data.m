function dres_train = generate_training_data()

seq_idx = 1;
is_show = 1;

opt = globals();
seq_name = opt.mot2d_train_seqs{seq_idx};
seq_set = 'train';

% read ground truth
filename = fullfile(opt.mot, opt.mot2d, seq_set, seq_name, 'gt', 'gt.txt');
dres_gt = read_mot2dres(filename);
y_gt = dres_gt.y + dres_gt.h;

ids = unique(dres_gt.id);
dres_train = cell(numel(ids), 1);
for i = 1:numel(ids)
    index = find(dres_gt.id == ids(i));
    dres = sub(dres_gt, index);
    
    % check if the target is occluded or not
    num = numel(dres.fr);
    dres.occluded = zeros(num, 1);
    y = dres.y + dres.h;
    for j = 1:num
        fr = dres.fr(j);
        index = find(dres_gt.fr == fr & dres_gt.id ~= ids(i));
        [~, ov] = calc_overlap(dres, j, dres_gt, index);
        if isempty(find(ov' > opt.overlap_occ & y(j) < y_gt(index), 1)) == 0
            dres.occluded(j) = 1;
        end
    end
    dres_train{i} = dres;
    
    % show gt
%     if is_show
%         for j = 1:num
%             fr = dres.fr(j);
%             filename = fullfile(opt.mot, opt.mot2d, seq_set, seq_name, 'img1', sprintf('%06d.jpg', fr));
%             disp(filename);
%             I = imread(filename);
%             figure(1);
%             show_dres(fr, I, 'GT', dres);
%             pause;
%         end
%     end
end

% collect false alarms from detections
% read detections
filename = fullfile(opt.mot, opt.mot2d, seq_set, seq_name, 'det', 'det.txt');
dres_det = read_mot2dres(filename);
num = numel(dres_det.fr);
for i = 1:num
    fr = dres_det.fr(i);
    index = find(dres_gt.fr == fr);
    overlap = calc_overlap(dres_det, i, dres_gt, index);
    if max(overlap) < opt.overlap_neg
        dres = sub(dres_det, i);
        
        dres_train{end+1} = dres;

        if is_show
            filename = fullfile(opt.mot, opt.mot2d, seq_set, seq_name, 'img1', sprintf('%06d.jpg', fr));
            disp(filename);
            I = imread(filename);
            figure(1);
            show_dres(fr, I, 'False alarm', dres);
            pause;
        end        
    end
end