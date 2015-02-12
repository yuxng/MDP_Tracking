function MDP_learning

opt = globals();
MDP = MDP_initialize();

seq_idx = 1;
is_show = 1;
seq_name = opt.mot2d_train_seqs{seq_idx};
seq_num = opt.mot2d_train_nums(seq_idx);
seq_set = 'train';

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

% build the dres structure for ground truth
dres_gt.fr = Cgt{1};
dres_gt.id = Cgt{2};
dres_gt.x = Cgt{3};
dres_gt.y = Cgt{4};
dres_gt.w = Cgt{5};
dres_gt.h = Cgt{6};
dres_gt.r = Cgt{7};

if is_show
    figure(1);
    cmap = colormap;
end
ID = 0;
dres_track = [];

% show detection results
for i = 1:seq_num
    % show image
    filename = fullfile(opt.mot, opt.mot2d, seq_set, seq_name, 'img1', sprintf('%06d.jpg', i));
    disp(filename);
    I = imread(filename);
    
    % show ground truth
    if is_show
        subplot(2, 2, 1);
        imshow(I);
        title('GT');
        hold on;
        index = find(Cgt{1} == i);
        for j = 1:numel(index)
            x = Cgt{3}(index(j));
            y = Cgt{4}(index(j));
            w = Cgt{5}(index(j));
            h = Cgt{6}(index(j));
            rectangle('Position', [x y w h], 'EdgeColor', 'g', 'LineWidth', 2);
        end
        hold off;
    end  
    
    % build the dres structure for detections
    index = find(C{1} == i);
    num_det = numel(index);
    dres.x = C{3}(index);
    dres.y = C{4}(index);
    dres.w = C{5}(index);
    dres.h = C{6}(index);
    dres.r = C{7}(index);
    dres.fr = i * ones(num_det, 1);
    dres.state = cell(num_det, 1);
    dres.id = -1 * ones(num_det, 1);
    dres.lost = zeros(num_det, 1);
    dres.tracked = zeros(num_det, 1);
    
    % show detections
    if is_show
        subplot(2, 2, 2);
        imshow(I);
        title('Detections');
        hold on;    
        for j = 1:num_det
            x = dres.x(j);
            y = dres.y(j);
            w = dres.w(j);
            h = dres.h(j);
            r = dres.r(j);
            rectangle('Position', [x y w h], 'EdgeColor', 'g', 'LineWidth', 2);
            text(x, y, sprintf('%.2f', r), 'BackgroundColor',[.7 .9 .7]);
        end
        hold off;
    end
    
    if i == 1
        % initialization
        dres_track = dres;
        for j = 1:num_det
            ID = ID + 1;
            dres_track.id(j) = ID;
            dres_track.tracked(j) = 1;
            dres_track.state{j} = 'active';
            fprintf('target %d enter\n', ID);
        end
        mota = MDP_mota(i, dres_gt, dres_track);
        fprintf('mota %f\n', mota);
    else
        % find targets in the previous frame
        index = find(~strcmp('inactive', dres_track.state));
        % select an action for each target
        num = numel(index);
        actions_all = cell(num, 1);
        index_det_all = zeros(num, 1);
        for j = 1:num
            % find the possible actions for this target
            actions = MDP.actable_actions(MDP, dres_track.state{index(j)});
            % for link action, it should be expanded according to detections
            [actions, index_det] = MDP.expand_link(actions, num_det);
            % select the action maximizing the Q-function
            num_action = numel(actions);
            qscores = zeros(num_action, 1);
            for k = 1:num_action
                qscores(k) = MDP_qscore(MDP, dres_track, index(j), dres, index_det(k), actions{k});
            end
            [~, ind] = max(qscores);
            actions_all{j} = actions{ind};
            index_det_all(j) = index_det(ind);
        end
        % execuate the actions
        dres_track = MDP_execute_action(MDP, dres_track, index, dres, actions_all, index_det_all);
        % compute reward
        mota_new = MDP_mota(i, dres_gt, dres_track);
        reward = mota_new - mota;
        fprintf('mota %f, reward %f\n', mota_new, reward);
    end
    
    % show tracking results
    if is_show
        subplot(2, 2, 3);
        imshow(I);
        title('Tracking');
        hold on;
        index = find(dres_track.fr == i & strcmp('tracked', dres_track.state));
        for j = 1:numel(index)
            x = dres_track.x(index(j));
            y = dres_track.y(index(j));
            w = dres_track.w(index(j));
            h = dres_track.h(index(j));
            id = dres_track.id(index(j));
            index_color = 1 + floor((id-1) * size(cmap,1) / ID);
            rectangle('Position', [x y w h], 'EdgeColor', cmap(index_color,:), 'LineWidth', 2);
            text(x, y, sprintf('%d', id), 'BackgroundColor',[.7 .9 .7]);
            % show the previous path
            ind = find(dres_track.id == id);
            centers = [dres_track.x(ind)+dres_track.w(ind)/2 ...
                dres_track.y(ind)+dres_track.h(ind)/2];
            plot(centers(:,1), centers(:,2), 'LineWidth', 2, 'Color', cmap(index_color,:));
        end
        hold off;

        % show lost targets
        subplot(2, 2, 4);
        imshow(I);
        title('Lost Tracks');
        hold on;
        index = find(dres_track.fr == i & strcmp('lost', dres_track.state));
        for j = 1:numel(index)
            x = dres_track.x(index(j));
            y = dres_track.y(index(j));
            w = dres_track.w(index(j));
            h = dres_track.h(index(j));
            id = dres_track.id(index(j));
            index_color = 1 + floor((id-1) * size(cmap,1) / ID);
            rectangle('Position', [x y w h], 'EdgeColor', cmap(index_color,:), 'LineWidth', 2);
            text(x, y, sprintf('%d', id), 'BackgroundColor',[.7 .9 .7]);
            % show the previous path
            ind = find(dres_track.id == id);
            centers = [dres_track.x(ind)+dres_track.w(ind)/2 ...
                dres_track.y(ind)+dres_track.h(ind)/2];
            plot(centers(:,1), centers(:,2), 'LineWidth', 2, 'Color', cmap(index_color,:));        
        end
        hold off;    
    end
    
    if is_show
        pause;
    end
end