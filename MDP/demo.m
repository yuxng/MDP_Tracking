function demo

opt = globals();

is_train = 1;
seq_idx = 1;
is_show = 1;

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

if is_show
    figure(1);
    cmap = colormap;
end
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
    
    % show ground truth
    if is_show
        subplot(2, 3, 1);
        imshow(I);
        title('GT');
        hold on;
        index = find(Cgt{1} == i);
        for j = 1:numel(index)
            x = Cgt{3}(index(j));
            y = Cgt{4}(index(j));
            w = Cgt{5}(index(j));
            h = Cgt{6}(index(j));
            rectangle('Position', [x y w h], 'EdgeColor', 'g', 'LineWidth', 2);
        end
        hold off;
    end
    
    % show detections
%     subplot(2, 3, 2);
%     imshow(I);
%     title('Detections');
%     hold on;
%     index = find(C{1} == i);
%     for j = 1:numel(index)
%         x = C{3}(index(j));
%         y = C{4}(index(j));
%         w = C{5}(index(j));
%         h = C{6}(index(j));
%         r = C{7}(index(j));
%         rectangle('Position', [x y w h], 'EdgeColor', 'g', 'LineWidth', 2);
%         text(x, y, sprintf('%.2f', r), 'BackgroundColor',[.7 .9 .7]);
%     end
%     hold off;    
    
    % build the dres structure for network flow tracking
    index = find(C{1} == i);
    dres.x = C{3}(index);
    dres.y = C{4}(index);
    dres.w = C{5}(index);
    dres.h = C{6}(index);
    dres.r = C{7}(index);
    dres.fr = i * ones(numel(index), 1);
    dres.status = ones(numel(index), 1);  % 0 inactive 1 association 2 online 3 occluded
    dres.id = -1 * ones(numel(index), 1);
    dres.lost = zeros(numel(index), 1);    % in streak
    dres.tracked = zeros(numel(index), 1); % in streak
    
    % show detections
    if is_show
        subplot(2, 3, 2);
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
    
    % thresholding
    % index_threshold = find(dres.r > opt.det_threshold);
    % dres = sub(dres, index_threshold);
    
    % nms
    bbox = [dres.x dres.y dres.x+dres.w dres.y+dres.h dres.r];
    index_nms = nms_new(bbox, 0.6);
    dres = sub(dres, index_nms);
    
    % apply online model
    dres_online_all = [];
    if isempty(dres_track) == 0
        index = find(dres_track.status == 2);
        for j = 1:numel(index)
            id = dres_track.id(index(j));
            if isempty(models{id}) == 0
                [track_res, min_err, models{id}] = L1APG_track_frame(I, models{id});
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
                if ov < opt.exit_threshold
                    dres_online.status = 0;  % end the track
                    fprintf('target %d exit from online\n', id);
                end                
                
                % check if the online detection is good or not
                if min_err > opt.min_err_threshold
                    dres_online.status = 1;
                    fprintf('target %d end online\n', id);
                end
                
                if isempty(dres_online_all) == 1
                    dres_online_all = dres_online;
                else
                    dres_online_all = concatenate_dres(dres_online_all, dres_online);
                end
                dres_track.status(index(j)) = 0;
            end
        end
        
        % show online detections
        if is_show
            subplot(2, 3, 3);
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
    end
    
    if isempty(dres_online_all) == 0
        % occlusion reasoning between online tracked targets
        occ = reason_occlusions(I, dres_online_all, models);
        for j = 1:size(occ,1)
            if sum(occ(j,:)) > 0
                dres_online_all.status(j) = 4;
                fprintf('target %d occluded (hold)\n', dres_online_all.id(j));
            end
        end
        
        % use detection to update the online model
        x1 = dres.x;
        y1 = dres.y;
        x2 = dres.x + dres.w;
        y2 = dres.y + dres.h;
        flag = zeros(numel(dres.x),1);
        for j = 1:size(occ,1)
            overlap = calc_overlap(dres_online_all, j, dres, 1:numel(dres.x));
            ind = find(overlap > 0.5);
            if isempty(ind) == 0
                id = dres_online_all.id(j);
                [models{id}, tmp] = L1APG_update(I, models{id}, x1(ind), y1(ind), x2(ind), y2(ind));
                fprintf('Online target %d updated by detection with conf %.2f among %d detections\n', ...
                    id, dres.r(ind(tmp)), numel(ind));
                models{id}.lost = 0;
                flag(ind(tmp)) = 1;
            else
                id = dres_online_all.id(j);
                fprintf('No detection for online target %d\n', id);
                models{id}.lost = models{id}.lost + 1;
                if models{id}.lost  > opt.lost_online
                    dres_online_all.status(j) = 1;
                    fprintf('target %d exit online mode\n', id);
                end
            end
        end        
        
        % suppress detections covered by online prediction
        for j = 1:numel(dres.x)
            % only suppress unconfident detections
            if dres.r(j) < opt.det_confident
                [overlap, ov1, ov2] = calc_overlap(dres, j, dres_online_all, 1:numel(dres_online_all.x));
                if isempty(find(overlap > 0.6 | ov1 > 0.95 | ov2 > 0.95 | sum(ov1) > 0.6)) == 0
                    flag(j) = 1;
                end
            end
        end
        index = find(flag == 0);
        dres = sub(dres, index);
    end
    
    % show detections
    if is_show
        subplot(2, 3, 4);
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
    end
    
    if i == 1
        % initialization
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
            models{ID} = L1APG_initialize(I, ID, x1, y1, x2, y2);
            fprintf('target %d enter\n', ID);
        end
    else
        if isempty(dres) == 1 || isempty(dres.x) == 1  % no incoming detection
            index = find(dres_track.status == 1 | dres_track.status == 4);
            for j = 1:numel(index)
                fprintf('target %d unmatched due to no detection\n', dres_track.id(index(j)));
                dres_track.lost(index(j)) = dres_track.lost(index(j)) + 1;
                % check if target exit
                id = dres_track.id(index(j));
                x1 = models{id}.prediction(1) - dres_track.w(index(j))/2;
                y1 = models{id}.prediction(2) - dres_track.h(index(j))/2;
                x2 = models{id}.prediction(1) + dres_track.w(index(j))/2;
                y2 = models{id}.prediction(2) + dres_track.h(index(j))/2;
                if x1 < 0 || y1 < 0 || x2 > size(I,2) || y2 > size(I,1)
                    dres_track.status(index(j)) = 0;  % end target
                    fprintf('target %d exit from matching\n', id);
                    if dres_track.tracked(index(j)) < opt.tracked
                        fprintf('target %d is tracked less than %d frames\n', id, opt.tracked);
                    end                    
                else
                    if dres_track.lost(index(j)) > opt.lost && dres_track.status(index(j)) ~= 4
                        dres_track.status(index(j)) = 0;
                        fprintf('target %d ended\n', id);
                        % check if removing the target
                        if dres_track.tracked(index(j)) < opt.tracked
                            fprintf('target %d is tracked less than %d frames\n', id, opt.tracked);
                        end
                    end
                end
            end
        elseif isempty(find(dres_track.status == 1 | dres_track.status == 4)) == 1 % no active tracks
            for j = 1:numel(dres.x)
                ID = ID + 1;
                dres.id(j) = ID;
                dres.tracked(j) = 1;
                % build appearance model for the targets
                x1 = dres_track.x(j);
                y1 = dres_track.y(j);
                x2 = dres_track.x(j) + dres_track.w(j);
                y2 = dres_track.y(j) + dres_track.h(j);
                models{ID} = L1APG_initialize(I, ID, x1, y1, x2, y2);
                fprintf('target %d enter\n', ID);
            end
            dres_track = concatenate_dres(dres_track, dres);
        else
            % network flow tracking
            dres_track = concatenate_dres(dres_track, dres);
            dres_track_tmp = tracking(I, dres_track, models, opt);

            % process tracking results
            index = find(dres_track.status == 1 | dres_track.status == 4);
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
                        models{ID} = L1APG_initialize(I, ID, x1, y1, x2, y2);
                        fprintf('target %d enter\n', ID);
                    end
                else
                    matched = find(dres_track_tmp.id == ids(j));
                    if numel(matched) == 1  % unmatched track
                        fprintf('target %d unmatched\n', dres_track.id(index(matched)));
                        % check if target exit
                        id = dres_track.id(index(matched));
                        x1 = models{id}.prediction(1) - dres_track.w(index(matched))/2;
                        y1 = models{id}.prediction(2) - dres_track.h(index(matched))/2;
                        x2 = models{id}.prediction(1) + dres_track.w(index(matched))/2;
                        y2 = models{id}.prediction(2) + dres_track.h(index(matched))/2;
                        if x1 < 0 || y1 < 0 || x2 > size(I,2) || y2 > size(I,1)
                            dres_track.status(index(matched)) = 0;  % end target
                            fprintf('target %d exit from matching\n', id);
                            if dres_track.tracked(index(matched)) < opt.tracked
                                fprintf('target %d is tracked less than %d frames\n', id, opt.tracked);
                            end                            
                        else                        
                            % target lost
                            dres_track.lost(index(matched)) = dres_track.lost(index(matched)) + 1;
                            if dres_track.lost(index(matched)) > opt.lost && dres_track.status(index(matched)) ~= 4
                                dres_track.status(index(matched)) = 0;  % end target
                                fprintf('target %d ended\n', dres_track.id(index(matched)));
                                % check if removing the target
                                if dres_track.tracked(index(matched)) < opt.tracked
                                    fprintf('target %d is tracked less than %d frames\n', id, opt.tracked);
                                end
                            end
                        end
                    else  % matched track and detection
                        ind1 = index(matched(1));
                        ind2 = index(matched(2));
                        dres_track.id(ind2) = dres_track.id(ind1);
                        dres_track.status(ind1) = 0;
                        dres_track.tracked(ind2) = dres_track.tracked(ind1) + 1;
                        dres_track.lost(ind2) = 0;
                        dres_track.status(ind2) = 1;
                        fprintf('target %d matched\n', dres_track.id(ind2));

                        % re-initialize the online model
                        id = dres_track.id(ind2);
                        x1 = dres_track.x(ind2);
                        y1 = dres_track.y(ind2);
                        x2 = dres_track.x(ind2) + dres_track.w(ind2);
                        y2 = dres_track.y(ind2) + dres_track.h(ind2);
                        models{id} = L1APG_initialize(I, id, x1, y1, x2, y2);
                        if dres_track.tracked(ind2) > opt.tracked
                            % switch to online mode
                            dres_track.status(ind2) = 2;
                            fprintf('target %d switch to online mode\n', id);
                        end
                    end
                end
            end
        end
        
        % add online tracks
        dres_track = concatenate_dres(dres_track, dres_online_all);
    end
    % apply motion
    models = apply_motion_prediction(i, dres_track, models);
    
    % show tracking results
    if is_show
        subplot(2, 3, 5);
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
            % show the prediction
            plot(x+w/2, y+h/2, 'ro', 'LineWidth', 2);
            plot([x+w/2 models{id}.prediction(1)], [y+h/2 models{id}.prediction(2)], 'LineWidth', 2, 'Color', 'y');
            % show the previous path
            ind = find(dres_track.id == id);
            centers = [dres_track.x(ind)+dres_track.w(ind)/2 ...
                dres_track.y(ind)+dres_track.h(ind)/2];
            plot(centers(:,1), centers(:,2), 'LineWidth', 2, 'Color', cmap(index_color,:));
        end
        hold off;

        % show lost targets
        subplot(2, 3, 6);
        imshow(I);
        title('Lost Tracks');
        hold on;
        index = find(dres_track.fr ~= i & (dres_track.status == 1 | dres_track.status == 4));
        for j = 1:numel(index)
            x = dres_track.x(index(j));
            y = dres_track.y(index(j));
            w = dres_track.w(index(j));
            h = dres_track.h(index(j));
            id = dres_track.id(index(j));
            index_color = 1 + floor((id-1) * size(cmap,1) / ID);
            rectangle('Position', [x y w h], 'EdgeColor', cmap(index_color,:), 'LineWidth', 2);
            text(x, y, sprintf('%d', id), 'BackgroundColor',[.7 .9 .7]);
            % show the prediction
            plot(x+w/2, y+h/2, 'ro', 'LineWidth', 2);
            plot([x+w/2 models{id}.prediction(1)], [y+h/2 models{id}.prediction(2)], 'LineWidth', 2, 'Color', 'y');
            % show the previous path
            ind = find(dres_track.id == id);
            centers = [dres_track.x(ind)+dres_track.w(ind)/2 ...
                dres_track.y(ind)+dres_track.h(ind)/2];
            plot(centers(:,1), centers(:,2), 'LineWidth', 2, 'Color', cmap(index_color,:));        
        end
        hold off;    
    end
    
    if is_show
        pause;
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