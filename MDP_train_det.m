% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
%
% offline training using object detections
function tracker = MDP_train_det(seq_idx, tracker)

is_show = 0;
is_save = 1;
is_text = 0;
is_pause = 0;

opt = globals();
opt.is_show = is_show;

seq_name = opt.mot2d_train_seqs{seq_idx};
seq_num = opt.mot2d_train_nums(seq_idx);
seq_set = 'train';

if is_show
    close all;
end

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

% generate training data
I = dres_image.Igray{1};
[dres_train, dres_det, labels] = generate_training_data(seq_idx, dres_image, opt);

% for debugging
% dres_train = {dres_train{6}};

% intialize tracker
if nargin < 2 || isempty(tracker) == 1
    fprintf('initialize tracker from scratch\n');
    tracker = MDP_initialize(I, dres_det, labels, opt);
else
    % continuous training
    fprintf('continuous training\n');    
    tracker.image_width = size(I,2);
    tracker.image_height = size(I,1);
    tracker.max_width = max(dres_det.w);
    tracker.max_height = max(dres_det.h);
    tracker.max_score = max(dres_det.r);
    
    factive = MDP_feature_active(tracker, dres_det);
    index = labels ~= 0;
    tracker.factive = [tracker.factive; factive(index,:)];
    tracker.lactive = [tracker.lactive; labels(index)];
    tracker.w_active = svmtrain(tracker.lactive, tracker.factive, '-c 1 -q');    
end

