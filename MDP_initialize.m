% initialization
function tracker = MDP_initialize(image_width, image_height, dres_det, labels, opt)

% normalization factor for features
tracker.image_width = image_width;
tracker.image_height = image_height;
tracker.max_width = max(dres_det.w);
tracker.max_height = max(dres_det.h);
tracker.max_score = max(dres_det.r);
tracker.fb_factor = opt.fb_factor;

% active
tracker.prev_state = 1;
tracker.state = 1;
tracker.fnum_active = 6;
factive = MDP_feature_active(tracker, dres_det);
index = labels ~= 0;
tracker.factive = factive(index,:);
tracker.lactive = labels(index);
tracker.w_active = svmtrain(tracker.lactive, tracker.factive, '-c 1');

% tracked
num = opt.num;
tracker.num = num;
tracker.fnum_tracked = 5;
tracker.w_tracked = [];

% occluded
tracker.fnum_occluded = 5;
tracker.w_occluded = [];
tracker.streak_occluded = 0;

% tracker parameters
tracker.threshold_ratio = opt.threshold_ratio;
tracker.threshold_dis = opt.threshold_dis;
tracker.rescale_box = opt.rescale_box;  % [width height]
tracker.rescale_img = opt.rescale_img;
tracker.enlarge_box = opt.enlarge_box;
tracker.level_track = opt.level_track;
tracker.level_lost = opt.level_lost;
tracker.max_ratio = opt.max_ratio;
tracker.min_vnorm = opt.min_vnorm;
tracker.overlap_box = opt.overlap_box;
tracker.patchsize = opt.patchsize;
tracker.weight_tracking = opt.weight_tracking;
tracker.weight_association = opt.weight_association;

% display results or not
tracker.is_show = opt.is_show;