% execute action
function dres_track = MDP_execute(MDP, dres_track, dres, actions, index_det)

index = find(~strcmp('inactive', dres_track.state));
num = numel(index);
flags = zeros(numel(dres.x), 1);
for i = 1:num
    action = actions{i};
    ind = index_det(i);
    switch action
        case 'link'
            tmp = sub(dres, ind);
            tmp.id = dres_track.id(index(i));
            tmp.state = MDP.transition(MDP, dres_track.state{index(i)}, action);
            tmp.tracked = dres_track.tracked(index(i)) + 1;
            dres_track.state{index(i)} = 'inactive';
            dres_track = concatenate_dres(dres_track, tmp);
            flags(ind) = 1;
            fprintf('target %d link to detection with score %f\n', tmp.id, tmp.r);
        case {'hold', 'terminate'}
            dres_track.state{index(i)} = MDP.transition(MDP, dres_track.state{index(i)}, action);
            dres_track.lost(index(i)) = dres_track.lost(index(i)) + 1;
            fprintf('target %d %s\n', dres_track.id(index(i)), action);
    end
end

% add unlinked detections as new targets
dres_unlink = sub(dres, find(flags == 0));
ID = max(dres_track.id);
for i = 1:numel(dres_unlink.x)
    dres_unlink.id(i) = ID + i;
    dres_unlink.tracked(i) = 1;
    dres_unlink.state{i} = 'active';
end
dres_track = concatenate_dres(dres_track, dres_unlink);