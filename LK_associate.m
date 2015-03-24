% use LK trackers for association
function tracker = LK_associate(frame_id, dres_image, dres_det, tracker)

% current frame
J = dres_image.Igray{frame_id};

BB2 = [dres_det.x; dres_det.y; dres_det.x + dres_det.w; dres_det.y + dres_det.h];

% crop images and boxes
s = [tracker.std_box(1)/bb_width(BB2), tracker.std_box(2)/bb_height(BB2)];
bb_scale = round([BB2(1)*s(1); BB2(2)*s(2); BB2(3)*s(1); BB2(4)*s(2)]);
bb_scale(3) = bb_scale(1) + tracker.std_box(1) - 1;
bb_scale(4) = bb_scale(2) + tracker.std_box(2) - 1;
imsize = round([size(J,1)*s(2), size(J,2)*s(1)]);
J_scale = imResample(J, imsize, 'bilinear');
bb_crop = bb_rescale_relative(bb_scale, tracker.enlarge_box);
J_crop = im_crop(J_scale, bb_crop);
BB2_crop = bb_shift_absolute(bb_scale, [-bb_crop(1) -bb_crop(2)]); 

bb_crop_J = bb_crop;
s_J = s;

for i = 1:tracker.num
    I = dres_image.Igray{tracker.frame_ids(i)};
    
    BB1 = [tracker.x1(i); tracker.y1(i); tracker.x2(i); tracker.y2(i)];
    
    % crop images and boxes
    s = [tracker.std_box(1)/bb_width(BB1), tracker.std_box(2)/bb_height(BB1)];
    bb_scale = round([BB1(1)*s(1); BB1(2)*s(2); BB1(3)*s(1); BB1(4)*s(2)]);
    bb_scale(3) = bb_scale(1) + tracker.std_box(1) - 1;
    bb_scale(4) = bb_scale(2) + tracker.std_box(2) - 1;    
    imsize = round([size(I,1)*s(2), size(I,2)*s(1)]);
    I_scale = imResample(I, imsize, 'bilinear');
    bb_crop = bb_rescale_relative(bb_scale, tracker.enlarge_box);
    I_crop = im_crop(I_scale, bb_crop);
    BB1_crop = bb_shift_absolute(bb_scale, [-bb_crop(1) -bb_crop(2)]);
    
    % LK tracking
    [BB3, xFJ, flag, medFB, medNCC, medFB_left, medFB_right, medFB_up, medFB_down] = LK(I_crop, ...
        J_crop, BB1_crop, BB2_crop, tracker.level_lost);
    
    BB3 = bb_shift_absolute(BB3, [bb_crop_J(1) bb_crop_J(2)]);
    BB3 = [BB3(1)/s_J(1); BB3(2)/s_J(2); BB3(3)/s_J(1); BB3(4)/s_J(2)];
    
    ratio = (BB3(4)-BB3(2)) / (BB1(4)-BB1(2));
    ratio = min(ratio, 1/ratio);    
    
    if isnan(medFB) || isnan(medFB_left) || isnan(medFB_right) || isnan(medFB_up) || isnan(medFB_down)  ...
        || isnan(medNCC) || ~bb_isdef(BB3) || ratio < tracker.max_ratio
        medFB = inf;
        medFB_left = inf;
        medFB_right = inf;
        medFB_up = inf;
        medFB_down = inf;
        medNCC = 0;
        o = 0;
        score = 0;
        ind = 1;
        angle = 0;
        flag = 2;
        BB3 = [NaN; NaN; NaN; NaN];
    else
        % compute overlap
        dres.x = BB3(1);
        dres.y = BB3(2);
        dres.w = BB3(3) - BB3(1);
        dres.h = BB3(4) - BB3(2);
        o = calc_overlap(dres, 1, dres_det, 1);
        ind = 1;
        score = dres_det.r(1);
        
        % compute angle
        centerI = [(BB1(1)+BB1(3))/2 (BB1(2)+BB1(4))/2];
        centerJ = [(BB3(1)+BB3(3))/2 (BB3(2)+BB3(4))/2];
        v = compute_velocity(tracker);
        v_new = [centerJ(1)-centerI(1), centerJ(2)-centerI(2)] / double(frame_id - tracker.frame_ids(i));
        if norm(v) > tracker.min_vnorm && norm(v_new) > tracker.min_vnorm
            angle = dot(v, v_new) / (norm(v) * norm(v_new));
        else
            angle = 1;
        end        
    end
    
    tracker.bbs{i} = BB3;
    tracker.points{i} = xFJ;
    tracker.flags(i) = flag;
    tracker.medFBs(i) = medFB;
    tracker.medFBs_left(i) = medFB_left;
    tracker.medFBs_right(i) = medFB_right;
    tracker.medFBs_up(i) = medFB_up;
    tracker.medFBs_down(i) = medFB_down;    
    tracker.medNCCs(i) = medNCC;
    tracker.overlaps(i) = o;
    tracker.scores(i) = score;
    tracker.indexes(i) = ind;
    tracker.angles(i) = angle;
