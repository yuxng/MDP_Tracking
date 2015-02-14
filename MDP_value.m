% compute the value function
function [qscore, f, dres_track] = MDP_value(MDP, dres_track, dres_det, dres_image, opt, is_display)

for i = 1:numel(dres_det.x)
    dres_det.state{i} = 'active';
end
dres_track = concatenate_dres(dres_track, dres_det);
index = find(~strcmp('inactive', dres_track.state));
dres = sub(dres_track, index);

% select the action with network flow
% adding transition links to the graph by fiding overlapping detections in consequent frames.
[dres, tr_num] = build_graph(MDP, dres, dres_image);

% setting parameters for tracking
c_en = 10;     % birth cost
c_ex = 10;     % death cost
betta_index = 5;
betta = MDP.weights(betta_index);   % betta

dres_track_tmp = tracking_push_relabel(dres, c_en, c_ex, betta, tr_num);

% compute feature vector
f = zeros(MDP.fnum, 1);

% process tracking results
ids = unique(dres_track_tmp.id);
% for each track
for i = 1:numel(ids)
    if ids(i) == -1  % unmatched detection
        index_unmatched = find(dres_track_tmp.id == -1);
        ID = max(dres_track.id);
        for j = 1:numel(index_unmatched)
            dres_track.id(index(index_unmatched(j))) = ID + j;
            dres_track.tracked(index(index_unmatched(j))) = 1;
            if is_display
                fprintf('target %d enter\n', ID+j);
            end
        end
    else
        matched = find(dres_track_tmp.id == ids(i));
        if numel(matched) == 1  % unmatched track
            if is_display
                fprintf('target %d unmatched\n', dres_track.id(index(matched)));
            end
            % target lost
            dres_track.lost(index(matched)) = dres_track.lost(index(matched)) + 1;
            if dres_track.lost(index(matched)) > opt.lost
                dres_track.state{index(matched)} = 'inactive';  % end target
                if is_display
                    fprintf('target %d ended\n', dres_track.id(index(matched)));
                end
                % check if removing the target
                if dres_track.tracked(index(matched)) < opt.tracked
                    if is_display
                        fprintf('target %d is tracked less than %d frames\n', ...
                            dres_track.id(index(matched)), opt.tracked);
                    end
                end
            else
                dres_track.state{index(matched)} = 'lost';
            end
            % update feature
            f(betta_index) = f(betta_index) + dres_track.r(index(matched));
        else  % matched track and detection
            ind1 = index(matched(1));
            ind2 = index(matched(2));
            dres_track.id(ind2) = dres_track.id(ind1);
            dres_track.state{ind1} = 'inactive';
            dres_track.tracked(ind2) = dres_track.tracked(ind1) + 1;
            dres_track.lost(ind2) = 0;
            dres_track.state{ind2} = 'tracked';
            if is_display
                fprintf('target %d matched to detection with score %.2f\n', ...
                    dres_track.id(ind2), dres_track.r(ind2));
            end
            % update feature
            f(1:4) = f(1:4) + dres_track_tmp.nei(matched(2)).features{matched(1)}';
            f(betta_index) = f(betta_index) + dres_track.r(ind1) + dres_track.r(ind2);
        end
    end
end
f = f / tr_num;

% compute qscore
qscore = dot(MDP.weights, f);