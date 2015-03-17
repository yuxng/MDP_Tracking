% MDP value function
function [tracker, qscore, f] = MDP_value(tracker, frame_id, dres_image, dres_det, index_det, opt)

% active, decide to tracked or inactive
if tracker.state == 1    
    % extract features
    dres_one = sub(dres_det, index_det);
    f = MDP_feature_active(tracker, dres_one);
    qscore = 1;
    % prediction
    label = svmpredict(1, f, tracker.w_active);
    % make a decision
    if label > 0
        tracker.state = 2;
    else
        tracker.state = 0;
    end
    tracker.prev_state = 1;
    % build the dres structure
    tracker.dres = dres_one;
    tracker.dres.id = tracker.target_id;
    tracker.dres.state = tracker.state;

% tracked, decide to tracked or occluded
elseif tracker.state == 2
    % extract features with LK tracking
    [tracker, f] = MDP_feature_tracked(frame_id, dres_image, dres_det, tracker, opt);
    % compute qscore
    if isempty(find(tracker.flags ~= 2, 1)) == 1
        label = -1;
        qscore = 0;
    else
        [label, ~, prob] = svmpredict(1, f, tracker.w_tracked, '-b 1');
        qscore = prob(1);
    end
    fprintf('qscore in tracked %.2f\n', qscore);
    % make a decision
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
        tracker = LK_update(frame_id, tracker, dres_image.Igray{frame_id}, dres_det);
    else
        tracker.state = 3;
        dres_one = sub(tracker.dres, numel(tracker.dres.fr));
        dres_one.fr = frame_id;
        dres_one.id = tracker.target_id;
        dres_one.state = 3;
        tracker.dres = concatenate_dres(tracker.dres, dres_one);        
    end
    tracker.prev_state = 2;

% occluded, decide to tracked or occluded
elseif tracker.state == 3
    if isempty(index_det) == 1
        qscore = 0;
        label = -1;
        f = [];
    else
        % extract features with LK association
        dres = sub(dres_det, index_det);
        [features, flag] = MDP_feature_occluded(frame_id, dres_image, dres, tracker, opt);
        
        m = size(features, 1);
        labels = -1 * ones(m, 1);
        [labels, ~, probs] = svmpredict(labels, features, tracker.w_occluded, '-b 1');
        
        probs(flag == 0, 1) = 0;
        probs(flag == 0, 2) = 1;
        labels(flag == 0) = -1;
        
        [qscore, ind] = max(probs(:,1));
        label = labels(ind);
        f = features(ind,:);
        
        dres_one = sub(dres_det, index_det(ind));
        tracker = LK_associate(frame_id, dres_image, dres_one, tracker, opt);
        dres = dres_one;
    end
    
    fprintf('qscore in lost %.2f\n', qscore);
    % make a decision
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
    tracker.prev_state = 3;
end