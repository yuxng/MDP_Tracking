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

% build the dres structure for detections
dres_all.fr = C{1};
dres_all.id = C{2};
dres_all.x = C{3};
dres_all.y = C{4};
dres_all.w = C{5};
dres_all.h = C{6};
dres_all.r = C{7} / opt.det_normalization;
num_det = numel(dres_all.fr);
dres_all.state = cell(num_det, 1);
dres_all.lost = zeros(num_det, 1);
dres_all.tracked = zeros(num_det, 1);

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

for t = 1:MDP.T
    fprintf('iter %d, interval %d\n', t, MDP.intervals(t));
    for i = 1:seq_num
        % extract detections
        index = find(dres_all.fr == i);
        dres = sub(dres_all, index);
        num_det = numel(index);

        % show image
        filename = fullfile(opt.mot, opt.mot2d, seq_set, seq_name, 'img1', sprintf('%06d.jpg', i));
        disp(filename);
        I = imread(filename);

        dres_image.x = 1;
        dres_image.y = 1;
        dres_image.w = size(I, 2);
        dres_image.h = size(I, 1);
        dres_image.I = I;

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

        if mod(i, MDP.intervals(t)) == 1
            fprintf('initialization\n');
            % initialization
            dres_track = dres;
            ID = 0;
            for j = 1:num_det
                ID = ID + 1;
                dres_track.id(j) = ID;
                dres_track.tracked(j) = 1;
                dres_track.state{j} = 'active';
                fprintf('target %d enter\n', ID);
            end
        else
            % compute value function
            [qscore, f, dres_track] = MDP_value(MDP, dres_track, dres, dres_image, 1);

            % compute the value for the new state
            if mod(i, MDP.intervals(t)) ~= 0 && i ~= seq_num
                reward = -1;
                dres_next = sub(dres_all, find(dres_all.fr == i+1)); 
                qscore_new = MDP_value(MDP, dres_track, dres_next, dres_image, 0);
                fprintf('qscore %f, qscore_new %f, reward %f\n', qscore, qscore_new, reward);
                difference = reward + MDP.gamma * qscore_new - qscore;
            else
                reward = MDP_mota(i-MDP.intervals(t)+1, i, dres_gt, dres_track);
                fprintf('qscore %f, \n\nreward %f\n\n', qscore, reward);
                difference = reward - qscore;
            end

            % update weights
            MDP = MDP_update(MDP, difference, f);
        end

        % show tracking results
        if is_show
            subplot(2, 2, 3);
            imshow(I);
            title('Tracking');
            hold on;
            index = find(dres_track.fr == i & ...
                (strcmp('tracked', dres_track.state) | strcmp('active', dres_track.state)));
            for j = 1:numel(index)
                x = dres_track.x(index(j));
                y = dres_track.y(index(j));
                w = dres_track.w(index(j));
                h = dres_track.h(index(j));
                id = dres_track.id(index(j));
                index_color = min(1 + floor((id-1) * size(cmap,1) / max(dres_track.id)), size(cmap,1));
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
                index_color = min(1 + floor((id-1) * size(cmap,1) / max(dres_track.id)), size(cmap,1));
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
            pause();
        end
    end
end