function compute_seq_nums

opt = globals;

fprintf('\n2D training sequences\n');
for i = 1:numel(opt.mot2d_train_seqs)
    filename = fullfile(opt.mot, opt.mot2d, 'train', opt.mot2d_train_seqs{i}, ...
        'img1', '*.jpg');
    files = dir(filename);
    fprintf('%s %d\n', opt.mot2d_train_seqs{i}, numel(files));
end

fprintf('\n2D testing sequences\n');
for i = 1:numel(opt.mot2d_test_seqs)
    filename = fullfile(opt.mot, opt.mot2d, 'test', opt.mot2d_test_seqs{i}, ...
        'img1', '*.jpg');
    files = dir(filename);
    fprintf('%s %d\n', opt.mot2d_test_seqs{i}, numel(files));
end