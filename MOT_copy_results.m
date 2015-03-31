function MOT_copy_results

seqs = {'TUD-Crossing', 'PETS09-S2L2', 'ETH-Jelmoli', ...
    'ETH-Linthescher', 'ETH-Crossing', 'AVG-TownCentre', 'ADL-Rundle-1', ...
    'ADL-Rundle-3', 'KITTI-16', 'KITTI-19', 'Venice-1'};

for i = 1:numel(seqs)
    file_src = sprintf('results/%s.txt', seqs{i});
    disp(file_src);
    file_dst = sprintf('results_MOT/%s.txt', seqs{i});
    copyfile(file_src, file_dst);
end