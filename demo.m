function demo

opt = globals();

is_train = 1;
seq_idx = 1;

if is_train
    seq_name = opt.mot2d_train_seqs{seq_idx};
    seq_num = opt.mot2d_train_nums(seq_idx);
    seq_set = 'train';
else
    seq_name = opt.mot2d_test_seqs{seq_idx};
    seq_num = opt.mot2d_test_nums(seq_idx);
    seq_set = 'test';
end

% read detections
filename = fullfile(opt.mot, opt.mot2d, seq_set, seq_name, 'det', 'det.txt');
fid = fopen(filename, 'r');
% <frame>, <id>, <bb_left>, <bb_top>, <bb_width>, <bb_height>, <conf>, <x>, <y>, <z>
C = textscan(fid, '%d %d %f %f %f %f %f %f %f %f', 'Delimiter', ',');
fclose(fid);

% read ground truth
filename = fullfile(opt.mot, opt.mot2d, seq_set, seq_name, 'gt', 'gt.txt');
fid = fopen(filename, 'r');
% <frame>, <id>, <bb_left>, <bb_top>, <bb_width>, <bb_height>, <conf>, <x>, <y>, <z>
Cgt = textscan(fid, '%d %d %f %f %f %f %f %f %f %f', 'Delimiter', ',');
fclose(fid);

figure(1);
cmap = colormap;
ID = 0;
models = cell(10000, 1);
dres_track = [];

