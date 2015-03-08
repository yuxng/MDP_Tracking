% training MDP
function MDP_train

is_show = 1;

opt = globals();
seq_idx = 1;
seq_name = opt.mot2d_train_seqs{seq_idx};
seq_num = opt.mot2d_train_nums(seq_idx);
seq_set = 'train';

% build the dres structure for images
dres_image = read_dres_image(opt, seq_set, seq_name, seq_num);
fprintf('read images done\n');

% generate training data
[dres_train, dres_det, labels] = generate_training_data(seq_idx, opt);
num_train = numel(dres_train);

% intialize tracker
I = dres_image.I{1};
tracker = MDP_initialize(size(I,2), size(I,1), dres_det, labels);

% for each training sequence
iter = 0;
for t = 7 * ones(1, 50) %1:num_train
    iter = iter + 1;
    tracker.alpha = tracker.alpha / iter;
    tracker.explore = tracker.explore / iter;
    
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
            break;

        % active
        elseif tracker.state == 1
            
            % compute overlap
            overlap = calc_overlap(dres_gt, 1, dres, 1:num_det);
            [ov, ind] = max(overlap);
            fprintf('Start: first frame overlap %.2f\n', ov);

            % initialize the LK tracker
            tracker = LK_initialize(tracker, fr, id, dres, ind, dres_image);
            
            % qscore
            [tracker, ~, f] = MDP_value(tracker, fr, dres_image, dres, ind);

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
            [tracker, qscore, f] = MDP_value(tracker, fr, dres_image, dres, []);
            
            % check if tracking result overlaps with gt
            index = find(dres_gt.fr == fr);
            if isempty(index) == 1
                overlap = 0;
            else
                if dres_gt.occluded(index) == 1
                    overlap = 0;
                else
                    overlap = calc_overlap(dres_gt, index, tracker.dres, numel(tracker.dres.fr));
                end
            end
            if overlap > 0.5
                if tracker.state == 2
                    reward = 1;
                else
                    reward = -1;
                end
            else
                if tracker.state == 3
                    reward = 1;
                else
                    reward = -1;
                end
            end
            fprintf('reward %.1f\n', reward);
            
            % update weights
            if fr == seq_num
                difference = reward - qscore;
            else
                if tracker.state == 3
                    difference = reward - qscore;
                else
                    index = find(dres_det.fr == fr+1);
                    dres_next = sub(dres_det, index);
                    [~, qscore_new] = MDP_value(tracker, fr+1, dres_image, dres_next, []);
                    difference = reward + tracker.gamma * qscore_new - qscore;
                end
            end
            tracker = MDP_update(tracker, difference, f);
            
        % occluded
        elseif tracker.state == 3
            % find a set of detections for association
            index_det = generate_association_index(tracker, fr, dres);
            [tracker, qscore, f] = MDP_value(tracker, fr, dres_image, dres, index_det);
            
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
                    if dres_gt.occluded(index) == 1
                        overlap = 0;
                    else
                        overlap = calc_overlap(dres_gt, index, dres, index_det);
                    end
                end
                if max(overlap) > 0.5
                    if tracker.state == 2
                        % if the association is correct
                        ov = calc_overlap(dres_gt, index, tracker.dres, numel(tracker.dres.fr));
                        if ov > 0.4
                            reward = 1;
                        else
                            reward = -1;
                            label = -1;
                            is_end = 1;
                            fprintf('associated to wrong target! Game over\n');
                        end
                    else
                        reward = -1;   % no association
                        reward = 1;
                        label = 1;
                        % extract features
                        [~, ind] = max(overlap);
                        dres_one = sub(dres, index_det(ind));
                        f = MDP_feature_occluded(fr, dres_image, dres_one, tracker);                        
                        fprintf('Missed association!\n');
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
        end
        
        % check if target outside image
        if isempty(find(tracker.flags == 1, 1)) == 1
            if tracker.dres.x(end) < 0 || tracker.dres.x(end)+tracker.dres.w(end) > dres_image.w(fr)
                fprintf('target outside image by checking boarders\n');
                tracker.state = 0;
            end 
        end
            
        % show results
        if iter > 30
            is_show = 1;
        end
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
            pause();
            
            % filename = sprintf('results/%s_%06d.png', seq_name, fr);
            % hgexport(h, filename, hgexport('factorystyle'), 'Format', 'png');
        end
        
        fr = fr + 1;
    end
end