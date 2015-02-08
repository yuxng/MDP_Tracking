function main

opt = globals();

is_train = 1;
seq_idx = 1;

if is_train
    seq_name = opt.mot2d_train_seqs{seq_idx};
    seq_num = opt.mot2d_train_nums(seq_idx);
    seq_set = 'train';
else
    seq_name = opt.mot2d_test_seqs{seq_idx};
    seq_num = opt.mot2d_test_nums(seq_idx);
    seq_set = 'test';
end

% read detections
filename = fullfile(opt.mot, opt.mot2d, seq_set, seq_name, 'det', 'det.txt');
fid = fopen(filename, 'r');
% <frame>, <id>, <bb_left>, <bb_top>, <bb_width>, <bb_height>, <conf>, <x>, <y>, <z>
C = textscan(fid, '%d %d %f %f %f %f %f %f %f %f', 'Delimiter', ',');
fclose(fid);

% build the dres structure for network flow tracking
dres.x = C{3};
dres.y = C{4};
dres.w = C{5};
dres.h = C{6};
dres.r = C{7};
dres.fr = C{1};

%%% Adding transition links to the graph by fiding overlapping detections in consequent frames.
display('in building the graph...')
dres = build_graph(dres);

%%% setting parameters for tracking
c_en      = 10;     %% birth cost
c_ex      = 10;     %% death cost
c_ij      = 0;      %% transition cost
betta     = 0.2;    %% betta
max_it    = inf;    %% max number of iterations (max number of tracks)
thr_cost  = 18;     %% max acceptable cost for a track (increase it to have more tracks.)

%%% Running tracking algorithms
display('in DP tracking ...')
tic;
dres_dp       = tracking_dp(dres, c_en, c_ex, c_ij, betta, thr_cost, max_it, 0);
dres_dp.r     = -dres_dp.id;
toc;
% write tracking results
filename = sprintf('results/%s.txt', seq_name);
fprintf('write results: %s\n', filename);
write_tracking_results(filename, dres_dp);
% evaluation
benchmark_dir = fullfile(opt.mot, opt.mot2d, seq_set, filesep);
evaluateTracking({seq_name}, 'results', benchmark_dir);

tic;
display('in DP tracking with nms in the loop...')
dres_dp_nms   = tracking_dp(dres, c_en, c_ex, c_ij, betta, thr_cost, max_it, 1);
dres_dp_nms.r = -dres_dp_nms.id;
toc;
% write tracking results
filename = sprintf('results/%s.txt', seq_name);
fprintf('write results: %s\n', filename);
write_tracking_results(filename, dres_dp_nms);
% evaluation
benchmark_dir = fullfile(opt.mot, opt.mot2d, seq_set, filesep);
evaluateTracking({seq_name}, 'results', benchmark_dir);

tic;
display('in push relabel algorithm ...')
dres_push_relabel   = tracking_push_relabel(dres, c_en, c_ex, c_ij, betta, max_it);
dres_push_relabel.r = -dres_push_relabel.id;
toc;
% write tracking results
filename = sprintf('results/%s.txt', seq_name);
fprintf('write results: %s\n', filename);
write_tracking_results(filename, dres_push_relabel);
% evaluation
benchmark_dir = fullfile(opt.mot, opt.mot2d, seq_set, filesep);
evaluateTracking({seq_name}, 'results', benchmark_dir);