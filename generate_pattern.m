% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
function pattern = generate_pattern(img, bb, patchsize)
% get patch under bounding box (bb), normalize it size, reshape to a column
% vector and normalize to zero mean and unit variance (ZMUV)

% initialize output variable
nBB = size(bb,2);
pattern = zeros(prod(patchsize),nBB);
% for every bounding box
for i = 1:nBB
    % sample patch
    patch = img_patch(img, bb(:,i));
    
    % normalize size to 'patchsize' and nomalize intensities to ZMUV
    pattern(:,i) = tldPatch2Pattern(patch,patchsize);
end

function pattern = tldPatch2Pattern(patch, patchsize)

patch   = imresize(patch, patchsize); % 'bilinear' is faster
pattern = double(patch(:));
pattern = pattern - mean(pattern);