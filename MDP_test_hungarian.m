% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
%
% testing MDP
function metrics = MDP_test_hungarian(seq_idx, seq_set, tracker, is_kitti)

if nargin < 4
    is_kitti = 0;
end

is_show = 0;
is_save = 1;
is_text = 0;
is_pause = 0;

opt = globals();
opt.is_text = is_text;
opt.exit_threshold = 0.7;

if is_kitti == 1
    opt.max_occlusion = 20;
    opt.tracked = 10;
    opt.threshold_dis = 1;
    tracker.threshold_dis = opt.threshold_dis;
end

if is_show
%     close all;
end

if is_kitti == 0
    if strcmp(seq_set, 'train') == 1
        seq_name = opt.mot2d_train_seqs{seq_idx};
        seq_num = opt.mot2d_train_nums(seq_idx);
    else
        seq_name = opt.mot2d_test_seqs{seq_idx};
        seq_num = opt.mot2d_test_nums(seq_idx);
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

    % read detections
    filename = fullfile(opt.mot, opt.mot2d, seq_set, seq_name, 'det', 'det.txt');
    dres_det = read_mot2dres(filename);

    if strcmp(seq_set, 'train') == 1
        % read ground truth
        filename = fullfile(opt.mot, opt.mot2d, seq_set, seq_name, 'gt', 'gt.txt');
        dres_gt = read_mot2dres(filename);
        dres_gt = fix_groundtruth(seq_name, dres_gt);
    end
else
    if strcmp(seq_set, 'training') == 1
        seq_name = opt.kitti_train_seqs{seq_idx};
        seq_num = opt.kitti_train_nums(seq_idx);
    else
        seq_name = opt.kitti_test_seqs{seq_idx};
        seq_num = opt.kitti_test_nums(seq_idx);
    end

    % build the dres structure for images
    filename = sprintf('%s/kitti_%s_%s_dres_image.mat', opt.results_kitti, seq_set, seq_name);
    if exist(filename, 'file') ~= 0
        object = load(filename);
        dres_image = object.dres_image;
        fprintf('load images from file %s done\n', filename);
    else
        dres_image = read_dres_image_kitti(opt, seq_set, seq_name, seq_num);
        fprintf('read images done\n');
        save(filename, 'dres_image', '-v7.3');
    end

    % read detections
    filename = fullfile(opt.kitti, seq_set, 'det_02', [seq_name '.txt']);
    dres_det = read_kitti2dres(filename);    

    if strcmp(seq_set, 'training') == 1
        % read ground truth
        filename = fullfile(opt.kitti, seq_set, 'label_02', [seq_name '.txt']);
        dres_gt = read_kitti2dres(filename);
    end
end

% load the trained model
if nargin < 3
    object = load('tracker.mat');
    tracker = object.tracker;
end

% intialize tracker
I = dres_image.I{1};
tracker = MDP_initialize_test(tracker, size(I,2), size(I,1), dres_det, is_show);

% for each frame
trackers = [];
id = 0;
for fr = 1:seq_num
    if is_text
        fprintf('frame %d\n', fr);
    else
        fprintf('.');
        if mod(fr, 100) == 0
            fprintf('\n');
        end        
    end
    
    % extract detection
    index = find(dres_det.fr == fr);
    dres = sub(dres_det, index);
    
    % nms
    if is_kitti
        boxes = [dres.x dres.y dres.x+dres.w dres.y+dres.h dres.r];
        index = nms_new(boxes, 0.6);
        dres = sub(dres, index);

        % only keep cars and pedestrians
        ind = strcmp('Car', dres.type) | strcmp('Pedestrian', dres.type);
        index = find(ind == 1);
        dres = sub(dres, index);
    end
    
    dres = MDP_crop_image_box(dres, dres_image.Igray{fr}, tracker);
    
    if is_show
        figure(1);
        
        % show ground truth
        if strcmp(seq_set, 'train') == 1
            subplot(2, 2, 1);
            show_dres(fr, dres_image.I{fr}, 'GT', dres_gt);
        end

        % show detections