% show detection results
for i = 1:seq_num
    % show image
    filename = fullfile(opt.mot, opt.mot2d, seq_set, seq_name, 'img1', sprintf('%06d.jpg', i));
    disp(filename);
    I = imread(filename);
    
    dres_image.x = 1;
    dres_image.y = 1;
    dres_image.w = size(I, 2);
    dres_image.h = size(I, 1);
    
    subplot(2, 2, 1);
    imshow(I);
    title('GT');
    hold on;
    % show ground truth
    index = find(Cgt{1} == i);
    for j = 1:numel(index)
        x = Cgt{3}(index(j));
        y = Cgt{4}(index(j));
        w = Cgt{5}(index(j));
        h = Cgt{6}(index(j));
        rectangle('Position', [x y w h], 'EdgeColor', 'g', 'LineWidth', 2);
    end
    hold off;
    
    % build the dres structure for network flow tracking
    index = find(C{1} == i);
    dres.x = C{3}(index);
    dres.y = C{4}(index);
    dres.w = C{5}(index);
    dres.h = C{6}(index);
    dres.r = C{7}(index);
    dres.fr = i * ones(numel(index), 1);
    dres.status = ones(numel(index), 1);  % 0 inactive 1 association 2 online
    dres.id = -1 * ones(numel(index), 1);
    dres.lost = zeros(numel(index), 1);
    dres.tracked = zeros(numel(index), 1);
    
    % nms
    bbox = [dres.x dres.y dres.x+dres.w dres.y+dres.h dres.r];
    index_nms = nms(bbox, 0.5);
    dres = sub(dres, index_nms);
    
    % remove truncated detections
    index_trunc = find(dres.x > 0 & dres.y > 0);
    dres = sub(dres, index_trunc);
    
    % apply online model
    dres_online_all = [];
    if isempty(dres_track) == 0
        index = find(dres_track.status == 2);
        for j = 1:numel(index)
            id = dres_track.id(index(j));
            if isempty(models{id}) == 0
                [track_res, min_err, model_new] = L1APG_track_frame(I, models{id});
                rect = aff2image(track_res, models{id}.para.sz_T);
                inp	= reshape(rect, 2, 4);
                dres_online.x = inp(2,1);
                dres_online.y = inp(1,1);
                dres_online.w = inp(2,4) - inp(2,1); 
                dres_online.h = inp(1,4) - inp(1,1);
                dres_online.r = min_err;
                dres_online.fr = i;
                dres_online.status = 2;
                dres_online.id = id;
                dres_online.lost = 0;
                dres_online.tracked = dres_track.tracked(index(j))+1;

                % check if outside image
                [~, ov] = calc_overlap(dres_online, 1, dres_image, 1);
                
                % check if the online detection is good or not
                if min_err > opt.min_err_threshold
                    if ov < opt.exit_threshold
                        dres_track.status(index(j)) = 0;  % end the track
                        fprintf('target %d exit\n', id);
                    else                    
                        dres_track.status(index(j)) = 1;
                        fprintf('target %d end online\n', id);
                    end
                else
                    models{id} = model_new;
                    if ov < opt.exit_threshold
                        dres_online.status = 0;  % end the track
                        fprintf('target %d exit\n', id);
                    end
                    if isempty(dres_online_all) == 1
                        dres_online_all = dres_online;
                    else
                        dres_online_all = concatenate_dres(dres_online_all, dres_online);
                    end
                    dres_track.status(index(j)) = 0;
                end
            end
        end
        
        % show online detections
        subplot(2, 2, 2);
        imshow(I);
        title('Online Detections');
        hold on;
        if isempty(dres_online_all) == 0
            for j = 1:numel(dres_online_all.x)
                x = dres_online_all.x(j);
                y = dres_online_all.y(j);
                w = dres_online_all.w(j);
                h = dres_online_all.h(j);
                r = dres_online_all.r(j);
                rectangle('Position', [x y w h], 'EdgeColor', 'g', 'LineWidth', 2);
                text(x, y, sprintf('%.2f', r), 'BackgroundColor',[.7 .9 .7]);
            end
        end
        hold off;         
    end
    
    % suppress detections covered by online prediction
    if isempty(dres_online_all) == 0
        flag = zeros(numel(dres.x),1);
        for j = 1:numel(dres.x)
            [overlap, ov1] = calc_overlap(dres, j, dres_online_all, 1:numel(dres_online_all.x));
            if max(overlap) > 0.5 || max(ov1) > 0.9
                flag(j) = 1;
            end
        end
        index = find(flag == 0);
        dres = sub(dres, index);
    end
    
    % show detections
    subplot(2, 2, 3);
    imshow(I);
    title('Offline Detections');
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
    
    if i == 1
        dres_track = dres;
        for j = 1:numel(dres.x)
            ID = ID + 1;
            dres_track.id(j) = ID;
            dres_track.tracked(j) = 1;
            % build appearance model for the initial targets
            x1 = dres_track.x(j);
            y1 = dres_track.y(j);
            x2 = dres_track.x(j) + dres_track.w(j);
            y2 = dres_track.y(j) + dres_track.h(j);
            models{ID} = L1APG_initialize(I, x1, y1, x2, y2);           
        end
    else
        if isempty(dres) == 1 || isempty(dres.x) == 1  % no incoming detection
            index = find(dres_track.status == 1);
            for j = 1:numel(index)
                dres_track.lost(index(j)) = dres_track.lost(index(j)) + 1;
                if dres_track.lost(index(j)) > opt.lost
                    dres_track.status(index(j)) = 0;
                end
            end
        elseif isempty(find(dres_track.status == 1)) == 1 % no active tracks
            for j = 1:numel(dres.x)
                ID = ID + 1;
                dres.id(j) = ID;
                dres.tracked(j) = 1;
                % build appearance model for the targets
                x1 = dres_track.x(j);
                y1 = dres_track.y(j);
                x2 = dres_track.x(j) + dres_track.w(j);
                y2 = dres_track.y(j) + dres_track.h(j);
                models{ID} = L1APG_initialize(I, x1, y1, x2, y2);                    
            end
            dres_track = concatenate_dres(dres_track, dres);
        else
            % network flow tracking
            dres_track = concatenate_dres(dres_track, dres);
            dres_track_tmp = tracking(I, dres_track, models);

            % process tracking results
            index = find(dres_track.status == 1);
            ids = unique(dres_track_tmp.id);
            % for each track
            for j = 1:numel(ids)
                if ids(j) == -1  % unmatched detection
                    index_unmatched = find(dres_track_tmp.id == -1);
                    for k = 1:numel(index_unmatched)
                        ID = ID + 1;
                        dres_track.id(index(index_unmatched(k))) = ID;
                        dres_track.tracked(index(index_unmatched(k))) = 1;
                        % build appearance model for the targets
                        x1 = dres_track.x(index(index_unmatched(k)));
                        y1 = dres_track.y(index(index_unmatched(k)));
                        x2 = dres_track.x(index(index_unmatched(k))) + dres_track.w(index(index_unmatched(k)));
                        y2 = dres_track.y(index(index_unmatched(k))) + dres_track.h(index(index_unmatched(k)));
                        models{ID} = L1APG_initialize(I, x1, y1, x2, y2);                         
                    end
                else
                    matched = find(dres_track_tmp.id == ids(j));
                    if numel(matched) == 1  % unmatched track
                        dres_track.lost(index(matched)) = dres_track.lost(index(matched)) + 1;
                        if dres_track.lost(index(matched)) > opt.lost
                            dres_track.status(index(matched)) = 0;
                        end
                    else  % matched track and detection
                        ind1 = index(matched(1));
                        ind2 = index(matched(2));
                        dres_track.id(ind2) = dres_track.id(ind1);
                        dres_track.status(ind1) = 0;
                        dres_track.tracked(ind2) = dres_track.tracked(ind1) + 1;

                        % re-initialize the online model
                        id = dres_track.id(ind2);
                        x1 = dres_track.x(ind2);
                        y1 = dres_track.y(ind2);
                        x2 = dres_track.x(ind2) + dres_track.w(ind2);
                        y2 = dres_track.y(ind2) + dres_track.h(ind2);
                        models{id} = L1APG_initialize(I, x1, y1, x2, y2);                        
                        if dres_track.tracked(ind2) > opt.tracked
                            % switch to online mode
                            dres_track.status(ind2) = 2;
                        end
                    end
                end
            end
        end
        
        % add online tracks
        dres_track = concatenate_dres(dres_track, dres_online_all);
    end
    
    % show tracking results
    subplot(2, 2, 4);
    imshow(I);
    title('Tracking');
    hold on;
    index = find(dres_track.fr == i);
    for j = 1:numel(index)
        x = dres_track.x(index(j));
        y = dres_track.y(index(j));
        w = dres_track.w(index(j));
        h = dres_track.h(index(j));
        id = dres_track.id(index(j));
        
        index_color = 1 + floor((id-1) * size(cmap,1) / ID);
        rectangle('Position', [x y w h], 'EdgeColor', cmap(index_color,:), 'LineWidth', 2);
        
        text(x, y, sprintf('%d', id), 'BackgroundColor',[.7 .9 .7]);
    end
    hold off;    
    
    pause;
end

% write tracking results
filename = sprintf('%s/%s.txt', opt.results, seq_name);
fprintf('write results: %s\n', filename);
write_tracking_results(filename, dres_track);

% evaluation
benchmark_dir = fullfile(opt.mot, opt.mot2d, seq_set, filesep);
evaluateTracking({seq_name}, opt.results, benchmark_dir);