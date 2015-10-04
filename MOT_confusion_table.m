% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
function MOT_confusion_table

close all;
data = [56.0, 46.8, 14.0, 20.0, 30.8, 60.8;
        44.8, 43.4, 13.3, 22.6, 30.8, 60.3;
        47.9, 48.2, 11.5, 26.1, 29.8, 57.8;
        53.2, 47.5, 13.9, 20.9, 32.1, 59.9;
        49.0, 42.1, 11.5, 22.1, 29.4, 61.2];

C = data;
% for i = 1:size(C, 2)
%     s = sum(C(:,i));
%     C(:,i) = C(:,i) / s;
% end
C = 100 * C;
 
imagesc(C);  
colormap(flipud(gray)); 

textStrings = num2str(data(:),'%0.1f');       % Create strings from the matrix values
textStrings = strtrim(cellstr(textStrings));  % Remove any space padding

[x,y] = meshgrid(1:6, 1:5);   %# Create x and y coordinates for the strings
hStrings = text(x(:), y(:),textStrings(:),...      %# Plot the strings
                'HorizontalAlignment','center');
midValue = mean(get(gca,'CLim'));  %# Get the middle value of the color range
textColors = repmat(C(:) > midValue,1,3);  %# Choose white or black for the
                                             %#   text color of the strings so
                                             %#   they can be easily seen over
                                             %#   the background color
set(hStrings,{'Color'},num2cell(textColors,2));  %# Change the text colors

set(gca,'XTick',1:6,...                         %# Change the axes tick marks
        'XTickLabel',{'TUD-Campus','ETH-Sunnyday', 'ETH-Pedcross2', 'ADL-Rundle-8','Venice-2', 'KITTI-17'},...  %#   and tick labels
        'YTick',1:5,...
        'YTickLabel',{'TUD-Stadtmitte','ETH-Sunnyday','ADL-Rundle-6','KITTI-13','PETS09-S2L1'},...
        'TickLength',[0 0], ...
        'Fontsize', 12);
xlabel('Testing Sequences');    
ylabel('Training Sequences');
title('MOTA');

rotateXLabels(gca, -25);