%         subplot(2, 2, 2);
        show_dres(fr, dres_image.I{fr}, 'Detections', dres);
    end
    
    % separate trackers into the first and the second class
    [index1, index2] = sort_trackers(trackers);
    
    for k = 1:2
        % process trackers in the first class or the second class
        if k == 1
            index_track = index1;
        else
            index_track = index2;
        end
           
        num_track = numel(index_track);
        flags = zeros(num_track, 1);

        % process tracked targets
        for i = 1:num_track
            ind = index_track(i);
            if trackers{ind}.state == 0
                flags(i) = 1;
            elseif trackers{ind}.state == 2
                % track target
                trackers{ind} = track(fr, dres_image, dres, trackers{ind}, opt);
                % connect target
                if trackers{ind}.state == 3
                    if k == 1
                        index_tmp = index_track(1:i-1);
                    else
                        index_tmp = [index_track(1:i-1); index1];
                    end                    
                    [dres_tmp, index] = generate_initial_index(trackers(index_tmp), dres);
                    dres_associate = sub(dres_tmp, index);
                    trackers{ind} = associate(fr, dres_image,  dres_associate, trackers{ind}, opt);
                end                
                
                if trackers{ind}.state == 2 || trackers{ind}.state == 0
                    flags(i) = 1;
                end
            end
        end

        % process lost targets
        if k == 1
            index_tmp = index_track(flags == 1);
        else
            index_tmp = [index_track(flags == 1); index1];
        end
        [dres_tmp, index] = generate_initial_index(trackers(index_tmp), dres);    
        dres_associate = sub(dres_tmp, index);
        num_det = numel(index);

        % compute distance matrix
        index_track = index_track(flags == 0);
        num_track = numel(index_track);
        dist = zeros(num_track, num_det);
        for i = 1:num_track
            % lost target
            ind = index_track(i);
            dist(i,:) = compute_distance(fr, dres_image, dres_associate, trackers{ind});
        end

        % Hungarian algorithm
        assignment = assignmentoptimal(dist);

        % process the assignment
        for i = 1:numel(assignment)
            det_id = assignment(i);
            ind = index_track(i);
            if det_id == 0
                % no association
                trackers{ind}.state = 3;
                dres_one = sub(trackers{ind}.dres, numel(trackers{ind}.dres.fr));
                dres_one.fr = fr;
                dres_one.id = trackers{ind}.target_id;
                dres_one.state = 3;

                if trackers{ind}.dres.fr(end) == fr
                    dres_tmp = trackers{ind}.dres;
                    index_tmp = 1:numel(dres_tmp.fr)-1;
                    trackers{ind}.dres = sub(dres_tmp, index_tmp);
                end        
                trackers{ind}.dres = concatenate_dres(trackers{ind}.dres, dres_one);
            else
                % association
                dres_one = sub(dres_associate, det_id);
                trackers{ind} = LK_associate(fr, dres_image, dres_one, trackers{ind});

                trackers{ind}.state = 2;
                % build the dres structure
                dres_one = [];
                dres_one.fr = fr;
                dres_one.id = trackers{ind}.target_id;
                dres_one.x = trackers{ind}.bb(1);
                dres_one.y = trackers{ind}.bb(2);
                dres_one.w = trackers{ind}.bb(3) - trackers{ind}.bb(1);
                dres_one.h = trackers{ind}.bb(4) - trackers{ind}.bb(2);
                dres_one.r = 1;
                dres_one.state = 2;
                if isfield(trackers{ind}.dres, 'type')
                    dres_one.type = {trackers{ind}.dres.type{1}};
                end    

                if trackers{ind}.dres.fr(end) == fr
                    dres_tmp = trackers{ind}.dres;
                    index_tmp = 1:numel(dres_tmp.fr)-1;
                    trackers{ind}.dres = sub(dres_tmp, index_tmp);            
                end
                trackers{ind}.dres = interpolate_dres(trackers{ind}.dres, dres_one);
                % update LK tracker
                trackers{ind} = LK_update(fr, trackers{ind}, dres_image.Igray{fr}, dres_associate, 1);              
            end
        end
    end
    
    % find detections for initialization
    [dres, index] = generate_initial_index(trackers, dres);
    for i = 1:numel(index)
        % extract features
        dres_one = sub(dres, index(i));
        f = MDP_feature_active(tracker, dres_one);
        % prediction
        label = svmpredict(1, f, tracker.w_active, '-q');
        % make a decision
        if label < 0
            continue;
        end
        
        % reset tracker
        tracker.prev_state = 1;
        tracker.state = 1;            
        id = id + 1;
        
        trackers{end+1} = initialize(fr, dres_image, id, dres, index(i), tracker);
    end
    
    % resolve tracker conflict
    trackers = resolve(trackers, dres, opt);    
    
    dres_track = generate_results(trackers);
    if is_show
        figure(2);

        % show tracking results
