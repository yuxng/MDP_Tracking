% extract features for tracked state
function [tracker, f] = MDP_feature_tracked(frame_id, dres_image, dres_det, tracker)

% LK tracking
tracker = LK_tracking(frame_id, dres_image, dres_det, tracker);

% extract features
f = zeros(1, tracker.fnum_tracked);

% use mean
f(1) = mean(exp(-tracker.medFBs / tracker.fb_factor));
f(2) = mean(tracker.medNCCs);
f(3) = mean(tracker.bb_overlaps);
f(4) = mean(tracker.nccs);
f(5) = mean(tracker.angles);

if tracker.is_show
    fprintf('ftracked: ');
    for i = 1:numel(f)
        fprintf('%.2f ', f(i));
    end
    fprintf('\n');
end