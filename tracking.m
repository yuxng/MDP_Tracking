% network flow tracking
function dres_push_relabel = tracking(img, dres_track, models)

index = find(dres_track.status == 1 | dres_track.status == 4);
dres = sub(dres_track, index);

%%% Adding transition links to the graph by fiding overlapping detections in consequent frames.
[dres, tr_num] = build_graph(img, dres, models);

%%% setting parameters for tracking
c_en      = 10;     %% birth cost
c_ex      = 10;     %% death cost
betta     = 0.2;    %% betta

dres_push_relabel   = tracking_push_relabel(dres, c_en, c_ex, betta, tr_num);