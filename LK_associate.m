% use LK trackers for association
function tracker = LK_associate(frame_id, dres_image, dres_det, tracker, opt)

rescale = 0.5;

% current frame
J = dres_image.Igray{frame_id};
J = imresize(J, rescale);

BB2 = [dres_det.x; dres_det.y; dres_det.x + dres_det.w; dres_det.y + dres_det.h] * rescale;
BB2 = bb_rescale_relative(BB2, tracker.rescale_box);

for i = 1:tracker.num
    I = dres_image.Igray{tracker.frame_ids(i)};
    I = imresize(I, rescale);
    
    BB1 = [tracker.x1(i); tracker.y1(i); tracker.x2(i); tracker.y2(i)] * rescale;    
    BB1 = bb_rescale_relative(BB1, tracker.rescale_box);
    
    [BB3, xFJ, flag, medFB, medNCC, medFB_left, medFB_right] = LK(I, J, BB1, BB2, 1);
    BB3 = bb_rescale_relative(BB3, 1./tracker.rescale_box) / rescale;
    BB1 = bb_rescale_relative(BB1, 1./tracker.rescale_box) / rescale;
    
    ratio = (BB3(4)-BB3(2)) / (BB1(4)-BB1(2));
    ratio = min(ratio, 1/ratio);    
    
    if isnan(medFB) || isnan(medFB_left) || isnan(medFB_right) || isnan(medNCC) || ~bb_isdef(BB3) || ratio < 0.75
        medFB = inf;
        medFB_left = inf;
        medFB_right = inf;
        medNCC = 0;
        o = 0;
        score = 0;
        ind = 1;
        angle = 0;
        flag = 2;
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
        if norm(v) > 0.2 && norm(v_new) > 0.2
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
    tracker.medNCCs(i) = medNCC;
    tracker.overlaps(i) = o;
    tracker.scores(i) = score;
    tracker.indexes(i) = ind;
    tracker.angles(i) = angle;
end

% combine tracking and detection results
[~, ind] = min(tracker.medFBs);
if tracker.overlaps(ind) > 0.7
    index = tracker.indexes(ind);
    bb_det = [dres_det.x(index); dres_det.y(index); ...
        dres_det.x(index)+dres_det.w(index); dres_det.y(index)+dres_det.h(index)];
    tracker.bb = mean([repmat(tracker.bbs{ind},1,opt.weight_association) bb_det], 2);
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

if opt.is_show
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