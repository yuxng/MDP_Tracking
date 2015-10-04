% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
%
% training MDP
function tracker = MDP_train(seq_idx, tracker)

is_show = 0;   % set is_show to 1 to show tracking results in training
is_save = 1;   % set is_save to 1 to save trained tracker
is_text = 0;   % set is_text to 1 to display detailed info in training
is_pause = 0;  % set is_pause to 1 to debug

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
    
    % update weights of active state
    factive = MDP_feature_active(tracker, dres_det);
    index = labels ~= 0;    
    tracker.factive = [tracker.factive; factive(index,:)];
    tracker.lactive = [tracker.lactive; labels(index)];
    tracker.w_active = svmtrain(tracker.lactive, tracker.factive, '-c 1 -q');    
end

% for each training sequence
t = 0;
iter = 0;
max_iter = opt.max_iter;
max_count = opt.max_count;
count = 0;
num_train = numel(dres_train);
counter = zeros(num_train, 1);
is_good = zeros(num_train, 1);
is_difficult = zeros(num_train, 1);
while 1
    iter = iter + 1;
    if is_text
        fprintf('iter %d\n', iter);
    else
        fprintf('.');
        if mod(iter, 100) == 0
            fprintf('\n');
        end
    end
    if iter > max_iter
        fprintf('max iteration exceeds\n');
        break;
    end
    if isempty(find(is_good == 0, 1)) == 1
        % two pass training
        if count == opt.max_pass
            break;
        else
            count = count + 1;
            fprintf('***pass %d finished***\n', count);
            is_good = zeros(num_train, 1);
            is_good(is_difficult == 1) = 1;
            counter = zeros(num_train, 1);
            t = 0;
        end
    end
    
    % find a sequence to train
    while 1
        t = t + 1;
        if t > num_train
            t = 1;
        end
        if is_good(t) == 0
            break;
        end
    end
    if is_text
        fprintf('tracking sequence %d\n', t);
    end
    
    dres_gt = dres_train{t};
    
    % first frame
    fr = dres_gt.fr(1);
    id = dres_gt.id(1);
    
    % reset tracker
    tracker.prev_state = 1;
    tracker.state = 1;
    tracker.target_id = id;
    
    % start tracking
    while fr <= seq_num
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
        
        % inactive
        if tracker.state == 0
            if reward == 1
                is_good(t) = 1;
                fprintf('sequence %d is good\n', t);
            end
            break;
            
        % active    
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
            
        % tracked    
        elseif tracker.state == 2
            tracker.streak_occluded = 0;
            tracker = MDP_value(tracker, fr, dres_image, dres, []);
            
        % occluded
        elseif tracker.state == 3
            tracker.streak_occluded = tracker.streak_occluded + 1;
            
            % find a set of detections for association
            dres = MDP_crop_image_box(dres, dres_image.Igray{fr}, tracker);
            [dres, index_det, ctrack] = generate_association_index(tracker, fr, dres);
            index_gt = find(dres_gt.fr == fr, 1);
            if dres_gt.covered(index_gt) ~= 0
                index_det = [];
            end
            [tracker, ~, f] = MDP_value(tracker, fr, dres_image, dres, index_det);

            if is_show
                figure(1);
                subplot(2, 3, 3);
                show_dres(fr, dres_image.I{fr}, 'Potential Associations', sub(dres, index_det));
                hold on;
                plot(ctrack(1), ctrack(2), 'ro', 'LineWidth', 2);
                hold off;
            end

            if isempty(index_det) == 0
                % compute reward
                [reward, label, f, is_end] = MDP_reward_occluded(fr, f, dres_image, ...
                    dres_gt, dres, index_det, tracker, opt, is_text);

                % update weights if negative reward
                if reward == -1
                    tracker.f_occluded(end+1,:) = f;
                    tracker.l_occluded(end+1) = label;
                    tracker.w_occluded = svmtrain(tracker.l_occluded, tracker.f_occluded, '-c 1 -q -g 1 -b 1');
                    if is_text
                        fprintf('training examples in occluded state %d\n', size(tracker.f_occluded,1));
                    end
                end

                if is_end
                    tracker.state = 0;
                end
            end
            
            % transition to inactive if lost for a long time
            if tracker.streak_occluded > opt.max_occlusion
                tracker.state = 0;
                if isempty(find(dres_gt.fr == fr, 1)) == 1
                    reward = 1;
                end
                if is_text
                    fprintf('target exits due to long time occlusion\n');
                end
            end
        end
        
        % check if outside image
        if tracker.state == 2
            [~, ov] = calc_overlap(tracker.dres, numel(tracker.dres.fr), dres_image, fr);
            if ov < opt.exit_threshold
                if is_text
                    fprintf('target outside image by checking boarders\n');
                end
                tracker.state = 0;
                reward = 1;
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
        
        % try to connect recently lost target
        if ~(tracker.state == 3 && tracker.prev_state == 2)
            fr = fr + 1;
        end
    end
    
    if fr > seq_num
        is_good(t) = 1;
        fprintf('sequence %d is good\n', t);
    end
    counter(t) = counter(t) + 1;
    if counter(t) > max_count
        is_good(t) = 1;
        is_difficult(t) = 1;
        fprintf('sequence %d max iteration\n', t);
    end
end
fprintf('Finish training %s\n', seq_name);

% save model
if is_save
    filename = sprintf('%s/%s_tracker.mat', opt.results, seq_name);
    save(filename, 'tracker');
end