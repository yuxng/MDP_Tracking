% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
function MOT_plot_bar_new

mota = [26.6, 25.4, 26.6, 20.9, 26.6, 23.6, 26.6, 23.6, 26.6, 24.5, 26.6, 21.4];
close all;
set(gca, 'FontSize', 16)
hold on;

cmap = colormap;
cmap = cmap(33:64,:);
num = numel(mota);
for i = 1:numel(mota)
    if mod(i,2) == 1
        bar(2*i, mota(i), 'Facecolor', 'b');
    else
        index_color = 1 + floor((i-1) * size(cmap,1) / num);
        bar(2*i-1, mota(i), 'Facecolor', cmap(index_color,:));
    end
end
h = ylabel('MOTA');
set(h, 'FontSize', 16);
h = xlabel('Tracker');
set(h, 'FontSize', 16);
h = title('Framework Analysis');
set(h, 'FontSize', 16);