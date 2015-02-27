% compute tracks using ground truth
function [dres_track, features] = tracking_oracle(model, dres_gt, dres_track, dres_det, dres_image, opt)

features = zeros(model.fnum, 1);
threshold = 0.4;

% associate tracks with GT
index_track = find(dres_track.state ~= 0);
num = numel(index_track);
match_track = zeros(num, 3);
count_gt = zeros(numel(dres_gt.x), 1);
% for each track
for i = 1:num
    ind = index_track(i);
    index_gt = find(dres_gt.fr == dres_track.fr(ind));
    overlap = calc_overlap(dres_track, ind, dres_gt, index_gt);
    [o, ind_gt] = max(overlap);
    if o > threshold
        match_track(i,:) = [index_gt(ind_gt) double(dres_gt.id(index_gt(ind_gt))) o];
        count_gt(index_gt(ind_gt)) = count_gt(index_gt(ind_gt)) + 1;
    end
end
% resolve conflict assignment
index_gt = find(count_gt > 1);
for i = 1:numel(index_gt)
    index = find(match_track(:,1) == index_gt(i));
    overlap = match_track(index,3);
    [~, ind] = max(overlap);
    for j = 1:numel(index)
        if j ~= ind
            match_track(index(j),:) = [0 0 0];
        end
    end
end

% associate detections with GT
num = numel(dres_det.x);
match_det = zeros(num, 3);
count_gt = zeros(numel(dres_gt.x), 1);
% for each detection
for i = 1:num
    index_gt = find(dres_gt.fr == dres_det.fr(i));
    overlap = calc_overlap(dres_det, i, dres_gt, index_gt);
    [o, ind_gt] = max(overlap);
    if o > threshold
        match_det(i,:) = [index_gt(ind_gt) double(dres_gt.id(index_gt(ind_gt))) o];
        count_gt(index_gt(ind_gt)) = count_gt(index_gt(ind_gt)) + 1;
    end
end
% resolve conflict assignment
index_gt = find(count_gt > 1);
for i = 1:numel(index_gt)
    index = find(match_det(:,1) == index_gt(i));
    overlap = match_det(index,3);
    [~, ind] = max(overlap);
    for j = 1:numel(index)
        if j ~= ind
            match_det(index(j),:) = [0 0 0];
        end
    end
end

% build the new tracks
for i = 1:size(match_track,1)
    ind = index_track(i);
    if match_track(i,1) == 0  % unmatched track
        dres_track.lost(ind) = dres_track.lost(ind) + 1;
        if dres_track.lost(ind) > opt.lost
            dres_track.state(ind) = 0;
            fprintf('target %d ended\n', dres_track.id(ind));
        else
            dres_track.state(ind) = 2;
            fprintf('target %d lost\n', dres_track.id(ind));
        end
    else
        id = match_track(i,2);
        ind_det = find(match_det(:,2) == id);
        if isempty(ind_det) == 1  % unmatched track
            dres_track.lost(ind) = dres_track.lost(ind) + 1;
            if dres_track.lost(ind) > opt.lost
                dres_track.state(ind) = 0;
                fprintf('target %d ended\n', dres_track.id(ind));
            else
                dres_track.state(ind) = 2;
                fprintf('target %d lost\n', dres_track.id(ind));
            end
            
            % update features
            features(model.f_start) = features(model.f_start) + 1;
            features(model.f_end) = features(model.f_end) + 1;
            features(model.f_det) = features(model.f_det) + dres_track.r(ind);
            features(model.f_cover) = features(model.f_cover) + dres_track.covers(ind);
            features(model.f_bias) = features(model.f_bias) + 1;
        else  % matched track and detection
            fprintf('target %d matched with detection %f\n', ...
                dres_track.id(ind), dres_det.r(ind_det));
            
            dres_det.id(ind_det) = dres_track.id(ind);
            dres_det.lost(ind_det) = 0;
            dres_det.tracked(ind_det) = dres_track.tracked(ind) + 1;
            dres_det.state(ind_det) = 1;
            dres_track.state(ind) = 0;
            
            % update features
            features(model.f_start) = features(model.f_start) + 1;
            features(model.f_end) = features(model.f_end) + 1;
            features(model.f_det) = features(model.f_det) + dres_track.r(ind) + dres_det.r(ind_det);
            features(model.f_cover) = features(model.f_cover) + dres_track.covers(ind) + dres_det.covers(ind_det);
            features(model.f_bias) = features(model.f_bias) + 2;
            % compute pairwise features
            % overlap between detection and track
            overlap = calc_overlap(dres_track, ind, dres_det, ind_det);
            features(model.f_overlap) = features(model.f_overlap) + overlap;
            % distance between detection and track
            ctrack = apply_motion_prediction(dres_image.fr, dres_track, dres_track.id(ind));
            cdet = dres_det.centers{ind_det};
            distance = -norm(ctrack-cdet) / dres_image.h;
            features(model.f_distance) = features(model.f_distance) + distance;
            % aspect ratio between detection and track
            ratio = dres_track.h(ind) ./ dres_det.h(ind_det);
            ratio  = min(ratio, 1/ratio);
            features(model.f_ratio) = features(model.f_ratio) + ratio;
            % chi square distance between color histogram
            chisq = -distChiSq(dres_track.hists{ind}, dres_det.hists{ind_det});
            features(model.f_color) = features(model.f_color) + chisq;
            % reconstruction error
            id = dres_det.id(ind_det);
            x1 = dres_det.x(ind_det);
            y1 = dres_det.y(ind_det);
            x2 = dres_det.x(ind_det) + dres_det.w(ind_det);
            y2 = dres_det.y(ind_det) + dres_det.h(ind_det);            
            err = 1 - L1APG_reconstruction_error(dres_image.I, model.templates{id}, x1, y1, x2, y2);
            features(model.f_recon) = features(model.f_recon) + err;
        end
    end
end
% add new detections
ID = max(dres_track.id);
for i = 1:size(match_det,1)
    if match_det(i,1) ~= 0 && dres_det.id(i) == -1
        ID = ID + 1;
        dres_det.id(i) = ID;
        dres_det.tracked(i) = 1;
        dres_det.state(i) = 1;  
        fprintf('target %d enter\n', ID);
        
        % update features
        features(model.f_start) = features(model.f_start) + 1;
        features(model.f_end) = features(model.f_end) + 1;
        features(model.f_det) = features(model.f_det) + dres_det.r(i);
        features(model.f_cover) = features(model.f_cover) + dres_det.covers(i);
        features(model.f_bias) = features(model.f_bias) + 1;
    end
end
index = find(dres_det.id ~= -1);
dres = sub(dres_det, index);
dres_track = concatenate_dres(dres_track, dres);