% initialize the LK tracker
function tracker = LK_initialize(tracker, frame_id, target_id, dres, ind, dres_image, opt)

x1 = dres.x(ind);
y1 = dres.y(ind);
x2 = dres.x(ind) + dres.w(ind);
y2 = dres.y(ind) + dres.h(ind);    

% template num
num = tracker.num;

% tracker parameters
tracker.threshold_ratio = 0.6;
tracker.threshold_dis = 200;
tracker.target_id = target_id;
tracker.rescale_box = [0.6 1];  % [width height]
tracker.bb = zeros(4,1);
tracker.patchsize = [24 12];

% initialize all the templates
bb = repmat([x1; y1; x2; y2], [1 num]);
bb(:,2) = bb_shift_relative(bb(:,1), [-0.01 -0.01]);
bb(:,3) = bb_shift_relative(bb(:,1), [-0.01 0.01]);
bb(:,4) = bb_shift_relative(bb(:,1), [0.01 -0.01]);
bb(:,5) = bb_shift_relative(bb(:,1), [0.01 0.01]);

tracker.frame_ids = frame_id * int32(ones(num, 1));
tracker.x1 = bb(1,:)';
tracker.y1 = bb(2,:)';
tracker.x2 = bb(3,:)';
tracker.y2 = bb(4,:)';

% initialize the patterns
img = dres_image.Igray{frame_id};
tracker.patterns = generate_pattern(img, bb, tracker.patchsize);

% box overlap history
tracker.bb_overlaps = ones(num, 1);

% tracker resutls
tracker.bbs = cell(num, 1);
tracker.points = cell(num, 1);
tracker.flags = ones(num, 1);
tracker.medFBs = zeros(num, 1);
tracker.medFBs_left = zeros(num, 1);
tracker.medFBs_right = zeros(num, 1);
tracker.medNCCs = zeros(num, 1);
tracker.overlaps = zeros(num, 1);
tracker.scores = zeros(num, 1);
tracker.indexes = zeros(num, 1);
tracker.nccs = zeros(num, 1);
tracker.angles = zeros(num, 1);

if isempty(tracker.w_tracked) == 1
    features = [ones(1, tracker.fnum_tracked); zeros(1, tracker.fnum_tracked)];
    labels = [+1; -1];
    tracker.ftracked = features;
    tracker.ltracked = labels;
    tracker.w_tracked = svmtrain(tracker.ltracked, tracker.ftracked, '-c 1 -b 1'); 
end

% compute features for occluded state
if isempty(tracker.w_occluded) == 1
    features = MDP_feature_occluded(frame_id, dres_image, dres, tracker, opt);
    m = size(features, 1);
    labels = -1 * ones(m, 1);
    labels(ind) = 1;
    ov = calc_overlap(dres, ind, dres, 1:numel(dres.fr));
    ov(ind) = 0;
    index = find(ov > 0.5);
    features(index,:) = [];
    labels(index,:) = [];
    
    % add default negative example
    features = [features; zeros(1, tracker.fnum_occluded)];
    labels = [labels; -1];
    
    tracker.foccluded = features;
    tracker.loccluded = labels;
    tracker.w_occluded = svmtrain(tracker.loccluded, tracker.foccluded, '-c 1 -b 1');    
end