% network flow tracking
function dres_push_relabel = tracking(dres)

%%% Adding transition links to the graph by fiding overlapping detections in consequent frames.
display('in building the graph...')
[dres, tr_num] = build_graph(dres);

%%% setting parameters for tracking
c_en      = 10;     %% birth cost
c_ex      = 10;     %% death cost
c_ij      = 0;      %% transition cost
betta     = 0.2;    %% betta

display('in push relabel algorithm ...')
dres_push_relabel   = tracking_push_relabel(dres, c_en, c_ex, c_ij, betta, tr_num);