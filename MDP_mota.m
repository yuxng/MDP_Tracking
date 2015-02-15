% compute the reward using MOTA
function reward = MDP_mota(fr1, fr2, dres_gt, dres_track)

% convert gt
index = find(dres_gt.fr <= fr2 & dres_gt.fr >= fr1);
dres_gt = sub(dres_gt, index);
gtI = convert_dres_to_struct(dres_gt);

% conver track
stI = convert_dres_to_struct(dres_track);

mets = CLEAR_MOT_HUN(gtI, stI);
reward = mets(12);