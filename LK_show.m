% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
%
% show LK tracking results
function LK_show(im1, im2, xFI, BB1, xFJ, BB2)

% Create a new image showing the two images side by side.
im3 = appendimages(im1,im2);

% Show a figure with lines joining the accepted matches.
h = figure(2);
set(h, 'Position', [100 100 2*size(im3,2) 2*size(im3,1)]);
axis equal;
colormap('gray');
imagesc(im3);
hold on;
cols1 = size(im1,2);
loc1 = xFI(1:2,:)';
loc2 = xFJ(1:2,:)';
plot(loc1(:,1), loc1(:,2), 'ro', 'LineWidth', 2);
plot(loc2(:,1)+cols1, loc2(:,2), 'yo', 'LineWidth', 2);
for i = 1: size(loc1,1)
    if isnan(loc2(i,1)) == 0
        line([loc1(i,1) loc2(i,1)+cols1], [loc1(i,2) loc2(i,2)], 'Color', 'c', 'LineWidth', 2);
    end
end

rectangle('Position', [BB1(1) BB1(2) BB1(3)-BB1(1) BB1(4)-BB1(2)], 'EdgeColor', 'g', 'LineWidth', 4);
rectangle('Position', [BB2(1)+cols1 BB2(2) BB2(3)-BB2(1) BB2(4)-BB2(2)], 'EdgeColor', 'y', 'LineWidth', 4);
axis off;
hold off;

% Return a new image that appends the two images side-by-side.

function im = appendimages(image1, image2)

% Select the image with the fewest rows and fill in enough empty rows
%   to make it the same height as the other image.
rows1 = size(image1,1);
rows2 = size(image2,1);

if (rows1 < rows2)
     image1(rows2,1) = 0;
else
     image2(rows1,1) = 0;
end

% Now append both images side-by-side.
im = [image1 image2];