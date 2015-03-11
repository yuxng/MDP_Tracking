% find detections for initialization
function [index_det, dres_all] = generate_initial_index(trackers, dres_det)

if isempty(dres_det) == 1
    index_det = [];
    return;
end

% collect dres from trackers
dres_track = [];
dres_all = [];
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
    
    if isempty(dres_all)
        dres_all = tracker.dres;
    else
        dres_all = concatenate_dres(dres_all, tracker.dres);
    end
end

% compute overlaps
num_det = numel(dres_det.fr);
num_track = numel(dres_track.fr);
if num_track
    overlaps = zeros(num_det, 1);
    for i = 1:num_det
        overlaps(i) = calc_overlap(dres_det, i, dres_track, 1:num_track);
    end
    index_det = find(overlaps < 0.5);
else
    index_det = 1:num_det;
end