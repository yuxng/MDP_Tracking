% network flow tracking
function [dres_track, features] = tracking(model, dres_track, dres_det, dres_image, opt)

for i = 1:numel(dres_det.x)
    dres_det.state(i) = 1;
end
dres_track = concatenate_dres(dres_track, dres_det);
index = find(dres_track.state ~= 0);
dres = sub(dres_track, index);

% select the action with network flow
% adding transition links to the graph by fiding overlapping detections in consequent frames.
dres = build_graph(model, dres, dres_image, opt);

% setting parameters for tracking
c_en = model.weights(model.f_start);     % birth cost
c_ex = model.weights(model.f_end);       % death cost
dres_track_tmp = tracking_push_relabel(dres, c_en, c_ex);

% compute feature vector
features = zeros(model.fnum, 1);

% process tracking results
ids = unique(dres_track_tmp.id);
% for each track
for i = 1:numel(ids)
    if ids(i) == -1  % unmatched track or detection
        index_unmatched = find(dres_track_tmp.id == -1);
        for j = 1:numel(index_unmatched)
            ind = index(index_unmatched(j));
            if dres_track.id(ind) ~= -1  % track
                if opt.is_display
                    fprintf('target %d lost\n', dres_track.id(ind));
                end
                % target lost
                dres_track.lost(ind) = dres_track.lost(ind) + 1;
                if dres_track.lost(ind) > opt.lost
                    dres_track.state(ind) = 0;  % end target
                    if opt.is_display
                        fprintf('target %d ended\n', dres_track.id(ind));
                    end
                    % check if removing the target
                    if dres_track.tracked(ind) < opt.tracked
                        if opt.is_display
                            fprintf('target %d is tracked less than %d frames\n', ...
                                dres_track.id(ind), opt.tracked);
                        end
                    end
                else
                    dres_track.state(ind) = 2;
                end                
            end
        end
    else
        matched = find(dres_track_tmp.id == ids(i));
        if numel(matched) == 1  % unmatched track or detection
            ind = index(matched);
            if dres_track.id(ind) ~= -1  % track
                if opt.is_display
                    fprintf('target %d lost\n', dres_track.id(ind));
                end
                % target lost
                dres_track.lost(ind) = dres_track.lost(ind) + 1;
                if dres_track.lost(ind) > opt.lost
                    dres_track.state(ind) = 0;  % end target
                    if opt.is_display
                        fprintf('target %d ended\n', dres_track.id(ind));
                    end
                    % check if removing the target
                    if dres_track.tracked(ind) < opt.tracked
                        if opt.is_display
                            fprintf('target %d is tracked less than %d frames\n', ...
                                dres_track.id(ind), opt.tracked);
                        end
                    end
                else
                    dres_track.state(ind) = 2;
                end
            else  % add the detection
                dres_track.id(ind) = max(dres_track.id) + 1;
                dres_track.tracked(ind) = 1;
                dres_track.state(ind) = 1;
                if opt.is_display
                    fprintf('target %d enter\n', dres_track.id(ind));
                end                
            end
            % update feature
            features(model.f_start) = features(model.f_start) + 1;
            features(model.f_end) = features(model.f_end) + 1;
            features(model.f_det) = features(model.f_det) + dres_track.r(ind);
            features(model.f_cover) = features(model.f_cover) + dres_track.covers(ind);
            features(model.f_bias) = features(model.f_bias) + 1;
        else  % matched track and detection
            ind1 = index(matched(1));
            ind2 = index(matched(2));
            dres_track.id(ind2) = dres_track.id(ind1);
            dres_track.state(ind1) = 0;
            dres_track.tracked(ind2) = dres_track.tracked(ind1) + 1;
            dres_track.lost(ind2) = 0;
            dres_track.state(ind2) = 1;
            if opt.is_display
                fprintf('target %d matched to detection with score %.2f\n', ...
                    dres_track.id(ind2), dres_track.r(ind2));
            end
            % update features
            ind = dres_track_tmp.nei(matched(2)).inds == matched(1);           
            features(model.f_start) = features(model.f_start) + 1;
            features(model.f_end) = features(model.f_end) + 1;
            features(model.f_det) = features(model.f_det) + dres_track.r(ind1) + dres_track.r(ind2);
            features(model.f_cover) = features(model.f_cover) + dres_track.covers(ind1) + dres_track.covers(ind2);
            features(model.f_bias) = features(model.f_bias) + 2;
            % overlap between detection and track
            features(model.f_overlap) = features(model.f_overlap) + dres_track_tmp.nei(matched(2)).features{ind}(1);
            % distance between detection and track
            features(model.f_distance) = features(model.f_distance) + dres_track_tmp.nei(matched(2)).features{ind}(2);
            % aspect ratio between detection and track
            features(model.f_ratio) = features(model.f_ratio) + dres_track_tmp.nei(matched(2)).features{ind}(3);
            % chi square distance between color histogram
            features(model.f_color) = features(model.f_color) + dres_track_tmp.nei(matched(2)).features{ind}(4);            
        end
    end
end

% remove used detections
index = find(dres_track.id ~= -1);
dres_track = sub(dres_track, index);