% for each training sequence
num_train = numel(dres_train);
for t = 1:num_train

    fprintf('tracking sequence %d\n', t);
    
    dres_gt = dres_train{t};
    
    % first frame
    fr = dres_gt.fr(1);
    id = dres_gt.id(1);
    
    % reset tracker
    tracker.prev_state = 1;
    tracker.state = 1;
    tracker.target_id = id;
    
    % start tracking
    while fr <= dres_gt.fr(end)
        if is_text
            fprintf('\nframe %d, state %d\n', fr, tracker.state);
        end
        
        % extract detection
        index = find(dres_det.fr == fr);
        dres = sub(dres_det, index);
        num_det = numel(dres.fr);        
        
        % show results
        if is_show
            figure(1);
            % show ground truth
            subplot(2, 3, 1);
            show_dres(fr, dres_image.I{fr}, 'GT', dres_gt);

            % show detections
            subplot(2, 3, 2);
            show_dres(fr, dres_image.I{fr}, 'Detections', dres_det);
        end
        
        if tracker.state == 0
            break;
            
        elseif tracker.state == 1
            
            % compute overlap
            overlap = calc_overlap(dres_gt, 1, dres, 1:num_det);
            [ov, ind] = max(overlap);
            if is_text
                fprintf('Start: first frame overlap %.2f\n', ov);
            end

            % initialize the LK tracker
            tracker = LK_initialize(tracker, fr, id, dres, ind, dres_image);
            tracker.state = 2;
            tracker.streak_occluded = 0;

            % build the dres structure
            dres_one = sub(dres, ind);
            tracker.dres = dres_one;
            tracker.dres.id = tracker.target_id;
            tracker.dres.state = tracker.state;
            
        % tracking by association
        else
            
            % find object detections for association
            dres = MDP_crop_image_box(dres, dres_image.Igray{fr}, tracker);
            [dres, index_det, ctrack] = generate_association_index(tracker, fr, dres);
            index_gt = find(dres_gt.fr == fr);
            if dres_gt.covered(index_gt) ~= 0
                index_det = [];
            end
            
            if is_show
                figure(1);
                subplot(2, 3, 3);
                show_dres(fr, dres_image.I{fr}, 'Potential Associations', sub(dres, index_det));
                hold on;
                plot(ctrack(1), ctrack(2), 'ro', 'LineWidth', 2);
                hold off;
            end            
            
            % compute features
            if isempty(index_det) == 0
                % extract features with LK association
                dres_associate = sub(dres, index_det);
                features = MDP_feature_occluded(fr, dres_image, dres_associate, tracker);
                
                % compute labels
                flag_update = 0;
                m = size(features, 1);
                labels = -1 * ones(m, 1);
                % compute overlap
                if isempty(index_gt) == 0
                    overlap = calc_overlap(dres_gt, index_gt, dres_associate, 1:numel(index_det));
                    [ov, ind] = max(overlap);
                    if ov > opt.overlap_pos
                        labels(ind) = 1;
                        flag_update = 1;
                    end
                end
                
                % update features
                tracker.f_occluded(end+1:end+m,:) = features;
                tracker.l_occluded(end+1:end+m) = labels;
                if is_text
                    fprintf('training examples in occluded state %d\n', size(tracker.f_occluded,1));
                end
                
                % update template
                if flag_update
                    dres_one = sub(dres_associate, ind);
                    tracker = LK_associate(fr, dres_image, dres_one, tracker);

                    tracker.prev_state = tracker.state;
                    tracker.state = 2;
                    % build the dres structure
                    dres_one = [];
                    dres_one.fr = fr;
                    dres_one.id = tracker.target_id;
                    dres_one.x = tracker.bb(1);
                    dres_one.y = tracker.bb(2);
                    dres_one.w = tracker.bb(3) - tracker.bb(1);
                    dres_one.h = tracker.bb(4) - tracker.bb(2);
                    dres_one.r = 1;
                    dres_one.state = 2;

                    if tracker.dres.fr(end) == fr
                        dres_tmp = tracker.dres;
                        index_tmp = 1:numel(dres_tmp.fr)-1;
                        tracker.dres = sub(dres_tmp, index_tmp);            
                    end
                    tracker.dres = interpolate_dres(tracker.dres, dres_one);
                    % update LK tracker
                    tracker = LK_update(fr, tracker, dres_image.Igray{fr}, dres_associate, 1);
                else
                    tracker.state = 3;
                    dres_one = sub(tracker.dres, numel(tracker.dres.fr));
                    dres_one.fr = fr;
                    dres_one.id = tracker.target_id;
                    dres_one.state = 3;

                    if tracker.dres.fr(end) == fr
                        dres_tmp = tracker.dres;
                        index_tmp = 1:numel(dres_tmp.fr)-1;
                        tracker.dres = sub(dres_tmp, index_tmp);            
                    end      
                    tracker.dres = concatenate_dres(tracker.dres, dres_one);                        
                end
            else
                tracker.state = 3;
                dres_one = sub(tracker.dres, numel(tracker.dres.fr));
                dres_one.fr = fr;
                dres_one.id = tracker.target_id;
                dres_one.state = 3;

                if tracker.dres.fr(end) == fr
                    dres_tmp = tracker.dres;
                    index_tmp = 1:numel(dres_tmp.fr)-1;
                    tracker.dres = sub(dres_tmp, index_tmp);            
                end      
                tracker.dres = concatenate_dres(tracker.dres, dres_one);          
            end
  
        end
            
        % show results
        if is_show
            figure(1);     

            % show tracking results
            subplot(2, 3, 4);
            show_dres(fr, dres_image.I{fr}, 'Tracking', tracker.dres, 2);

            % show lost targets
            subplot(2, 3, 5);
            show_dres(fr, dres_image.I{fr}, 'Lost', tracker.dres, 3);
            
            subplot(2, 3, 6);
            show_templates(tracker, dres_image);

            fprintf('frame %d, state %d\n', fr, tracker.state);
            if is_pause
                pause();
            else
                pause(0.01);
            end
            
%             filename = sprintf('results/%s_%06d.png', seq_name, fr);
%             hgexport(h, filename, hgexport('factorystyle'), 'Format', 'png');
        end
        
        fr = fr + 1;
    end

end
tracker.w_occluded = svmtrain(tracker.l_occluded, tracker.f_occluded, '-c 1 -q -g 1 -b 1');
fprintf('Finish training %s\n', seq_name);

% save model
if is_save
    filename = sprintf('%s/%s_tracker_det.mat', opt.results, seq_name);
    save(filename, 'tracker');
end