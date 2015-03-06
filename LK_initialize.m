% initialize the LK tracker
function tracker = LK_initialize(tracker, frame_id, target_id, x1, y1, x2, y2, img)

% template num
num = tracker.num;

% tracker parameters
tracker.threshold_ratio = 0.6;
tracker.threshold_dis = 150;
tracker.target_id = target_id;
tracker.rescale_box = [0.5 0.8];
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
tracker.patterns = generate_pattern(img, bb, tracker.patchsize);

% tracker resutls
tracker.bbs = cell(num, 1);
tracker.points = cell(num, 1);
tracker.flags = ones(num, 1);
tracker.medFBs = zeros(num, 1);
tracker.medNCCs = zeros(num, 1);
tracker.overlaps = zeros(num, 1);
tracker.indexes = zeros(num, 1);
tracker.nccs = zeros(num, 1);
tracker.angles = zeros(num, 1);