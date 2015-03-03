% update the weights of q function
function tracker = MDP_update(tracker, difference, f)

if tracker.prev_state == 1
    tracker.w_active = tracker.w_active + tracker.alpha * difference .* f;
    fnum = tracker.fnum_active;
    weights = tracker.w_active;
    type = 'active';
end

if tracker.prev_state == 2
    tracker.w_tracked = tracker.w_tracked + tracker.alpha * difference .* f;
    fnum = tracker.fnum_tracked;
    weights = tracker.w_tracked;
    type = 'tracked';
end

if tracker.prev_state == 3
    tracker.w_occluded = tracker.w_occluded + tracker.alpha * difference .* f;
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