function main

opt = globals();

% LK trackers
MAX_ID = 10000;
trackers = cell(MAX_ID, 1);

seq_idx = 1;
is_show = 1;
seq_name = opt.mot2d_train_seqs{seq_idx};
seq_num = opt.mot2d_train_nums(seq_idx);
seq_set = 'train';

% build the dres structure for images
dres_image.x = zeros(seq_num, 1);
dres_image.y = zeros(seq_num, 1);
dres_image.w = zeros(seq_num, 1);
dres_image.h = zeros(seq_num, 1);
dres_image.I = cell(seq_num, 1);
dres_image.Igray = cell(seq_num, 1);

% read detections
filename = fullfile(opt.mot, opt.mot2d, seq_set, seq_name, 'det', 'det.txt');
dres_det = read_mot2dres(filename);

% read ground truth
filename = fullfile(opt.mot, opt.mot2d, seq_set, seq_name, 'gt', 'gt.txt');
dres_gt = read_mot2dres(filename);

for i = 1:seq_num
    % show image
    filename = fullfile(opt.mot, opt.mot2d, seq_set, seq_name, 'img1', sprintf('%06d.jpg', i));
    disp(filename);
    I = imread(filename);

    dres_image.x(i) = 1;
    dres_image.y(i) = 1;
    dres_image.w(i) = size(I, 2);
    dres_image.h(i) = size(I, 1);
    dres_image.I{i} = I;
    dres_image.Igray{i} = rgb2gray(I);
    
    % extract detections
    index = find(dres_det.fr == i);
    dres = sub(dres_det, index);
    num_det = numel(index);    

    if i == 1
        fprintf('initialization\n');
        % initialization
        dres_track = dres;
        id = 0;
        for j = 1:num_det
            id = id + 1;
            dres_track.id(j,1) = id;
            dres_track.state(j,1) = 1;
            % build appearance model for the initial targets
            x1 = dres_track.x(j);
            y1 = dres_track.y(j);
            x2 = dres_track.x(j) + dres_track.w(j);
            y2 = dres_track.y(j) + dres_track.h(j);
            trackers{id} = MDP_initialize(size(I,2), size(I,1), dres_det);
            trackers{id} = LK_initialize(trackers{id}, i, id, x1, y1, x2, y2);
            fprintf('target %d enter\n', id);
        end
    else
        % find tracked targets
        index = find(dres_track.state == 1);
        for j = 1:numel(index)
            ind = index(j);
            id = dres_track.id(ind);
            
            for k = 1:num_det
                dres_one = sub(dres, k);
                trackers{id} = LK_associate(i, dres_image, dres_one, trackers{id});
            end
            
            trackers{id} = LK_tracking(i, dres_image, dres, trackers{id});
        end
        
        % process tracking results
        for j = 1:numel(index)
            ind = index(j);
            id = dres_track.id(ind);
            bb = trackers{id}.bb;
            
            dres_one.fr = i;
            dres_one.id = id;
            dres_one.x = bb(1);
            dres_one.y = bb(2);
            dres_one.w = bb(3) - bb(1);
            dres_one.h = bb(4) - bb(2);
            dres_one.r = 1;
            dres_one.state = 1;
            dres_track.state(ind) = 0;
            dres_track = concatenate_dres(dres_track, dres_one);
            
            % update LK tracker
            trackers{id} = LK_update(i, trackers{id});
        end        
    end   

    % show tracking results
    if is_show
        figure(1);
        % show ground truth
        subplot(2, 2, 1);
        show_dres(i, I, 'GT', dres_gt);

        % show detections
        subplot(2, 2, 2);
        show_dres(i, I, 'Detections', dres_det);        

        % show tracking results
        subplot(2, 2, 3);
        show_dres(i, I, 'Tracking', dres_track);        

        % show lost targets
        subplot(2, 2, 4);

        pause();
    end
end

% save results
filename = sprintf('%s/%s.mat', opt.results, seq_name);
save(filename, 'dres_track');

% write tracking results
filename = sprintf('%s/%s.txt', opt.results, seq_name);
fprintf('write results: %s\n', filename);
write_tracking_results(filename, dres_track, opt.tracked);

% evaluation
benchmark_dir = fullfile(opt.mot, opt.mot2d, seq_set, filesep);
evaluateTracking({seq_name}, opt.results, benchmark_dir);