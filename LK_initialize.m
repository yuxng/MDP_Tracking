% initialize the LK tracker
function tracker = LK_initialize(frame_id, target_id, x1, y1, x2, y2)

% template num
num = 5;

% tracker parameters
tracker.target_id = target_id;
tracker.num = num;
tracker.rescale_box = [0.6 0.8];
tracker.bb = zeros(4,1);

% initialize all the templates as the same
tracker.frame_ids = frame_id * ones(num, 1);
tracker.x1 = x1 * ones(num, 1);
tracker.y1 = y1 * ones(num, 1);
tracker.x2 = x2 * ones(num, 1);
tracker.y2 = y2 * ones(num, 1);

% tracker resutls
tracker.bbs = cell(num, 1);
tracker.points = cell(num, 1);
tracker.flags = zeros(num, 1);
tracker.medFBs = zeros(num, 1);
tracker.medNCCs = zeros(num, 1);
tracker.overlaps = zeros(num, 1);
tracker.indexes = zeros(num, 1);