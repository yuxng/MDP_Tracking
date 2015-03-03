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

% read detections
filename = fullfile(opt.mot, opt.mot2d, seq_set, seq_name, 'det', 'det.txt');
dres_det = read_mot2dres(filename);

% generate training data
dres_train = generate_training_data(seq_idx, opt);
num_train = numel(dres_train);

% intialize tracker
filename = fullfile(opt.mot, opt.mot2d, seq_set, seq_name, 'img1', sprintf('%06d.jpg', 1));
I = imread(filename);
tracker = MDP_initialize(size(I,2), size(I,1), dres_det);

% for each training sequence
for t = 1:num_train
    dres_gt = dres_train{t};
    num_seq = numel(dres_gt.fr);
    
    % first frame
    fr = dres_gt.fr(1);
    id = dres_gt.id(1);
    
    % reset tracker
    tracker.prev_state = 1;
    tracker.state = 1;
    tracker.target_id = id;
    
    % extract detection
    index = find(dres_det.fr == fr);
    dres = sub(dres_det, index);
    num_det = numel(dres.fr);
    
    % compute overlap
    overlap = calc_overlap(dres_gt, 1, dres, 1:num_det);
    [ov, ind] = max(overlap);
    disp(ov);
    [tracker, qscore, f] = MDP_value(tracker, fr, dres_image, dres, ind);
    
    % compute reward
    if id == -1
        if tracker.state == 0
            reward = 1;
        else
            reward = -1;
        end
        % update weights
        difference = reward - qscore;
        tracker = MDP_update(tracker, difference, f);
        continue;
    else
        if tracker.state == 2
            reward = 1;
        else
            reward = -1;
            % update weights
            difference = reward - qscore;
            tracker = MDP_update(tracker, difference, f);            
            continue;
        end
    end
    
    % up to here tracked target
    % initialize the LK tracker
    x1 = dres.x(ind);
    y1 = dres.y(ind);
    x2 = dres.x(ind) + dres.w(ind);
    y2 = dres.y(ind) + dres.h(ind);    
    tracker = LK_initialize(tracker, fr, id, x1, y1, x2, y2);     
    
    % extract detection
    index = find(dres_det.fr == fr+1);
    dres_next = sub(dres_det, index);
    [~, qscore_new] = MDP_value(tracker, fr+1, dres_image, dres_next, []);
    difference = reward + tracker.gamma * qscore_new - qscore;
    
    % update weights
    tracker = MDP_update(tracker, difference, f);
    
    % for each frame
    for i = 2:num_seq
        fr = dres_gt.fr(i);
        
        % extract detection
        index = find(dres_det.fr == fr);
        dres = sub(dres_det, index);
        
        if tracker.state == 3   % occluded
            % find a set of detections for association
            index_det = generate_association_index(tracker, fr, dres);
            if isempty(index_det) == 1
                continue;
            end
            [tracker, qscore, f] = MDP_value(tracker, fr, dres_image, dres, index_det);
            
            % check if any detection overlap with gt
            overlap = calc_overlap(dres_gt, i, dres, index_det);
            if max(overlap) > 0.5
                if tracker.state == 2
                    % if the association is correct
                    ov = calc_overlap(dres_gt, i, tracker.dres, numel(tracker.dres.fr));
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
            
            % update weights
            if tracker.state == 3
                j = 1;
                while fr+j <= dres_gt.fr(num_seq)
                    index = find(dres_det.fr == fr+j);
                    dres_next = sub(dres_det, index);
                    index_det = generate_association_index(tracker, fr+j, dres_next);
                    if isempty(index_det) == 0
                        break;
                    end
                    j = j + 1;
                end
            else
                j = 1;
                index = find(dres_det.fr == fr+j);
                dres_next = sub(dres_det, index);                
                index_det = [];
            end
            [~, qscore_new] = MDP_value(tracker, fr+j, dres_image, dres_next, index_det);
            difference = reward + tracker.gamma * qscore_new - qscore;
            tracker = MDP_update(tracker, difference, f);     
        elseif tracker.state == 2
            [tracker, qscore, f] = MDP_value(tracker, fr, dres_image, dres, []);
            
            % check if any detection overlap with gt            
            overlap = calc_overlap(dres_gt, i, tracker.dres, numel(tracker.dres.fr));
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
            
            % update weights
            if tracker.state == 3
                j = 1;
                while fr+j <= dres_gt.fr(num_seq) 
                    index = find(dres_det.fr == fr+j);
                    dres_next = sub(dres_det, index);
                    index_det = generate_association_index(tracker, fr+j, dres_next);
                    if isempty(index_det) == 0
                        break;
                    end
                    j = j + 1;                    
                end
            else
                j = 1;
                index = find(dres_det.fr == fr+j);
                dres_next = sub(dres_det, index);                
                index_det = [];
            end
            [~, qscore_new] = MDP_value(tracker, fr+j, dres_image, dres_next, index_det);
            difference = reward + tracker.gamma * qscore_new - qscore;
            tracker = MDP_update(tracker, difference, f);           
        end
        
        % show results
        if is_show
            figure(1);
            % show ground truth
            subplot(2, 2, 1);
            show_dres(fr, dres_image.I{fr}, 'GT', dres_gt);

            % show detections
            subplot(2, 2, 2);
            show_dres(fr, dres_image.I{fr}, 'Detections', dres_det);        

            % show tracking results
            subplot(2, 2, 3);
            show_dres(fr, dres_image.I{fr}, 'Tracking', tracker.dres);        

            % show lost targets
            subplot(2, 2, 4);

            pause();
        end        
    end
end