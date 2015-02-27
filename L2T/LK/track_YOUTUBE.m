function track_YOUTUBE

close all;
seq_name = 'FLUFFYJET_1';
root_path = '/home/yuxiang/Projects/Multiview_Tracking/dataset/YOUTUBE/';

%prepare the file name for each image
filenames = textread(fullfile(root_path, seq_name, 'img', 'imlist.txt'), '%s');
nframes = numel(filenames);
s_frames = cell(nframes,1);
for t = 1:nframes
    s_frames{t} = fullfile(root_path, seq_name, 'img', filenames{t});
end

% read initial bounding box
filename = fullfile(root_path, seq_name, 'img', 'init.txt');
fid = fopen(filename, 'r');
BB1 = fscanf(fid, '%f', 4);
fclose(fid);
imgI = imread(s_frames{1});
if ndims(imgI) == 3
    imgI = rgb2gray(imgI);
end

figure(1);
imshow(imgI);
bb_draw(BB1, 'linewidth', 2, 'edgecolor', 'g', 'curvature', [0 0]);

% main function for tracking
for t = 2:nframes
    imgJ = imread(s_frames{t});
    if ndims(imgJ) == 3
        imgJ = rgb2gray(imgJ);
    end    
    [BB2, xFJ] = LK_tracking(BB1, imgI, imgJ);
    
    imshow(imgJ);
    hold on;
    bb_draw(BB2, 'linewidth', 2, 'edgecolor', 'g', 'curvature', [0 0]);
    plot(xFJ(1,:), xFJ(2,:), 'gs', 'MarkerSize', 10);
    hold off;
    
    imgI = imgJ;
    BB1 = BB2;
    pause;
end