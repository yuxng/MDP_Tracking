% find detections for initialization
function dres_all = generate_results(trackers)

% collect dres from trackers
dres_all = [];
for i = 1:numel(trackers)
    tracker = trackers{i};
    
    if isempty(dres_all)
        dres_all = tracker.dres;
    else
        dres_all = concatenate_dres(dres_all, tracker.dres);
    end
end