%         subplot(2, 2, 3);
        show_dres(fr, dres_image.I{fr}, 'Tracking', dres_track, 2);

        % show lost targets
%         subplot(2, 2, 4);
        figure(3);
        show_dres(fr, dres_image.I{fr}, 'Lost', dres_track, 3);

        if is_pause
            pause();
        else
            pause(0.01);
        end
    end  
end

% write tracking results
if is_kitti == 0
    filename = sprintf('%s/%s.txt', opt.results, seq_name);
    fprintf('write results: %s\n', filename);
    write_tracking_results(filename, dres_track, opt.tracked);

    % evaluation
    if strcmp(seq_set, 'train') == 1
        benchmark_dir = fullfile(opt.mot, opt.mot2d, seq_set, filesep);
        metrics = evaluateTracking({seq_name}, opt.results, benchmark_dir);
    else
        metrics = [];
    end

    % save results
    if is_save
        filename = sprintf('%s/%s_results.mat', opt.results, seq_name);
        save(filename, 'dres_track', 'metrics');
    end
else
    filename = sprintf('%s/%s.txt', opt.results_kitti, seq_name);
    fprintf('write results: %s\n', filename);
    write_tracking_results_kitti(filename, dres_track, opt.tracked);
    
    % evaluation
    if strcmp(seq_set, 'training') == 1
        % write a temporal seqmap file
        filename = sprintf('%s/evaluate_tracking.seqmap', opt.results_kitti);
        fid = fopen(filename, 'w');
        fprintf(fid, '%s empty %06d %06d\n', seq_name, 0, seq_num);
        fclose(fid);
        system('python evaluate_tracking_kitti.py results_kitti');
    end
    
    % save results
    if is_save
        filename = sprintf('%s/kitti_%s_%s_results.mat', opt.results_kitti, seq_set, seq_name);
        save(filename, 'dres_track');
    end    
end


% sort trackers according to number of tracked frames
function [index1, index2] = sort_trackers(trackers)

sep = 10;
num = numel(trackers);
len = zeros(num, 1);
state = zeros(num, 1);
for i = 1:num
    len(i) = trackers{i}.streak_tracked;
    state(i) = trackers{i}.state;
end

index1 = find(len > sep);
[~, ind] = sort(state(index1));
index1 = index1(ind);

index2 = find(len <= sep);
[~, ind] = sort(state(index2));
index2 = index2(ind);


% initialize a tracker
% dres: detections
function tracker = initialize(fr, dres_image, id, dres, ind, tracker)

if tracker.state ~= 1
    return;
else  % active

    % initialize the LK tracker
    tracker = LK_initialize(tracker, fr, id, dres, ind, dres_image);
    tracker.state = 2;
    tracker.streak_occluded = 0;
    tracker.streak_tracked = 0;

    % build the dres structure
    dres_one.fr = dres.fr(ind);
    dres_one.id = tracker.target_id;
    dres_one.x = dres.x(ind);
    dres_one.y = dres.y(ind);
    dres_one.w = dres.w(ind);
    dres_one.h = dres.h(ind);
    dres_one.r = dres.r(ind);
    dres_one.state = tracker.state;
    if isfield(dres, 'type')
        dres_one.type = {dres.type{ind}};
    end        
    tracker.dres = dres_one;
end

% track a target
function tracker = track(fr, dres_image, dres, tracker, opt)