end

% combine tracking and detection results
[~, ind] = min(tracker.medFBs);
if tracker.overlaps(ind) > tracker.overlap_box
    index = tracker.indexes(ind);
    bb_det = [dres_det.x(index); dres_det.y(index); ...
        dres_det.x(index)+dres_det.w(index); dres_det.y(index)+dres_det.h(index)];
    tracker.bb = mean([repmat(tracker.bbs{ind}, 1, tracker.weight_association) bb_det], 2);
else
    tracker.bb = tracker.bbs{ind};
end

% compute pattern similarity
if bb_isdef(tracker.bb)
    pattern = generate_pattern(dres_image.Igray{frame_id}, tracker.bb, tracker.patchsize);
    nccs = distance(pattern, tracker.patterns, 1); % measure NCC to positive examples
    tracker.nccs = nccs';
else
    tracker.nccs = zeros(tracker.num, 1);
end

if tracker.is_show
    fprintf('LK association, target %d detection %.2f, medFBs ', ...
        tracker.target_id, dres_det.r);
    for i = 1:tracker.num
        fprintf('%.2f ', tracker.medFBs(i));
    end
    fprintf('\n');

    fprintf('LK association, target %d detection %.2f, medFBs left ', ...
        tracker.target_id, dres_det.r);
    for i = 1:tracker.num
        fprintf('%.2f ', tracker.medFBs_left(i));
    end
    fprintf('\n');

    fprintf('LK association, target %d detection %.2f, medFBs right ', ...
        tracker.target_id, dres_det.r);
    for i = 1:tracker.num
        fprintf('%.2f ', tracker.medFBs_right(i));
    end
    fprintf('\n');
    
    fprintf('LK association, target %d detection %.2f, medFBs up ', ...
        tracker.target_id, dres_det.r);
    for i = 1:tracker.num
        fprintf('%.2f ', tracker.medFBs_up(i));
    end
    fprintf('\n');

    fprintf('LK association, target %d detection %.2f, medFBs down ', ...
        tracker.target_id, dres_det.r);
    for i = 1:tracker.num
        fprintf('%.2f ', tracker.medFBs_down(i));
    end
    fprintf('\n');    

    fprintf('LK association, target %d detection %.2f, nccs ', ...
        tracker.target_id, dres_det.r);
    for i = 1:tracker.num
        fprintf('%.2f ', tracker.nccs(i));
    end
    fprintf('\n');

    fprintf('LK association, target %d detection %.2f, overlaps ', ...
        tracker.target_id, dres_det.r);
    for i = 1:tracker.num
        fprintf('%.2f ', tracker.overlaps(i));
    end
    fprintf('\n');

    fprintf('LK association, target %d detection %.2f, scores ', ...
        tracker.target_id, dres_det.r);
    for i = 1:tracker.num
        fprintf('%.2f ', tracker.scores(i));
    end
    fprintf('\n');

    fprintf('LK association, target %d detection %.2f, angles ', ...
        tracker.target_id, dres_det.r);
    for i = 1:tracker.num
        fprintf('%.2f ', tracker.angles(i));
    end
    fprintf('\n');
end