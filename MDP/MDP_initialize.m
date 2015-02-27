function MDP = MDP_initialize()

MDP.states = {'active', 'tracked', 'lost', 'inactive'};
MDP.actions = {'link', 'hold', 'terminate'}; % link action is composite
MDP.actable_actions = @MDP_actable_actions;  % function handler
MDP.transition = @MDP_transition;  % function handler
MDP.expand_link = @MDP_expand_link;  % function handler

% learning parameters
MDP.T = 3;
MDP.intervals = [5, 20, 30];
MDP.gamma = 0.5;
MDP.alpha = 0.01;
MDP.epsilon = 0.1;
MDP.fnum = 5;
MDP.weights = rand(MDP.fnum, 1);

% tracking parameters
MDP.threshold_dis = 50;
MDP.threshold_lost = 10;
MDP.threshold_tracked = 4;

function actions = MDP_actable_actions(MDP, state)

state_index = find(strcmp(state, MDP.states) == 1);

if state_index == 1  % active
    actions = {'link', 'terminate'};
elseif state_index == 2 % tracked
    actions = {'link', 'hold'};
elseif state_index == 3  % lost
    actions = {'link', 'hold', 'terminate'};
elseif state_index == 4  % inactive
    actions = {'terminate'};
end


function state_new = MDP_transition(MDP, state, action)

state_index = find(strcmp(state, MDP.states) == 1);
action_index = find(strcmp(action, MDP.actions) == 1);

if state_index == 1  % active
    if action_index == 1  % link
        state_new = 'tracked';
    elseif action_index == 3  % terminate
        state_new = 'inactive';
    else
        state_new = [];
    end
elseif state_index == 2 % tracked
    if action_index == 1 % link
        state_new = 'tracked';
    elseif action_index == 2 % hold
        state_new = 'lost';
    else
        state_new = [];
    end
elseif state_index == 3  % lost
    if action_index == 1 % link
        state_new = 'tracked';
    elseif action_index == 2;  % hold
        state_new = 'lost';
    elseif action_index == 3  % terminate
        state_new = 'inactive';
    else
        state_new = [];
    end
elseif state_index == 4  % inactive
    if action_index == 3  % terminate
        state_new = 'inactive';
    else
        state_new = [];
    end
end


% expand link action
function [actions_new, index_det] = MDP_expand_link(actions, num_det)

num_action = numel(actions);
if isempty(find(strcmp('link', actions), 1)) == 1
    actions_new = actions;
    index_det = -1 * ones(num_action, 1);
else
    actions_new = cell(num_det + num_action - 1, 1);
    index_det = zeros(num_det + num_action - 1, 1);
    count = 0;
    for i = 1:num_det
        count = count + 1;
        actions_new{count} = 'link';
        index_det(count) = i;
    end
    index = find(strcmp('link', actions) == 0);
    for i = 1:numel(index)
        count = count + 1;
        actions_new{count} = actions{index(i)};
        index_det(count) = -1;
    end
end