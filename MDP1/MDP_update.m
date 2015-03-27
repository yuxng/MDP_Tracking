% update the weights of q function
function tracker = MDP_update(tracker, difference, f)

if tracker.prev_state == 2
    tracker.w_tracked = max(tracker.w_tracked + tracker.alpha * difference .* f, 0);
    fnum = tracker.fnum_tracked;
    weights = tracker.w_tracked;
    type = 'tracked';
end

if tracker.prev_state == 3
    tracker.w_occluded = max(tracker.w_occluded + tracker.alpha * difference .* f, 0);
    fnum = tracker.fnum_occluded;
    weights = tracker.w_occluded;
    type = 'occluded';
end

fprintf('difference = %.2f\n', difference);
fprintf('features %s ', type);
for i = 1:fnum
    fprintf('%f ', f(i));
end
fprintf('\n');
fprintf('weights %s ', type);
for i = 1:fnum
    fprintf('%f ', weights(i));
end
fprintf('\n');