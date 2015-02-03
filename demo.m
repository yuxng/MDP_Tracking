function demo

opt = globals();

is_train = 1;
seq_idx = 4;

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

% read ground truth
filename = fullfile(opt.mot, opt.mot2d, seq_set, seq_name, 'gt', 'gt.txt');
fid = fopen(filename, 'r');
% <frame>, <id>, <bb_left>, <bb_top>, <bb_width>, <bb_height>, <conf>, <x>, <y>, <z>
Cgt = textscan(fid, '%d %d %f %f %f %f %f %f %f %f', 'Delimiter', ',');
fclose(fid);

figure(1);

% show detection results
for i = 1:seq_num
    % show image
    filename = fullfile(opt.mot, opt.mot2d, seq_set, seq_name, 'img1', sprintf('%06d.jpg', i));
    I = imread(filename);
    
    subplot(1, 2, 1);
    imshow(I);
    hold on;
    
    % show ground truth
    index = find(Cgt{1} == i);
    for j = 1:numel(index)
        x = Cgt{3}(index(j));
        y = Cgt{4}(index(j));
        w = Cgt{5}(index(j));
        h = Cgt{6}(index(j));
        rectangle('Position', [x y w h], 'EdgeColor', 'g', 'LineWidth', 2);
    end
    hold off;
    
    subplot(1, 2, 2);
    imshow(I);
    hold on;    
    
    % show detections
    index = find(C{1} == i);
    for j = 1:numel(index)
        x = C{3}(index(j));
        y = C{4}(index(j));
        w = C{5}(index(j));
        h = C{6}(index(j));
        r = C{7}(index(j));
        rectangle('Position', [x y w h], 'EdgeColor', 'g', 'LineWidth', 2);
        text(x, y, sprintf('%.2f', r), 'BackgroundColor',[.7 .9 .7]);
    end
    hold off;
    
    % build the dres structure for network flow tracking
    dres.x = C{3}(index);
    dres.y = C{4}(index);
    dres.w = C{5}(index);
    dres.h = C{6}(index);
    dres.r = C{7}(index);
    dres.fr = i * ones(numel(index), 1);
    
    if i == 1
        dres_track = dres;
    else
        % network flow tracking
        dres = concatenate_dres(dres_track, dres);
        dres_track = tracking(dres);
    end
%     pause;
end