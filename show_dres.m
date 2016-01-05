% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
%
% draw dres structure
function show_dres(frame_id, I, tit, dres, state, cmap)

if nargin < 5
    state = 1;
end

if nargin < 6
    cmap = colormap;
end

imshow(I);
title(tit);
hold on;

if isempty(dres) == 1
    index = [];
else
    if isfield(dres, 'state') == 1
        index = find(dres.fr == frame_id & dres.state == state);
    else
        index = find(dres.fr == frame_id);
    end
    ids = unique(dres.id);
end

for i = 1:numel(index)
    ind = index(i);
    
    x = dres.x(ind);
    y = dres.y(ind);
    w = dres.w(ind);
    h = dres.h(ind);
    r = dres.r(ind);
    
    if isfield(dres, 'id') && dres.id(ind) > 0
        id = dres.id(ind);
        id_index = find(id == ids);
        str = sprintf('%d', id_index);
        index_color = min(1 + floor((id_index-1) * size(cmap,1) / numel(ids)), size(cmap,1));
        c = cmap(index_color,:);
    else
        c = 'g';
        if isfield(dres, 'type') && strcmp(dres.type{ind}, 'Pedestrian')
            c = 'y';
        end
        if isfield(dres, 'type') && strcmp(dres.type{ind}, 'Cyclist')
            c = 'm';
        end        
        str = sprintf('%.2f', r);
    end
    if isfield(dres, 'occluded') && dres.occluded(ind) > 0
        s = '--';
    else
        s = '-';
    end
    rectangle('Position', [x y w h], 'EdgeColor', c, 'LineWidth', 4, 'LineStyle', s);
    text(x, y-size(I,1)*0.01, str, 'BackgroundColor', [.7 .9 .7], 'FontSize', 14);    

    if isfield(dres, 'id') && dres.id(ind) > 0
        % show the previous path
        ind = find(dres.id == id & dres.fr <= frame_id);
        centers = [dres.x(ind)+dres.w(ind)/2, dres.y(ind)+dres.h(ind)];
        patchline(centers(:,1), centers(:,2), 'LineWidth', 4, 'edgecolor', c, 'edgealpha', 0.3);
    end
end
hold off;