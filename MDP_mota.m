% compute the reward using MOTA
function reward = MDP_mota(fr, dres_gt, dres_track)

% convert gt
index = find(dres_gt.fr <= fr);
dres_gt = sub(dres_gt, index);
gtI = convert_dres_to_struct(dres_gt, fr);

% conver track
stI = convert_dres_to_struct(dres_track, fr);

mets = CLEAR_MOT_HUN(gtI, stI);
reward = mets(12);