% initialization
function tracker = MDP_initialize(I, dres_det, opt)

image_width = size(I,2);
image_height = size(I,1);

% normalization factor for features
tracker.image_width = image_width;
tracker.image_height = image_height;
tracker.max_width = max(dres_det.w);
tracker.max_height = max(dres_det.h);
tracker.max_score = max(dres_det.r);
tracker.fb_factor = opt.fb_factor;

% initial state
tracker.prev_state = 1;
tracker.state = 1;
tracker.initial = 0;

% association model
tracker.fnum = 12;
tracker.w_tracked = [];
tracker.f_tracked = [];
tracker.l_tracked = [];

tracker.w_occluded = [];
tracker.f_occluded = [];
tracker.l_occluded = [];
tracker.streak_occluded = 0;

% tracker parameters
tracker.num = opt.num;
tracker.threshold_ratio = opt.threshold_ratio;
tracker.threshold_dis = opt.threshold_dis;
tracker.std_box = opt.std_box;  % [width height]
tracker.margin_box = opt.margin_box;
tracker.enlarge_box = opt.enlarge_box;
tracker.level_track = opt.level_track;
tracker.level = opt.level;
tracker.min_vnorm = opt.min_vnorm;
tracker.overlap_box = opt.overlap_box;
tracker.patchsize = opt.patchsize;
tracker.weight_tracking = opt.weight_tracking;
tracker.weight_association = opt.weight_association;

% display results or not
tracker.is_show = opt.is_show;