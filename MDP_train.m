% training MDP
function MDP_train

is_show = 0;

opt = globals();
opt.is_show = is_show;
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
    save(filename, 'dres_image');
end

% generate training data
I = dres_image.I{1};
[dres_train, dres_det, labels] = generate_training_data(seq_idx, size(I,2), size(I,1), opt);

% for debugging
% dres_train = {dres_train{11}};

num_train = numel(dres_train);
is_good = zeros(num_train, 1);

% intialize tracker
tracker = MDP_initialize(size(I,2), size(I,1), dres_det, labels);

% for each training sequence
t = 0;
iter = 0;
max_iter = 10000;
max_count = 20;
count = 0;
counter = zeros(num_train, 1);
while 1
    iter = iter + 1;
    fprintf('iter %d\n', iter);
    if iter > max_iter
        break;
    end
    if isempty(find(is_good == 0, 1)) == 1
        % two pass training
        if count == 2
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
    while fr <= seq_num
        fprintf('\nframe %d, state %d\n', fr, tracker.state);
        
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
            fprintf('Start: first frame overlap %.2f\n', ov);

            % initialize the LK tracker
            tracker = LK_initialize(tracker, fr, id, dres, ind, dres_image, opt);
            
            % qscore
            [tracker, ~, f] = MDP_value(tracker, fr, dres_image, dres, ind, opt);

            % compute reward
            if id == -1
                if tracker.state == 0
                    reward = 1;
                else
                    reward = -1;
                end
                label = -1;
            else
                if tracker.state == 2
                    reward = 1;
                else
                    reward = -1;
                end
                label = 1;
            end
            fprintf('reward %.1f\n', reward);
            
            % update weights
            if reward == -1
                tracker.factive(end+1,:) = f;
                tracker.lactive(end+1) = label;
                tracker.w_active = svmtrain(tracker.lactive, tracker.factive, '-c 1');
            end
            
        % tracked    
        elseif tracker.state == 2
            tracker.streak_occluded = 0;
            [tracker, ~, f] = MDP_value(tracker, fr, dres_image, dres, [], opt);
            
            % check if tracking result overlaps with gt
            is_end = 0;
            index = find(dres_gt.fr == fr);
            if isempty(index) == 1
                overlap = 0;
            else
                if dres_gt.covered(index) > opt.overlap_occ
                    overlap = 0;
                else
                    overlap = calc_overlap(dres_gt, index, tracker.dres, numel(tracker.dres.fr));
                end
            end
            fprintf('overlap in tracked %.2f\n', overlap);
            if overlap > 0.5
                if tracker.state == 2
                    reward = 1;
                else
                    reward = -1;
                    label = 1;
                    if isempty(find(tracker.flags ~= 2, 1)) == 1
                        reward = 0;  % no update
                    else
                        if isempty(find(dres_gt.occluded == 1, 1)) == 1
                            is_end = 1;
                            fprintf('target not tracked! Game over\n');
                        end
                    end
                end
            else
                if tracker.state == 3
                    reward = 1;
                else
                    if overlap < 0.2
                        reward = -1;                       
                    else
                        reward = 0;  % no update
                    end
                    label = -1;
                    % possible drift
                    if isempty(index) == 0 && dres_gt.covered(index) > 0.9
                        is_end = 1;
                        fprintf('target drift! Game over\n');
                    end
                end
            end
            fprintf('reward %.1f\n', reward);
            
            % update weights
            if reward == -1
                tracker.ftracked(end+1,:) = f;
                tracker.ltracked(end+1) = label;
                tracker.w_tracked = svmtrain(tracker.ltracked, tracker.ftracked, '-c 1 -b 1 -q');
                fprintf('training examples in tracked state %d\n', size(tracker.ftracked,1));
            end
            
            if is_end
                tracker.state = 0;
            end
            
        % occluded
        elseif tracker.state == 3
            tracker.streak_occluded = tracker.streak_occluded + 1;
            % find a set of detections for association
            index_det = generate_association_index(tracker, fr, dres_image.w(fr), dres_image.h(fr), dres, 0);
            [tracker, ~, f] = MDP_value(tracker, fr, dres_image, dres, index_det, opt);
            
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
                fprintf('max overlap in association %.2f\n', max(overlap));
                if max(overlap) > 0.4
                    if tracker.state == 2
                        % if the association is correct
                        ov = calc_overlap(dres_gt, index, tracker.dres, numel(tracker.dres.fr));
                        if ov > 0.4
                            reward = 1;
                        else
                            reward = -1;
                            label = -1;
                            is_end = 1;
                            fprintf('associated to wrong target (%.2f, %.2f)! Game over\n', max(overlap), ov);
                        end
                    else  % target not associated
                        if dres_gt.covered(index) < 0.2
                            if isempty(find(tracker.flags ~= 2, 1)) == 1
                                reward = 0;  % no update
                            else
                                reward = -1;   % no association
                                label = 1;
                                % extract features
                                [~, ind] = max(overlap);
                                dres_one = sub(dres, index_det(ind));
                                f = MDP_feature_occluded(fr, dres_image, dres_one, tracker, opt);
                                is_end = 1;
                                fprintf('Missed association!\n');
                            end
                        else
                            reward = 1;
                        end
                    end
                else
                    if tracker.state == 3
                        reward = 1;
                    else
                        reward = -1;
                        label = -1;
                        is_end = 1;
                        fprintf('associated to wrong target! Game over\n');
                    end
                end
                fprintf('reward %.1f\n', reward);

                % update weights
                if reward == -1
                    tracker.foccluded(end+1,:) = f;
                    tracker.loccluded(end+1) = label;
                    tracker.w_occluded = svmtrain(tracker.loccluded, tracker.foccluded, '-c 1 -b 1 -q');
                    fprintf('training examples in occluded state %d\n', size(tracker.foccluded,1));
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
                fprintf('target exits due to long time occlusion\n');
            end
            
        end
        
        % check if outside image
        if tracker.state == 2
            [~, ov] = calc_overlap(tracker.dres, numel(tracker.dres.fr), dres_image, fr);
            if ov < opt.exit_threshold
                fprintf('target outside image by checking boarders\n');
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
            pause(0.001);
            
%             filename = sprintf('results/%s_%06d.png', seq_name, fr);
%             hgexport(h, filename, hgexport('factorystyle'), 'Format', 'png');
        end
        
        fr = fr + 1;
    end
    
    if fr > seq_num
        is_good(t) = 1;
        fprintf('sequence %d is good\n', t);
    end
    counter(t) = counter(t) + 1;
    if counter(t) > max_count
        is_good(t) = 1;
        fprintf('sequence %d max iteration\n', t);
    end
end

% save model
save('tracker.mat', 'tracker');