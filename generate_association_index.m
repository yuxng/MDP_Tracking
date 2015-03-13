% find detections for association
function index_det = generate_association_index(tracker, frame_id, width, height, dres_det, is_truncated)

ctrack = apply_motion_prediction(frame_id, tracker);

num_det = numel(dres_det.fr);
cdets = [dres_det.x + dres_det.w/2, dres_det.y + dres_det.h/2];

% compute distances and aspect ratios
distances = zeros(num_det, 1);
ratios = zeros(num_det, 1);
for i = 1:num_det
    distances(i) = norm(cdets(i,:) - ctrack);

    ratio = tracker.dres.h(end) / dres_det.h(i);
    ratios(i) = min(ratio, 1/ratio);
end

if is_truncated == 0
    index_det = find(distances < tracker.threshold_dis & ratios > tracker.threshold_ratio & ...
        dres_det.x > 0 & dres_det.y > 0 & dres_det.x+dres_det.w < width & dres_det.y+dres_det.h < height);
else
    index_det = find(distances < tracker.threshold_dis & ratios > tracker.threshold_ratio);
end