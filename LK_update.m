% update the LK tracker
function tracker = LK_update(frame_id, tracker, img, dres_det)

% find the template with max FB error
[~, index] = max(tracker.medFBs);

% update
tracker.frame_ids(index) = frame_id;
tracker.x1(index) = tracker.bb(1);
tracker.y1(index) = tracker.bb(2);
tracker.x2(index) = tracker.bb(3);
tracker.y2(index) = tracker.bb(4);
tracker.patterns(:,index) = generate_pattern(img, tracker.bb, tracker.patchsize);

% compute overlap
dres.x = tracker.bb(1);
dres.y = tracker.bb(2);
dres.w = tracker.bb(3) - tracker.bb(1);
dres.h = tracker.bb(4) - tracker.bb(2);
num_det = numel(dres_det.fr);
if isempty(dres_det.fr) == 0
    o = calc_overlap(dres, 1, dres_det, 1:num_det);
    tracker.bb_overlaps(index) = max(o);
else
    tracker.bb_overlaps(index) = 0;
end