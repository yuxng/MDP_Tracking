% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
function MOT_display_results

is_save = 1;

opt = globals();
N = numel(opt.mot2d_test_seqs);
seq_set = 'test';

for seq_idx = 1:N
    close all;
    hf = figure(1);
    seq_name = opt.mot2d_test_seqs{seq_idx};
    seq_num = opt.mot2d_test_nums(seq_idx);
    
    % build the dres structure for images
    filename = sprintf('%s/%s_dres_image.mat', opt.results, seq_name);
    if exist(filename, 'file') ~= 0
        object = load(filename);
        dres_image = object.dres_image;
        fprintf('load images from file %s done\n', filename);
    else
        dres_image = read_dres_image(opt, seq_set, seq_name, seq_num);
        fprintf('read images done\n');
        save(filename, 'dres_image', '-v7.3');
    end
    
    % read tracking results
    filename = sprintf('results_MOT/results_MOT_1/%s.txt', seq_name);
    dres_track = read_mot2dres(filename);
    fprintf('read tracking results from %s\n', filename);
    ids = unique(dres_track.id);
    cmap = colormap(hsv(numel(ids)));
    cmap = cmap(randperm(numel(ids)),:);
    
    if is_save
        result_dir = sprintf('results_MOT/results_MOT_1/%s', seq_name);
        if exist(result_dir, 'dir') == 0
            mkdir(result_dir);
        end
    end
    
    for fr = 1:seq_num
        show_dres(fr, dres_image.I{fr}, '', dres_track, 2, cmap);
        if is_save
            filename = sprintf('%s/%06d.png', result_dir, fr);
            hgexport(hf, filename, hgexport('factorystyle'), 'Format', 'png');
            % saveas(hf, filename);
        else
            pause;
        end
    end
end