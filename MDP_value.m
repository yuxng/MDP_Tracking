% compute the value function
function [qscore, f, actions_all, index_det_all] = MDP_value(MDP, dres_track, dres, dres_image, is_random)

index = find(~strcmp('inactive', dres_track.state));
num_det = numel(dres.x);
% select an action for each target
num = numel(index);
qscores_all = zeros(num, 1);
fs_all = cell(num, 1);
actions_all = cell(num, 1);
index_det_all = zeros(num, 1);
for i = 1:num
    % find the possible actions for this target
    actions = MDP.actable_actions(MDP, dres_track.state{index(i)});
    % for link action, it should be expanded according to detections
    [actions, index_det] = MDP.expand_link(actions, num_det);
    % select the action maximizing the Q-function
    num_action = numel(actions);
    if is_random == 0
        qscores = zeros(num_action, 1);
        fs = cell(num_action, 1);
        for k = 1:num_action
            [qscores(k), fs{k}] = MDP_qscore(MDP, dres_track, index(i), dres, index_det(k), actions{k}, dres_image);
        end
        [q, ind] = max(qscores);
        qscores_all(i) = q;
        fs_all{i} = fs{ind};
        actions_all{i} = actions{ind};
        index_det_all(i) = index_det(ind);
    else
        ind = randi(num_action, 1);
        actions_all{i} = actions{ind};
        index_det_all(i) = index_det(ind);        
        [qscores_all(i), fs_all{i}] = MDP_qscore(MDP, dres_track, index(i), dres, ...
            index_det(ind), actions{ind}, dres_image);
    end
end

% sum qscore and features
qscore = mean(qscores_all);
f = zeros(MDP.fnum, 1);
for i = 1:num
    f = f + fs_all{i};
end
if num
    f = f/num;
end