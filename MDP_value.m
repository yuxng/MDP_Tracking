% MDP value function
function [tracker, qscore, f] = MDP_value(tracker, frame_id, dres_image, dres_det, index_det)

% active, decide to tracked or inactive
if tracker.state == 1    
    % extract features
    f = zeros(tracker.fnum_active, 1);
    f(1) = dres_det.x(index_det) / tracker.image_width;
    f(2) = dres_det.y(index_det) / tracker.image_height;
    f(3) = dres_det.w(index_det) / tracker.max_width;
    f(4) = dres_det.h(index_det) / tracker.max_height;
    f(5) = dres_det.r(index_det) / tracker.max_score;
    f(6) = 1;
    % compute qscore
    qscore = dot(tracker.w_active, f);
    % make a decision
    if qscore > 0
        tracker.state = 2;
    else
        qscore = -1 * qscore;
        tracker.state = 0;
    end
    tracker.prev_state = 1;
    % build the dres structure
    tracker.dres = sub(dres_det, index_det);
    tracker.dres.id = tracker.target_id;

% tracked, decide to tracked or occluded
elseif tracker.state == 2
    % LK tracking
    tracker = LK_tracking(frame_id, dres_image, dres_det, tracker);
    % extract features
    f = zeros(tracker.fnum_tracked, 1);
    num = tracker.num;
    frame_ids = tracker.frame_ids;
    [~, index] = sort(frame_ids);
    f(1:num) = tracker.medFBs(index);
    f(num+1:2*num) = tracker.medNCCs(index);
    f(2*num+1:3*num) = tracker.overlaps(index);
    f(3*num+1) = 1;
    % compute qscore
    qscore = dot(tracker.w_tracked, f);
    % make a decision
    if qscore > 0
        tracker.state = 2;
        % build the dres structure
        dres_one.fr = frame_id;
        dres_one.id = tracker.target_id;
        dres_one.x = tracker.bb(1);
        dres_one.y = tracker.bb(2);
        dres_one.w = tracker.bb(3) - tracker.bb(1);
        dres_one.h = tracker.bb(4) - tracker.bb(2);
        dres_one.r = 1;
        tracker.dres = concatenate_dres(tracker.dres, dres_one);
        % update LK tracker
        tracker = LK_update(frame_id, tracker);        
    else
        qscore = -1 * qscore;
        tracker.state = 3;
    end
    tracker.prev_state = 2;

% occluded, decide to tracked or occluded
elseif tracker.state == 3
    f = zeros(tracker.fnum_occluded, 1);
    num = tracker.num;
    frame_ids = tracker.frame_ids;
    [~, index] = sort(frame_ids);    
    
    % LK association
    min_value = inf;
    min_index = -1;
    for i = 1:numel(index_det)
        dres_one = sub(dres_det, index_det(i));
        tracker = LK_associate(frame_id, dres_image, dres_one, tracker);
        value = min(tracker.medFBs);
        if  value < min_value
            min_value = value;
            min_index = i;
            % extract features
            f(1:num) = tracker.medFBs(index);
            f(num+1:2*num) = tracker.medNCCs(index);
            f(2*num+1) = 1;
            % compute qscore
            qscore = dot(tracker.w_occluded, f);
        end
    end
    dres_one = sub(dres_det, index_det(min_index));
    tracker = LK_associate(frame_id, dres_image, dres_one, tracker);    
    
    % make a decision
    if qscore > 0
        tracker.state = 2;
        % build the dres structure
        dres_one.fr = frame_id;
        dres_one.id = tracker.target_id;
        dres_one.x = tracker.bb(1);
        dres_one.y = tracker.bb(2);
        dres_one.w = tracker.bb(3) - tracker.bb(1);
        dres_one.h = tracker.bb(4) - tracker.bb(2);
        dres_one.r = 1;
        tracker.dres = concatenate_dres(tracker.dres, dres_one);
        % update LK tracker
        tracker = LK_update(frame_id, tracker);           
    else
        qscore = -1 * qscore;
        tracker.state = 3;
    end
    tracker.prev_state = 3;
end