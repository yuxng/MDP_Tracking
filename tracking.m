% network flow tracking
function dres_push_relabel = tracking(img, dres_track, models)

fmax = max(dres_track.fr);
% apply motion model and predict next location
index = find(dres_track.status == 1 & dres_track.id ~= -1);
for i = 1:numel(index)
    id = dres_track.id(index(i));
    ind = find(dres_track.id == id);
    cx = dres_track.x(ind) + dres_track.w(ind)/2;
    cy = dres_track.y(ind) + dres_track.h(ind)/2;
    fr = dres_track.fr(ind);
    % compute velocity
    vx = 0;
    vy = 0;
    num = numel(ind);
    count = 0;
    for j = 2:num
        vx = vx + (cx(j)-cx(j-1)) / (fr(j) - fr(j-1));
        vy = vy + (cy(j)-cy(j-1)) / (fr(j) - fr(j-1));
        count = count + 1;
    end
    if count
        vx = vx / count;
        vy = vy / count;
    end
    
    cx_new = cx(end) + vx * (fmax - fr(end));
    cy_new = cy(end) + vy * (fmax - fr(end));
    models{id}.prediction = [cx_new cy_new];
end

index = find(dres_track.status == 1);
dres = sub(dres_track, index);

%%% Adding transition links to the graph by fiding overlapping detections in consequent frames.
[dres, tr_num] = build_graph(img, dres, models);

%%% setting parameters for tracking
c_en      = 10;     %% birth cost
c_ex      = 10;     %% death cost
betta     = 0.2;    %% betta

dres_push_relabel   = tracking_push_relabel(dres, c_en, c_ex, betta, tr_num);