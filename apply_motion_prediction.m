% apply motion models to predict the next locations of the targets
function models = apply_motion_prediction(fr_current, dres_track, models)

% apply motion model and predict next location
index = find(dres_track.status ~= 0 & dres_track.id ~= -1);
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
    
    cx_new = cx(end) + vx * (fr_current + 1 - fr(end));
    cy_new = cy(end) + vy * (fr_current + 1 - fr(end));
    models{id}.prediction = [cx_new cy_new];
end