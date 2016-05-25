% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
%
% read NTHU detection file
function dres = read_nthu2dres(filename)

if isempty(strfind(filename, 'detection'))
    is_gt = 1;
else
    is_gt = 0;
end

% count columns
fid = fopen(filename, 'r');
l = strtrim(fgetl(fid));
fclose(fid);

if strcmp(l(1:3), '000') == 0
    dres.fr = [];
    dres.id = [];
    dres.type = [];
    dres.x = [];
    dres.y = [];
    dres.w = [];
    dres.h = [];
    dres.r = [];
    return;
end

% The format of ground truth:
% <image ID> <tracker ID> <category> <x1> <y1> <x2> <y2>

% The format of detection result:
% <image ID> <category> <x1> <y1> <x2> <y2> <score>

fid = fopen(filename);
try
    if is_gt % ground truth file
        C = textscan(fid, '%d %d %s %f %f %f %f');
    else
        C = textscan(fid, '%d %s %f %f %f %f %f');
    end
catch
    error('This file is not in NTHU data format.');
end
fclose(fid);

% build the dres structure for detections
dres.fr = C{1};  % 1-based frame
if is_gt
    dres.id = C{2};  % 1-based id
    dres.type = C{3};
    dres.x = C{4};
    dres.y = C{5};
    dres.w = C{6}-C{4}+1;
    dres.h = C{7}-C{5}+1;
    dres.r = zeros(size(C{1}));
else
    dres.id = -1 * ones(size(C{1}));
    dres.type = C{2};
    dres.x = C{3};
    dres.y = C{4};
    dres.w = C{5}-C{3}+1;
    dres.h = C{6}-C{4}+1;    
    dres.r = C{7};
end