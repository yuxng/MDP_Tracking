function main

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

ID = 0;
% show detection results
for i = 1:seq_num
    filename = fullfile(opt.mot, opt.mot2d, seq_set, seq_name, 'img1', sprintf('%06d.jpg', i));
    disp(filename);
    
    % build the dres structure for network flow tracking
    index = find(C{1} == i);
    dres.x = C{3}(index);
    dres.y = C{4}(index);
    dres.w = C{5}(index);
    dres.h = C{6}(index);
    dres.r = C{7}(index);
    dres.fr = i * ones(numel(index), 1);
    dres.status = ones(numel(index), 1);
    dres.id = -1 * ones(numel(index), 1);
    dres.lost = zeros(numel(index), 1);
    
    % nms
    bbox = [dres.x dres.y dres.x+dres.w dres.y+dres.h dres.r];
    index_nms = nms(bbox, 0.5);
    dres = sub(dres, index_nms);
    
    if i == 1
        dres_track = dres;
        for j = 1:numel(index)
            ID = ID + 1;
            dres_track.id(j) = ID;
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
                    ind2= index(matched(2));
                    dres_track.id(ind2) = dres_track.id(ind1);
                    dres_track.status(ind1) = 0;
                end
            end
        end
    end
end

% write tracking results
filename = sprintf('%s/%s.txt', opt.results, seq_name);
fprintf('write results: %s\n', filename);
write_tracking_results(filename, dres_track);

% evaluation
benchmark_dir = fullfile(opt.mot, opt.mot2d, seq_set, filesep);
allMets = evaluateTracking({seq_name}, opt.results, benchmark_dir);