% LK tracking
function dres_LK = tracking_LK(tlds, dres_track, dres_image, frame_id, opt)

% rescale = opt.LK_rescale;
% rescale_box = opt.LK_rescale_box;
rescale = 1;

J = dres_image.Igray{frame_id};
% J = imresize(J, 0.5);
index = find(dres_track.state ~= 0);
num = numel(index);
dres_LK = sub(dres_track, index);
dres_LK.xFJ = cell(num, 1);
dres_LK.flag = zeros(num, 1);

for i = 1:num
    ind = index(i);
    
    % use the first frame
    id = dres_track.id(ind);
    tmp = find(dres_track.id == id);
    ind = tmp(1);
    
    x1 = dres_track.x(ind);
    y1 = dres_track.y(ind);
    x2 = dres_track.x(ind) + dres_track.w(ind);
    y2 = dres_track.y(ind) + dres_track.h(ind);
    BB1 = [x1; y1; x2; y2] * rescale;
    % BB1 = bb_rescale_relative(BB1, rescale_box);
    fr = dres_track.fr(ind);
    I = dres_image.Igray{fr};
    % I = imresize(I, 0.5);
    
    tld = tlds{id};
    
    [BB2, xFJ, flag] = LK_tracking(tld, BB1, I, J);
    % BB2 = bb_rescale_relative(BB2, 1./rescale_box);
    BB2 = BB2 / rescale;
    xFJ = xFJ / rescale;
    
    dres_LK.x(i) = BB2(1);
    dres_LK.y(i) = BB2(2);
    dres_LK.w(i) = BB2(3) - BB2(1);
    dres_LK.h(i) = BB2(4) - BB2(2);
    dres_LK.fr(i) = frame_id;
    dres_LK.tracked(i) = dres_track.tracked(ind) + 1;
    dres_LK.xFJ{i} = xFJ;
    dres_LK.flag(i) = flag;
end