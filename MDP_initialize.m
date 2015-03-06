% initialization
function tracker = MDP_initialize(image_width, image_height, dres_det, labels)

% learning parameters
tracker.gamma = 0.5;
tracker.alpha = 0.01;
tracker.explore = 0.1;

% normalization factor for features
tracker.image_width = image_width;
tracker.image_height = image_height;
tracker.max_width = max(dres_det.w);
tracker.max_height = max(dres_det.h);
tracker.max_score = max(dres_det.r);
tracker.fb_factor = 30;
tracker.frame_weight = 0.95;

% active
tracker.prev_state = 1;
tracker.state = 1;
tracker.fnum_active = 6;
tracker.factive = MDP_feature_active(tracker, dres_det);
tracker.lactive = labels;
tracker.w_active = svmtrain(tracker.lactive, tracker.factive, '-c 1');

% tracked
tracker.num = 10;
tracker.fnum_tracked = 4 * tracker.num + 1;
tracker.w_tracked = rand(tracker.fnum_tracked, 1);

% occluded
tracker.fnum_occluded = 4 * tracker.num + 1;
tracker.w_occluded = [];