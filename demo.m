function demo

opt = globals();

is_train = 1;
seq_idx = 4;

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

% show detection results
for i = 1:seq_num
    % show image
    filename = fullfile(opt.mot, opt.mot2d, seq_set, seq_name, 'img1', sprintf('%06d.jpg', i));
    I = imread(filename);
    
    subplot(1, 3, 1);
    imshow(I);
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
    
    subplot(1, 3, 2);
    imshow(I);
    hold on;    
    
    % show detections
    index = find(C{1} == i);
    for j = 1:numel(index)
        x = C{3}(index(j));
        y = C{4}(index(j));
        w = C{5}(index(j));
        h = C{6}(index(j));
        r = C{7}(index(j));
        rectangle('Position', [x y w h], 'EdgeColor', 'g', 'LineWidth', 2);
        text(x, y, sprintf('%.2f', r), 'BackgroundColor',[.7 .9 .7]);
    end
    hold off;
    
    % build the dres structure for network flow tracking
    dres.x = C{3}(index);
    dres.y = C{4}(index);
    dres.w = C{5}(index);
    dres.h = C{6}(index);
    dres.r = C{7}(index);
    dres.fr = i * ones(numel(index), 1);
    dres.status = ones(numel(index), 1);
    dres.id = -1 * ones(numel(index), 1);
    dres.lost = zeros(numel(index), 1);
    dres.tracked = zeros(numel(index), 1);
    
    % nms
    bbox = [dres.x dres.y dres.x+dres.w dres.y+dres.h dres.r];
    index_nms = nms(bbox, 0.5);
    dres = sub(dres, index_nms);
    
    if i == 1
        dres_track = dres;
        for j = 1:numel(dres.x)
            ID = ID + 1;
            dres_track.id(j) = ID;
            dres_track.tracked(j) = 1;
        end
    else
        % network flow tracking
        dres_track = concatenate_dres(dres_track, dres);
        index = find(dres_track.status == 1);
        dres = sub(dres_track, index);
        dres_track_tmp = tracking(dres);
        
        % process tracking results
        ids = unique(dres_track_tmp.id);
        % for each track
        for j = 1:numel(ids)
            if ids(j) == -1  % unmatched detection
                index_unmatched = find(dres_track_tmp.id == -1);
                for k = 1:numel(index_unmatched)
                    ID = ID + 1;
                    dres_track.id(index(index_unmatched(k))) = ID;
                    dres_track.tracked(index(index_unmatched(k))) = 1;
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
                end
            end
        end
    end
    
    % show tracking results
    subplot(1, 3, 3);
    imshow(I);
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