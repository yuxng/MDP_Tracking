function track_YOUTUBE

close all;
seq_name = 'FLUFFYJET_6';
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
bbox = fscanf(fid, '%f', 4);
x1 = bbox(1);
y1 = bbox(2);
x2 = bbox(3);
y2 = bbox(4);
fclose(fid);
img = imread(s_frames{1});
model = L1APG_initialize(img, 1, x1, y1, x2, y2);

% main function for tracking
for t = 2:nframes
    img = imread(s_frames{t});
    [track_res, err, model] = L1APG_track_frame(img, model);
    disp(track_res);
    pause;
end