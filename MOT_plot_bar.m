function MOT_plot_bar

mota_base = [26.6, 26.6, 26.6, 26.6, 26.6, 26.6, 26.6];
close all;
bar(mota_base, 0.5, 'b');
set(gca, 'FontSize', 16)
hold on;

cmap = colormap;
cmap = cmap(33:64,:);
mota = [12.9, 25.4, 20.9, 23.6, 23.6, 24.5, 21.4];
num = numel(mota);
for i = 1:numel(mota)
    index_color = 1 + floor((i-1) * size(cmap,1) / num);
    bar(i, mota(i), 0.25, 'Facecolor', cmap(index_color,:));
end
h = legend('Full Model', '1. Disable a2 in active', '2. Disable a3 in tracked', ...
    '3. Disable a6 in lost', '4. Disable FB error', '5. Disable NCC', ...
    '6. Disable height ratio', '7. Disable distance', 'Location', 'EastOutside');
set(h, 'FontSize', 16);
h = ylabel('MOTA');
set(h, 'FontSize', 16);
h = xlabel('Tracker');
set(h, 'FontSize', 16);
h = title('Framework Analysis');
set(h, 'FontSize', 16);