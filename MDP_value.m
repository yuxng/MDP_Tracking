% compute the value function
function [qscore, f, dres_track] = MDP_value(MDP, dres_track, dres_det, dres_image, is_display)

for i = 1:numel(dres_det.x)
    dres_det.state{i} = 'active';
end
dres_track = concatenate_dres(dres_track, dres_det);
index = find(~strcmp('inactive', dres_track.state));
dres = sub(dres_track, index);

% select the action with network flow
% adding transition links to the graph by fiding overlapping detections in consequent frames.
dres = build_graph(MDP, dres, dres_image);

% setting parameters for tracking
c_en = 0;     % birth cost
c_ex = 0;     % death cost
betta_index = 5;

dres_track_tmp = tracking_push_relabel(dres, c_en, c_ex);

% compute feature vector
f = zeros(MDP.fnum, 1);

% process tracking results
tr_num = 0;
ids = unique(dres_track_tmp.id);
% for each track
for i = 1:numel(ids)
    if ids(i) == -1  % unmatched track or detection
        index_unmatched = find(dres_track_tmp.id == -1);
        for j = 1:numel(index_unmatched)
            ind = index(index_unmatched(j));
            if dres_track.id(ind) ~= -1  % track
                if is_display
                    fprintf('target %d unmatched\n', dres_track.id(ind));
                end
                % target lost
                dres_track.lost(ind) = dres_track.lost(ind) + 1;
                if dres_track.lost(ind) > MDP.threshold_lost
                    dres_track.state{ind} = 'inactive';  % end target
                    if is_display
                        fprintf('target %d ended\n', dres_track.id(ind));
                    end
                    % check if removing the target
                    if dres_track.tracked(ind) < MDP.threshold_tracked
                        if is_display
                            fprintf('target %d is tracked less than %d frames\n', ...
                                dres_track.id(ind), MDP.threshold_tracked);
                        end
                    end
                else
                    dres_track.state{ind} = 'lost';
                end                
            end
        end
    else
        tr_num = tr_num + 1;
        matched = find(dres_track_tmp.id == ids(i));
        if numel(matched) == 1  % unmatched track or detection
            ind = index(matched);
            if dres_track.id(ind) ~= -1  % track
                if is_display
                    fprintf('target %d unmatched\n', dres_track.id(ind));
                end
                % target lost
                dres_track.lost(ind) = dres_track.lost(ind) + 1;
                if dres_track.lost(ind) > MDP.threshold_lost
                    dres_track.state{ind} = 'inactive';  % end target
                    if is_display
                        fprintf('target %d ended\n', dres_track.id(ind));
                    end
                    % check if removing the target
                    if dres_track.tracked(ind) < MDP.threshold_tracked
                        if is_display
                            fprintf('target %d is tracked less than %d frames\n', ...
                                dres_track.id(ind), MDP.threshold_tracked);
                        end
                    end
                else
                    dres_track.state{ind} = 'lost';
                end
            else  % add the detection
                dres_track.id(ind) = max(dres_track.id) + 1;
                dres_track.tracked(ind) = 1;
                dres_track.state{ind} = 'tracked';
                if is_display
                    fprintf('target %d enter\n', dres_track.id(ind));
                end                
            end
            % update feature
            f(betta_index) = f(betta_index) + dres_track.r(ind);
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
            ind = dres_track_tmp.nei(matched(2)).inds == matched(1);
            f(1:4) = f(1:4) + dres_track_tmp.nei(matched(2)).features{ind}';
            f(betta_index) = f(betta_index) + 0.5*dres_track.r(ind1) + 0.5*dres_track.r(ind2);
        end
    end
end
f = f / tr_num;

% compute qscore
qscore = dot(MDP.weights, f);

% remove used detections
index = find(dres_track.id ~= -1);
dres_track = sub(dres_track, index);