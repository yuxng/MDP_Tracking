% execute action
function dres_track = MDP_execute_action(MDP, dres_track, index, dres, actions, index_det)

num = numel(index);
for i = 1:num
    action = actions{i};
    ind = index_det(i);
    switch action
        case 'link'
            tmp = sub(dres, ind);
            tmp.id = dres_track.id(index(i));
            tmp.state = MDP.transition(MDP, dres_track.state{index(i)}, action);
            tmp.tracked = dres_track.tracked(index(i)) + 1;
            dres_track = concatenate_dres(dres_track, tmp);
        case {'hold', 'terminate'}
            dres_track.state{index(i)} = MDP.MDP_transition(MDP, dres_track.state{index(i)}, action);
            dres_track.lost(index(i)) = dres_track.lost(index(i)) + 1;
    end
end