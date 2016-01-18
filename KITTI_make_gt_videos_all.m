function KITTI_make_gt_videos_all

opt = globals();

seq_set = 'training';
seq_names = opt.kitti_train_seqs;
for i = 1:numel(seq_names)
    KITTI_make_gt_videos(seq_set, i);
end

seq_set = 'testing';
seq_names = opt.kitti_test_seqs;
for i = 1:numel(seq_names)
    KITTI_make_gt_videos(seq_set, i);
end
    