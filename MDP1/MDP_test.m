% testing MDP
function metrics = MDP_test(seq_idx, seq_set, tracker)

is_show = 1;
is_save = 0;
is_text = 0;

opt = globals();
opt.is_text = is_text;

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

% load the trained model
if nargin < 2
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
    
    if is_show
        figure(1);
        
        % show ground truth
        if strcmp(seq_set, 'train') == 1
            subplot(2, 2, 1);
            show_dres(fr, dres_image.I{fr}, 'GT', dres_gt);
        end

        % show detections
        subplot(2, 2, 2);
        show_dres(fr, dres_image.I{fr}, 'Detections', dres_det);
    end
    
    % track targets
    for i = 1:numel(trackers)
        trackers{i} = track(fr, dres_image, dres, trackers{i}, opt);    
    end
    
    % connect targets
    [dres_tmp, index] = generate_initial_index(trackers, dres);
    dres_associate = sub(dres_tmp, index);
    for i = 1:numel(trackers)
        trackers{i} = connect(fr, dres_image, dres_associate, trackers{i}, opt);
    end    
    
    % associate targets
    [dres_tmp, index] = generate_initial_index(trackers, dres);
    dres_associate = sub(dres_tmp, index);
    for i = 1:numel(trackers)
        trackers{i} = associate(fr, dres_image, dres_associate, trackers{i}, opt);    
    end
    
    % find detections for initialization
    [dres, index] = generate_initial_index(trackers, dres);
    for i = 1:numel(index)
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
        figure(1);

        % show tracking results
        subplot(2, 2, 3);
        show_dres(fr, dres_image.I{fr}, 'Tracking', dres_track, 2);

        % show lost targets
        subplot(2, 2, 4);
        show_dres(fr, dres_image.I{fr}, 'Lost', dres_track, 3);

        pause(0.01);
    end
end

% write tracking results
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
    filename = sprintf('%s/%s.mat', opt.results, seq_name);
    save(filename, 'dres_track', 'metrics');
end

% initialize a tracker
% dres: detections
function tracker = initialize(fr, dres_image, id, dres, ind, tracker)

if tracker.state ~= 1
    return;
else  % active

    % initialize the LK tracker
    tracker = LK_initialize(tracker, fr, id, dres, ind, dres_image);
    
    tracker = MDP_value(tracker, fr, dres_image, dres, ind);
end


% apply a single tracker
% dres: detections
function tracker = track(fr, dres_image, dres, tracker, opt)

% tracked    
if tracker.state == 2
    tracker.streak_occluded = 0;
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
if tracker.state == 3 && double(max(tracker.dres.fr)) ~= fr
    tracker.streak_occluded = tracker.streak_occluded + 1;
    % find a set of detections for association
    index_det = generate_association_index(tracker, fr, dres_image.w(fr), dres_image.h(fr), dres_associate, 1);
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


function tracker = connect(fr, dres_image, dres_associate, tracker, opt)

% occluded
if tracker.state == 3 && tracker.prev_state == 2
    % find a set of detections for association
    index_det = generate_association_index(tracker, fr, dres_image.w(fr), dres_image.h(fr), dres_associate, 1);
    tracker = MDP_value(tracker, fr, dres_image, dres_associate, index_det);
    
    % erase last second
    dres = tracker.dres;
    index = [1:numel(dres.fr)-2, numel(dres.fr)];
    tracker.dres = sub(dres, index);
    
    % check if target outside image
    [~, ov] = calc_overlap(tracker.dres, numel(tracker.dres.fr), dres_image, fr);
    if ov < opt.exit_threshold
        if opt.is_text
            fprintf('target outside image by checking boarders\n');
        end
        tracker.state = 0;
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

for i = 1:num_track
    [~, o] = calc_overlap(dres_track, i, dres_track, 1:num_track);
    o(i) = 0;
    [mo, ind] = max(o);
    if mo > opt.overlap_sup
        o1 = calc_overlap(dres_track, i, dres_det, 1:num_det);
        o2 = calc_overlap(dres_track, ind, dres_det, 1:num_det);
        if max(o1) > max(o2)
            trackers{dres_track.id(ind)}.state = 3;
            trackers{dres_track.id(ind)}.dres.state(end) = 3;
            if opt.is_text
                fprintf('target %d suppressed\n', dres_track.id(ind));
            end
        else
            trackers{dres_track.id(i)}.state = 3;
            trackers{dres_track.id(i)}.dres.state(end) = 3;
            if opt.is_text
                fprintf('target %d suppressed\n', dres_track.id(i));
            end
        end
    end
end


% collect dres from trackers
dres_track = [];
for i = 1:numel(trackers)
    tracker = trackers{i};
    dres = sub(tracker.dres, numel(tracker.dres.fr));
    
    if tracker.state == 3
        if isempty(dres_track)
            dres_track = dres;
        else
            dres_track = concatenate_dres(dres_track, dres);
        end
    end
end   

% compute overlaps
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
    if mo > opt.overlap_sup_lost
        f1 = dres_track.fr(i);
        f2 = dres_track.fr(ind);
        if f1 > f2
            trackers{dres_track.id(ind)}.state = 0;
            trackers{dres_track.id(ind)}.dres.state(end) = 0;
            flag(ind) = 1;
            if opt.is_text
                fprintf('target %d suppressed\n', dres_track.id(ind));
            end
        else
            trackers{dres_track.id(i)}.state = 0;
            trackers{dres_track.id(i)}.dres.state(end) = 0;
            flag(i) = 1;
            if opt.is_text
                fprintf('target %d suppressed\n', dres_track.id(i));
            end
        end
    end
end