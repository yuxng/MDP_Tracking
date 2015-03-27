% MDP value function
function [tracker, qscore, f] = MDP_value(tracker, frame_id, dres_image, dres_det, index_det)

% association
if isempty(index_det) == 1
    qscore = 0;
    label = -1;
    f = [];
else
    % extract features with LK association
    dres = sub(dres_det, index_det);
    [features, flag] = MDP_feature(frame_id, dres_image, dres, tracker);

    m = size(features, 1);
    labels = -1 * ones(m, 1);
    if tracker.state == 2
        w = tracker.w_tracked;
    else
        w = tracker.w_occluded;
    end
    [labels, ~, probs] = svmpredict(labels, features, w, '-b 1 -q');

    probs(flag == 0, 1) = 0;
    probs(flag == 0, 2) = 1;
    labels(flag == 0) = -1;

    [qscore, ind] = max(probs(:,1));
    label = labels(ind);
    f = features(ind,:);

    dres_one = sub(dres_det, index_det(ind));
    tracker = LK_associate(frame_id, dres_image, dres_one, tracker);
    dres = dres_one;
end

% make a decision
tracker.prev_state = tracker.state;
if label > 0
    tracker.state = 2;
    % build the dres structure
    dres_one.fr = frame_id;
    dres_one.id = tracker.target_id;
    dres_one.x = tracker.bb(1);
    dres_one.y = tracker.bb(2);
    dres_one.w = tracker.bb(3) - tracker.bb(1);
    dres_one.h = tracker.bb(4) - tracker.bb(2);
    dres_one.r = 1;
    dres_one.state = 2;
    tracker.dres = concatenate_dres(tracker.dres, dres_one);
    % update LK tracker
    tracker = LK_update(frame_id, tracker, dres_image.Igray{frame_id}, dres);           
else
    tracker.state = 3;
    dres_one = sub(tracker.dres, numel(tracker.dres.fr));
    dres_one.fr = frame_id;
    dres_one.id = tracker.target_id;
    dres_one.state = 3;
    tracker.dres = concatenate_dres(tracker.dres, dres_one);          
end

if tracker.is_show
    fprintf('qscore %.2f\n', qscore);
end