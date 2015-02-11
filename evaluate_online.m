function evaluate_online

opt = globals();
seq_set = 'train';
seq_name = 'TUD-Stadtmitte';
results = '/home/yuxiang/Projects/Multitarget_Tracking/L2A/results';

% load results
filename = sprintf('%s/%s.mat', results, seq_name);
object = load(filename);
dres_track = object.dres_track;

% write tracking results
filename = sprintf('%s/%s.txt', opt.results, seq_name);
fprintf('write results: %s\n', filename);
write_tracking_results(filename, dres_track);

% evaluation
benchmark_dir = fullfile(opt.mot, opt.mot2d, seq_set, filesep);
evaluateTracking({seq_name}, results, benchmark_dir);