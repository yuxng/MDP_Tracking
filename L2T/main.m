function main

opt = globals();

is_train = 1;
if is_train
    model = model_initialize();
else
    fprintf('load model\n');
    object = load('model.mat');
    model = object.model;
end

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
fid = fopen(filename, 'r');
% <frame>, <id>, <bb_left>, <bb_top>, <bb_width>, <bb_height>, <conf>, <x>, <y>, <z>
C = textscan(fid, '%d %d %f %f %f %f %f %f %f %f', 'Delimiter', ',');
fclose(fid);

% build the dres structure for detections
dres_det.fr = C{1};
dres_det.id = C{2};
dres_det.x = C{3};
dres_det.y = C{4};
dres_det.w = C{5};
dres_det.h = C{6};
dres_det.r = C{7} / opt.det_normalization;
num_det = numel(dres_det.fr);
dres_det.state = zeros(num_det, 1);
dres_det.lost = zeros(num_det, 1);
dres_det.tracked = zeros(num_det, 1);

% read ground truth
filename = fullfile(opt.mot, opt.mot2d, seq_set, seq_name, 'gt', 'gt.txt');
fid = fopen(filename, 'r');
% <frame>, <id>, <bb_left>, <bb_top>, <bb_width>, <bb_height>, <conf>, <x>, <y>, <z>
Cgt = textscan(fid, '%d %d %f %f %f %f %f %f %f %f', 'Delimiter', ',');
fclose(fid);

% build the dres structure for ground truth
dres_gt.fr = Cgt{1};
dres_gt.id = Cgt{2};
dres_gt.x = Cgt{3};
dres_gt.y = Cgt{4};
dres_gt.w = Cgt{5};
dres_gt.h = Cgt{6};
dres_gt.r = Cgt{7};

if is_show
    figure(1);
    cmap = colormap;
end

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
    % compute features
    % dres = model_compute_features(dres, dres_image);
    num_det = numel(index);    

    % show ground truth
    if is_show
        figure(1);
        subplot(2, 2, 1);
        imshow(I);
        title('GT');
        hold on;
        index = find(dres_gt.fr == i);
        for j = 1:numel(index)
            x = dres_gt.x(index(j));
            y = dres_gt.y(index(j));
            w = dres_gt.w(index(j));
            h = dres_gt.h(index(j));
            rectangle('Position', [x y w h], 'EdgeColor', 'g', 'LineWidth', 2);
        end
        hold off;
    end

    % show detections
    if is_show
        figure(1);
        subplot(2, 2, 2);
        imshow(I);
        title('Detections');
        hold on;    
        for j = 1:numel(dres.x)
            x = dres.x(j);
            y = dres.y(j);
            w = dres.w(j);
            h = dres.h(j);
            r = dres.r(j);
            rectangle('Position', [x y w h], 'EdgeColor', 'g', 'LineWidth', 2);
            text(x, y, sprintf('%.2f', r), 'BackgroundColor',[.7 .9 .7]);
        end
        hold off;
    end        

    if i == 1
        fprintf('initialization\n');
        % initialization
        dres_track = dres;
        ID = 0;
        for j = 6%1:num_det
            ID = ID + 1;
            dres_track.id(j) = ID;
            dres_track.tracked(j) = 1;
            dres_track.state(j) = 1;
            % build appearance model for the initial targets
            x1 = dres_track.x(j);
            y1 = dres_track.y(j);
            x2 = dres_track.x(j) + dres_track.w(j);
            y2 = dres_track.y(j) + dres_track.h(j);
            model.templates{ID} = L1APG_initialize(dres_image.Igray{i}, ID, x1, y1, x2, y2);
            model.tlds{ID} = LK_initialize(dres_image.Igray{i}, x1, y1, x2, y2);
            fprintf('target %d enter\n', ID);
        end
    else
        % apply LK trackers
        dres_LK = tracking_LK(model.tlds, dres_track, dres_image, i, opt);

        % show the TLD tracker results
        if is_show
            figure(1);
            subplot(2, 2, 3);
            imshow(I);
            title('LK Tracking');
            hold on;
            for j = 1:numel(dres_LK.x)
                x = dres_LK.x(j);
                y = dres_LK.y(j);
                w = dres_LK.w(j);
                h = dres_LK.h(j);
                id = dres_LK.id(j);
                xFJ = dres_LK.xFJ{j};
                index_color = min(1 + floor((id-1) * size(cmap,1) / max(dres_track.id)), size(cmap,1));
                rectangle('Position', [x y w h], 'EdgeColor', cmap(index_color,:), 'LineWidth', 2);
                text(x, y, sprintf('%d', id), 'BackgroundColor',[.7 .9 .7]);
                plot(xFJ(1,:), xFJ(2,:), 'gs', 'MarkerSize', 5);
                % show the previous path
                ind = find(dres_track.id == id);
                centers = [dres_track.x(ind)+dres_track.w(ind)/2 ...
                    dres_track.y(ind)+dres_track.h(ind)/2];
                plot(centers(:,1), centers(:,2), 'LineWidth', 2, 'Color', cmap(index_color,:));
            end
            hold off;
        end
        
        % process tracking results
        index = find(dres_track.state ~= 0);
        for j = 1:numel(index)
            dres_track.state(index(j)) = 0;
        end
        dres_track = concatenate_dres(dres_track, dres_LK);
    end   

    % show tracking results
    if is_show
        figure(1);
        subplot(2, 2, 4);
        imshow(I);
        title('Tracking');
        hold on;
        index = find(dres_track.fr == i & dres_track.state == 1);
        for j = 1:numel(index)
            x = dres_track.x(index(j));
            y = dres_track.y(index(j));
            w = dres_track.w(index(j));
            h = dres_track.h(index(j));
            id = dres_track.id(index(j));
            index_color = min(1 + floor((id-1) * size(cmap,1) / max(dres_track.id)), size(cmap,1));
            rectangle('Position', [x y w h], 'EdgeColor', cmap(index_color,:), 'LineWidth', 2);
            text(x, y, sprintf('%d', id), 'BackgroundColor',[.7 .9 .7]);
            % show the previous path
            ind = find(dres_track.id == id);
            centers = [dres_track.x(ind)+dres_track.w(ind)/2 ...
                dres_track.y(ind)+dres_track.h(ind)/2];
            plot(centers(:,1), centers(:,2), 'LineWidth', 2, 'Color', cmap(index_color,:));        
        end
        hold off;    
    end

    if is_show
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

% save model
if is_train
    model.tlds = cell(model.MAX_ID, 1);
    save('model.mat', 'model');
end