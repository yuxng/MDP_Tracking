% Q function
function qscore = MDP_qscore(MDP, dres_track, ind_track, dres, ind, action)

% build the feature vector
f = zeros(MDP.fnum, 1);
if strcmp(action, 'link') == 1
    % overlap between detection and track
    overlap = calc_overlap(dres_track, ind_track, dres, ind);
    f(1) = overlap;
    % distance between detection and track
    ctrack = [dres_track.x(ind_track)+dres_track.w(ind_track)/2, ...
        dres_track.y(ind_track)+dres_track.h(ind_track)/2];
    cdet = [dres.x(ind)+dres.w(ind)/2, dres.y(ind)+dres.h(ind)/2];
    distance = norm(ctrack - cdet);
    f(2) = 1/distance;
    % aspect ratio between detection and track
    ratio = dres_track.h(ind_track) ./ dres.h(ind);
    ratio  = min(ratio, 1/ratio);
    f(3) = ratio;
    % detection score
    score = dres.r(ind);
    f(4) = score;
elseif strcmp(action, 'hold') == 1
    f(5) = 1;
elseif strcmp(action, 'terminate') == 1
    f(6) = 1;
end

qscore = dot(MDP.weights, f);