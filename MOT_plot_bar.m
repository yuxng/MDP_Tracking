% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
function MOT_plot_bar

mota_base = [26.6, 26.6, 26.6, 26.6, 26.6, 26.6];
close all;
bar(mota_base, 0.5, 'b');
set(gca, 'FontSize', 16)
hold on;

cmap = colormap;
cmap = cmap(33:64,:);
mota = [25.4, 20.9, 23.6, 23.6, 24.5, 21.4];
num = numel(mota);
for i = 1:numel(mota)
    index_color = 1 + floor((i-1) * size(cmap,1) / num);
    bar(i, mota(i), 0.25, 'Facecolor', cmap(index_color,:));
end
h = legend('Full Model', 'Disable a3 in tracked', ...
    'Disable a6 in lost', 'Disable FB error', 'Disable NCC', ...
    'Disable height ratio', 'Disable distance', 'Location', 'EastOutside');
set(h, 'FontSize', 16);
h = ylabel('MOTA');
set(h, 'FontSize', 16);
h = xlabel('Tracker');
set(h, 'FontSize', 16);
h = title('Framework Analysis');
set(h, 'FontSize', 16);