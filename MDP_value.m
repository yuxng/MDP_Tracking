% compute the value function
function [qscores_all, actions_all, index_det_all] = MDP_value(MDP, dres_track, index, dres)

num_det = numel(dres.x);
% select an action for each target
num = numel(index);
qscores_all = zeros(num, 1);
actions_all = cell(num, 1);
index_det_all = zeros(num, 1);
for i = 1:num
    % find the possible actions for this target
    actions = MDP.actable_actions(MDP, dres_track.state{index(i)});
    % for link action, it should be expanded according to detections
    [actions, index_det] = MDP.expand_link(actions, num_det);
    % select the action maximizing the Q-function
    num_action = numel(actions);
    qscores = zeros(num_action, 1);
    for k = 1:num_action
        qscores(k) = MDP_qscore(MDP, dres_track, index(i), dres, index_det(k), actions{k});
    end
    [q, ind] = max(qscores);
    qscores_all(i) = q;
    actions_all{i} = actions{ind};
    index_det_all(i) = index_det(ind);
end