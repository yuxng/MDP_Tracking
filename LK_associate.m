% use LK trackers for association
function tracker = LK_associate(frame_id, dres_image, dres_det, tracker)

% current frame
J = dres_image.Igray{frame_id};

% crop image with bounding box
rect = [dres_det.x dres_det.y dres_det.w dres_det.h];
centerJ = [dres_det.x+dres_det.w/2, dres_det.y+dres_det.h/2];
J = imcrop(J, rect);

for i = 1:tracker.num
    I = dres_image.Igray{tracker.frame_ids(i)};
    BB1 = [tracker.x1(i); tracker.y1(i); tracker.x2(i); tracker.y2(i)];
    
    % crop image with bounding box
    rect = [BB1(1) BB1(2) BB1(3)-BB1(1) BB1(4)-BB1(2)];
    centerI = [(BB1(1)+BB1(3))/2 (BB1(2)+BB1(4))/2];
    I = imcrop(I, rect);
    
    % compute angle
    v = compute_velocity(tracker);
    v_new = [centerJ(1)-centerI(1), centerJ(2)-centerI(2)] / double(frame_id - tracker.frame_ids(i));
    angle = dot(v, v_new) / (norm(v) * norm(v_new));
    
    % resize the image
    I = imresize(I, size(J));
    BB1 = [1; 1; size(I,2); size(I,1)];
    
    BB1 = bb_rescale_relative(BB1, tracker.rescale_box);
    [BB2, xFJ, flag, medFB, medNCC] = LK(BB1, I, J);
    BB2 = bb_rescale_relative(BB2, 1./tracker.rescale_box);
    if isnan(medFB) || isnan(medNCC) || ~bb_isdef(BB2)
        medFB = inf;
        medNCC = 0;
        flag = 3;   % no test for target outside image
    end
    
    tracker.bbs{i} = BB2;
    tracker.points{i} = xFJ;
    tracker.flags(i) = flag;
    tracker.medFBs(i) = medFB;
    tracker.medNCCs(i) = medNCC;
    tracker.angles(i) = angle;
end

% use detection as output
bb_det = [dres_det.x; dres_det.y; ...
    dres_det.x+dres_det.w; dres_det.y+dres_det.h];
tracker.bb = bb_det;

% compute pattern similarity
pattern = generate_pattern(dres_image.Igray{frame_id}, bb_det, tracker.patchsize);
nccs = distance(pattern, tracker.patterns, 1); % measure NCC to positive examples
tracker.nccs = nccs';

fprintf('LK association, target %d detection %.2f, medFBs ', ...
    tracker.target_id, dres_det.r);
for i = 1:tracker.num
    fprintf('%.2f ', tracker.medFBs(i))
end
fprintf('\n');

fprintf('LK association, target %d detection %.2f, nccs ', ...
    tracker.target_id, dres_det.r);
for i = 1:tracker.num
    fprintf('%.2f ', tracker.nccs(i))
end
fprintf('\n');

fprintf('LK association, target %d detection %.2f, angles ', ...
    tracker.target_id, dres_det.r);
for i = 1:tracker.num
    fprintf('%.2f ', tracker.angles(i))
end
fprintf('\n');

% compute velocity
function v = compute_velocity(tracker)

fr = double(unique(tracker.frame_ids));
num = numel(fr);

% compute centers
centers = zeros(num, 2);
for i = 1:num
    index = find(tracker.frame_ids == fr(i));
    for j = 1:numel(index)
        ind = index(j);
        c = [(tracker.x1(ind)+tracker.x2(ind))/2 (tracker.y1(ind)+tracker.y2(ind))/2];
        centers(i,:) = centers(i,:) + c;
    end
    if numel(index)
        centers(i,:) = centers(i,:) / numel(index);
    end
end

count = 0;
vx = 0;
vy = 0;
cx = centers(:,1);
cy = centers(:,2);
for j = 2:num
    vx = vx + (cx(j)-cx(j-1)) / (fr(j) - fr(j-1));
    vy = vy + (cy(j)-cy(j-1)) / (fr(j) - fr(j-1));
    count = count + 1;
end
if count
    vx = vx / count;
    vy = vy / count;
end
v = [vx, vy];