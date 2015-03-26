% training MDP
function tracker = MDP_train(seq_idx, opt)

is_show = 0;
is_save = 1;
is_text = 0;
is_pause = 0;

if nargin < 2
    opt = globals();
end

seq_name = opt.mot2d_train_seqs{seq_idx};
seq_num = opt.mot2d_train_nums(seq_idx);
seq_set = 'train';

% try to use trained parameters
filename = sprintf('%s/%s_opt.mat', opt.results, seq_name);
if nargin < 2 && exist(filename, 'file')
    tmp = opt;
    object = load(filename);
    opt = object.opt;
    fprintf('load parameters from file %s\n', filename);
    opt.root = tmp.root;
    opt.mot = tmp.mot;
end
opt.is_show = is_show;

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
[dres_train, dres_det] = generate_training_data(seq_idx, opt);

% for debugging
% dres_train = {dres_train{2}};

num_train = numel(dres_train);
is_good = zeros(num_train, 1);

% intialize tracker
tracker = MDP_initialize(I, dres_det, opt);

% for each training sequence
t = 0;
iter = 0;
max_iter = opt.max_iter;
max_count = opt.max_count;
count = 0;
counter = zeros(num_train, 1);
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
        break;
    end
    if isempty(find(is_good == 0, 1)) == 1
        % two pass training
        if count == opt.max_pass
            break;
        else
            count = count + 1;
            is_good = zeros(num_train, 1);
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
        dres = MDP_crop_image_box(dres, dres_image.Igray{fr}, tracker);
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
            if reward == 1
                is_good(t) = 1;
                if is_text
                    fprintf('sequence %d is good\n', t);
                end
            end
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
            
        % occluded
        else
            if tracker.state == 2
                tracker.streak_occluded = 0;
            elseif tracker.state == 3
                tracker.streak_occluded = tracker.streak_occluded + 1;
            end
            
            % find a set of detections for association
            index_det = generate_association_index(tracker, fr, dres);
            [tracker, ~, f] = MDP_value(tracker, fr, dres_image, dres, index_det);

            if is_show
                figure(1);
                subplot(2, 3, 3);
                show_dres(fr, dres_image.I{fr}, 'Potential Associations', sub(dres, index_det));
            end

            if isempty(index_det) == 0
                is_end = 0;
                % check if any detection overlap with gt
                index = find(dres_gt.fr == fr);
                if isempty(index) == 1
                    overlap = 0;
                else
                    if dres_gt.covered(index) > opt.overlap_occ
                        overlap = 0;
                    else
                        overlap = calc_overlap(dres_gt, index, dres, index_det);
                    end
                end
                if is_text
                    fprintf('max overlap in association %.2f\n', max(overlap));
                end
                if max(overlap) > opt.overlap_pos
                    if tracker.state == 2
                        % if the association is correct
                        ov = calc_overlap(dres_gt, index, tracker.dres, numel(tracker.dres.fr));
                        if ov > opt.overlap_pos
                            reward = 1;
                        else
                            if ov < opt.overlap_neg
                                reward = -1;
                                label = -1;
                                is_end = 1;
                                if is_text
                                    fprintf('associated to wrong target (%.2f, %.2f)! Game over\n', max(overlap), ov);
                                end
                            else
                                reward = 0;
                            end
                        end
                    else  % target not associated
                        % if dres_gt.covered(index) < opt.overlap_neg
                        if dres_gt.covered(index) == 0
                            if isempty(find(tracker.flags ~= 2, 1)) == 1
                                reward = 0;  % no update
                            else
                                reward = -1;   % no association
                                label = 1;
                                % extract features
                                [~, ind] = max(overlap);
                                dres_one = sub(dres, index_det(ind));
                                f = MDP_feature(fr, dres_image, dres_one, tracker);
                                if is_text
                                    fprintf('Missed association!\n');
                                end
                                is_end = 1;
                            end
                        else
                            reward = 1;
                        end
                    end
                else
                    if tracker.state == 3
                        reward = 1;
                    else
                        ov = calc_overlap(dres_gt, index, tracker.dres, numel(tracker.dres.fr));
                        if ov < opt.overlap_neg || max(overlap) < opt.overlap_neg
                            reward = -1;
                            label = -1;
                            is_end = 1;
                            if is_text
                                fprintf('associated to wrong target! Game over\n');
                            end
                        else
                            reward = 0;
                        end
                    end
                end
                if is_text
                    fprintf('reward %.1f\n', reward);
                end

                % update weights
                if reward == -1
                    if tracker.prev_state == 3
                        tracker.f_occluded(end+1,:) = f;
                        tracker.l_occluded(end+1) = label;
                        tracker.w_occluded = svmtrain(tracker.l_occluded, tracker.f_occluded, '-c 1 -b 1 -q -g 1');
                        if is_text
                            fprintf('training examples in occluded state %d\n', size(tracker.f_occluded,1));
                        end
                    elseif tracker.prev_state == 2
                        tracker.f_tracked(end+1,:) = f;
                        tracker.l_tracked(end+1) = label;
                        tracker.w_tracked = svmtrain(tracker.l_tracked, tracker.f_tracked, '-c 1 -b 1 -q -g 1');
                        if is_text
                            fprintf('training examples in tracked state %d\n', size(tracker.f_tracked,1));
                        end
                    end
                end

                if is_end
                    tracker.state = 0;
                end
            end
            
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
        
        fr = fr + 1;
    end
    
    if fr > seq_num
        is_good(t) = 1;
        if is_text
            fprintf('sequence %d is good\n', t);
        end
    end
    counter(t) = counter(t) + 1;
    if counter(t) > max_count
        is_good(t) = 1;
        if is_text
            fprintf('sequence %d max iteration\n', t);
        end
    end
end
fprintf('Finish training %s\n', seq_name);

% save model
if is_save
    save('tracker.mat', 'tracker');
end