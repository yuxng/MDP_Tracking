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

% read detections
filename = fullfile(opt.mot, opt.mot2d, seq_set, seq_name, 'det', 'det.txt');
dres_det = read_mot2dres(filename);

% generate training data
dres_train = generate_training_data(seq_idx, opt);
num_train = numel(dres_train);

% intialize tracker
I = dres_image.I{1};
tracker = MDP_initialize(size(I,2), size(I,1), dres_det);

% for each training sequence
for t = 6 * ones(1, 10) %1:num_train
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
            subplot(2, 2, 1);
            show_dres(fr, dres_image.I{fr}, 'GT', dres_gt);

            % show detections
            subplot(2, 2, 2);
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
            x1 = dres.x(ind);
            y1 = dres.y(ind);
            x2 = dres.x(ind) + dres.w(ind);
            y2 = dres.y(ind) + dres.h(ind);    
            tracker = LK_initialize(tracker, fr, id, x1, y1, x2, y2);            
            
            % qscore
            [tracker, qscore, f] = MDP_value(tracker, fr, dres_image, dres, ind);

            % compute reward
            if id == -1
                if tracker.state == 0
                    reward = 1;
                else
                    reward = -1;
                end
            else
                if tracker.state == 2
                    reward = 1;
                else
                    reward = -1;
                end
            end
            fprintf('reward %.1f\n', reward);
            
            % update weights
            if tracker.state == 0 || fr == seq_num
                difference = reward - qscore;
            else
                index = find(dres_det.fr == fr+1);
                dres_next = sub(dres_det, index);                
                [~, qscore_new] = MDP_value(tracker, fr+1, dres_image, dres_next, []);            
                difference = reward + tracker.gamma * qscore_new - qscore;
            end
            tracker = MDP_update(tracker, difference, f);
            
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
            is_end = 0;
            if fr == seq_num
                difference = reward - qscore;
            else
                if tracker.state == 3
                    j = 1;
                    index_det = [];
                    while fr+j <= seq_num
                        index = find(dres_det.fr == fr+j);
                        dres_next = sub(dres_det, index);
                        index_det = generate_association_index(tracker, fr+j, dres_next);
                        if isempty(index_det) == 0
                            break;
                        end
                        j = j + 1;
                    end
                    if isempty(index_det) == 0
                        [~, qscore_new] = MDP_value(tracker, fr+j, dres_image, dres_next, index_det);                   
                        difference = reward + tracker.gamma * qscore_new - qscore;
                    else
                        difference = reward - qscore;
                        is_end = 1;
                        fprintf('no detection to associate in the future, end target\n');
                    end
                else
                    index = find(dres_det.fr == fr+1);
                    dres_next = sub(dres_det, index);
                    [~, qscore_new] = MDP_value(tracker, fr+1, dres_image, dres_next, []);
                    difference = reward + tracker.gamma * qscore_new - qscore;
                end
            end
            tracker = MDP_update(tracker, difference, f);
            if is_end
                tracker.state = 0;
            end
            
        % occluded
        elseif tracker.state == 3   
            % find a set of detections for association
            index_det = generate_association_index(tracker, fr, dres);
            [tracker, qscore, f] = MDP_value(tracker, fr, dres_image, dres, index_det);

            if isempty(index_det) == 0
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
                        if ov > 0.5
                            reward = 1;
                        else
                            reward = -1;
                        end
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
                is_end = 0;
                if fr == seq_num
                    difference = reward - qscore;
                elseif tracker.state == 3
                    j = 1;
                    index_det = [];
                    while fr+j <= seq_num
                        index = find(dres_det.fr == fr+j);
                        dres_next = sub(dres_det, index);
                        index_det = generate_association_index(tracker, fr+j, dres_next);
                        if isempty(index_det) == 0
                            break;
                        end
                        j = j + 1;
                    end
                    if isempty(index_det) == 0
                        [~, qscore_new] = MDP_value(tracker, fr+j, dres_image, dres_next, index_det);                 
                        difference = reward + tracker.gamma * qscore_new - qscore;
                    else
                        difference = reward - qscore;
                        is_end = 1;
                        fprintf('no detection to associate in the future, end target\n');
                    end                    
                else
                    index = find(dres_det.fr == fr+1);
                    dres_next = sub(dres_det, index);
                    [~, qscore_new] = MDP_value(tracker, fr+1, dres_image, dres_next, []);                   
                    difference = reward + tracker.gamma * qscore_new - qscore;
                end
                tracker = MDP_update(tracker, difference, f);
                if is_end
                    tracker.state = 0;
                end
            end
        end
        
        % check if target outside image
        if isempty(find(tracker.flags == 2, 1)) == 0
            fprintf('target outside image\n');
            tracker.state = 0;
        end
        
        % show results
        if is_show
            figure(1);     

            % show tracking results
            subplot(2, 2, 3);
            show_dres(fr, dres_image.I{fr}, 'Tracking', tracker.dres, 2);

            % show lost targets
            subplot(2, 2, 4);
            show_dres(fr, dres_image.I{fr}, 'Lost', tracker.dres, 3);

            fprintf('frame %d, state %d\n', fr, tracker.state);
            pause();
        end
        
        fr = fr + 1;
    end
end