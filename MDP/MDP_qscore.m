% Q function
function [qscore, f] = MDP_qscore(MDP, dres_track, ind_track, dres, ind, action, dres_image)

% build the feature vector
f = zeros(MDP.fnum, 1);

% overlap with other targets
index = find(~strcmp('inactive', dres_track.state));
index(index == ind_track) = [];
[~, overlap] = calc_overlap(dres_track, ind_track, dres_track, index);
f(1) = max(overlap);

% percentage of area outside image
[~, overlap] = calc_overlap(dres_track, ind_track, dres_image, 1);
f(2) = 1 - overlap;

if strcmp(action, 'link') == 1
    % overlap between detection and track
    overlap = calc_overlap(dres_track, ind_track, dres, ind);
    f(3) = overlap;
    % distance between detection and track
    ctrack = [dres_track.x(ind_track)+dres_track.w(ind_track)/2, ...
        dres_track.y(ind_track)+dres_track.h(ind_track)/2];
    cdet = [dres.x(ind)+dres.w(ind)/2, dres.y(ind)+dres.h(ind)/2];
    distance = norm(ctrack - cdet);
    f(4) = -distance / dres_image.h;
    % aspect ratio between detection and track
    ratio = dres_track.h(ind_track) ./ dres.h(ind);
    ratio  = min(ratio, 1/ratio);
    f(5) = ratio;
    % detection score
    score = dres.r(ind);
    f(6) = score/100;
elseif strcmp(action, 'hold') == 1
    f(7) = 1;
elseif strcmp(action, 'terminate') == 1
    f(8) = 1;
end

qscore = dot(MDP.weights, f);