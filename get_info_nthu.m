% get the NTHU dataset information
function opt = get_info_nthu(opt)

root = opt.nthu;
max_num = 1000;

% train set
path = fullfile(root, 'train', 'images');
nthu_train_seqs = cell(1, max_num);
nthu_train_nums = zeros(1, max_num);
count = 0;

for i = 1:max_num
    dir_name = sprintf('%06d', i);
    if exist(fullfile(path, dir_name), 'dir')
        count = count + 1;
        nthu_train_seqs{count} = dir_name;
        % count the number of frames
        filename = fullfile(path, dir_name, '*.jpg');
        nthu_train_nums(count) = numel(dir(filename));
    end
end
opt.nthu_train_seqs = nthu_train_seqs(1:count);
opt.nthu_train_nums = nthu_train_nums(1:count);

% test set
path = fullfile(root, 'test', 'images');
nthu_test_seqs = cell(1, max_num);
nthu_test_nums = zeros(1, max_num);
count = 0;

for i = 1:max_num
    dir_name = sprintf('%06d', i);
    if exist(fullfile(path, dir_name), 'dir')
        count = count + 1;
        nthu_test_seqs{count} = dir_name;
        % count the number of frames
        filename = fullfile(path, dir_name, '*.jpg');
        nthu_test_nums(count) = numel(dir(filename));
    end
end
opt.nthu_test_seqs = nthu_test_seqs(1:count);
opt.nthu_test_nums = nthu_test_nums(1:count);