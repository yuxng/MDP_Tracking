% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
function MOT_copy_images

% test sequences
seqs = {'TUD-Crossing', 'PETS09-S2L2', 'ETH-Jelmoli', ...
    'ETH-Linthescher', 'ETH-Crossing', 'AVG-TownCentre', 'ADL-Rundle-1', ...
    'ADL-Rundle-3', 'KITTI-16', 'KITTI-19', 'Venice-1'};

indexes = {{31, 107}, {68, 111}, {82, 215}, {51, 78}, {97}, {52, 220} ...
    {232}, {183}, {90}, {281}, {235}};

for i = 1:numel(seqs)
    seq_name = seqs{i};
    index = indexes{i};
    
    for j = 1:numel(index)
        ind = index{j};
        file_src = sprintf('results_MOT/results_MOT_1/%s/%06d.png', seq_name, ind);
        disp(file_src);
        file_dst = sprintf('figures/%s_%06d.png', seq_name, ind);
        copyfile(file_src, file_dst);
    end
      
end