% tracked    
if tracker.state == 2
    tracker.streak_occluded = 0;
    tracker.streak_tracked = tracker.streak_tracked + 1;
    tracker = MDP_value(tracker, fr, dres_image, dres, []);

    % check if target outside image
    [~, ov] = calc_overlap(tracker.dres, numel(tracker.dres.fr), dres_image, fr);
    if ov < opt.exit_threshold
        if opt.is_text
            fprintf('target outside image by checking boarders\n');
        end
        tracker.state = 0;
    end    
end


% associate a lost target
function tracker = associate(fr, dres_image, dres_associate, tracker, opt)

% occluded
if tracker.state == 3
    tracker.streak_occluded = tracker.streak_occluded + 1;
    % find a set of detections for association
    [dres_associate, index_det] = generate_association_index(tracker, fr, dres_associate);
    tracker = MDP_value(tracker, fr, dres_image, dres_associate, index_det);
    if tracker.state == 2
        tracker.streak_occluded = 0;
    end

    if tracker.streak_occluded > opt.max_occlusion
        tracker.state = 0;
        if opt.is_text
            fprintf('target %d exits due to long time occlusion\n', tracker.target_id);
        end
    end
    
    % check if target outside image
    [~, ov] = calc_overlap(tracker.dres, numel(tracker.dres.fr), dres_image, fr);
    if ov < opt.exit_threshold
        if opt.is_text
            fprintf('target outside image by checking boarders\n');
        end
        tracker.state = 0;
    end    
end


% associate a lost target
function dist = compute_distance(fr, dres_image, dres_associate, tracker)

% occluded
if tracker.state == 3
    % find a set of detections for association
    [dres_associate, index_det] = generate_association_index(tracker, fr, dres_associate);
    
    % compute association scores
    num = numel(dres_associate.fr);
    dist = Inf(1, num);    
    if isempty(index_det) == 0
        % extract features with LK association
        dres = sub(dres_associate, index_det);
        [features, flag] = MDP_feature_occluded(fr, dres_image, dres, tracker);

        m = size(features, 1);
        labels = -1 * ones(m, 1);
        [~, ~, probs] = svmpredict(labels, features, tracker.w_occluded, '-b 1 -q');
        
        dist(index_det(flag == 1)) = probs(flag == 1, 2);
        dist(dist > 0.5) = inf;
    end
end


% resolve conflict between trackers
function trackers = resolve(trackers, dres_det, opt)

% collect dres from trackers
dres_track = [];
for i = 1:numel(trackers)
    tracker = trackers{i};
    dres = sub(tracker.dres, numel(tracker.dres.fr));
    
    if tracker.state == 2
        if isempty(dres_track)
            dres_track = dres;
        else
            dres_track = concatenate_dres(dres_track, dres);
        end
    end
end   

% compute overlaps
num_det = numel(dres_det.fr);
if isempty(dres_track)
    num_track = 0;
else
    num_track = numel(dres_track.fr);
end

flag = zeros(num_track, 1);
for i = 1:num_track
    [~, o] = calc_overlap(dres_track, i, dres_track, 1:num_track);
    o(i) = 0;
    o(flag == 1) = 0;
    [mo, ind] = max(o);
    
    if isfield(dres_track, 'type')
        cls = dres_track.type{i};
        if strcmp(cls, 'Pedestrian') == 1
            overlap_sup = opt.overlap_sup;
        elseif strcmp(cls, 'Car') == 1
            overlap_sup = 0.95;
        end
    end
    
    if mo > overlap_sup        
        num1 = trackers{dres_track.id(i)}.streak_tracked;
        num2 = trackers{dres_track.id(ind)}.streak_tracked;
        o1 = max(calc_overlap(dres_track, i, dres_det, 1:num_det));
        o2 = max(calc_overlap(dres_track, ind, dres_det, 1:num_det));
        
        if num1 > num2
            sup = ind;
        elseif num1 < num2
            sup = i;
        else
            if o1 > o2
                sup = ind;
            else
                sup = i;
            end
        end
        
        trackers{dres_track.id(sup)}.state = 3;
        trackers{dres_track.id(sup)}.dres.state(end) = 3;
        if opt.is_text
            fprintf('target %d suppressed\n', dres_track.id(sup));
        end
        flag(sup) = 1;
    end
end