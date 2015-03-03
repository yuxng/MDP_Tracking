% apply motion models to predict the next locations of the targets
function prediction = apply_motion_prediction(fr_current, tracker)

% apply motion model and predict next location
dres = tracker.dres;
cx = dres.x + dres.w/2;
cy = dres.y + dres.h/2;
fr = double(dres.fr);
fr_current = double(fr_current);

% compute velocity
vx = 0;
vy = 0;
num = numel(cx);
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
prediction = [cx_new cy_new];