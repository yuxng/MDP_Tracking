% build the graph between two consecutive frames
function [dres, tr_num] = build_graph(MDP, dres, dres_image)

fmax = max(dres.fr);
f1 = find(dres.fr == fmax);   % indices for detections on this frame
f2 = find(dres.fr < fmax);   % indices for detections on the previous frames
tr_num = numel(f2);

% compute features for the dres
n = numel(dres.x);
centers = cell(n, 1);
hists = cell(n, 1);
for i = 1:n
    centers{i} = [dres.x(i)+dres.w(i)/2 dres.y(i)+dres.h(i)/2];
    I = imcrop(dres_image.I, [dres.x(i) dres.y(i) dres.w(i) dres.h(i)]);
    hists{i} = rgbhist(I, 4, 1)';
end

for i = 1:length(f1)
    % detection center
    cdet = centers{f1(i)};
    
    % each detction window will have a list of indices pointing to its neighbors in the previous frame.
    dres.nei(f1(i),1).inds  = f2;
    
    % compute the matching scores
    dres.nei(f1(i),1).scores = zeros(tr_num, 1);
    dres.nei(f1(i),1).features = cell(tr_num, 1);
    for j = 1:tr_num
        % overlap between detection and track
        overlap = calc_overlap(dres, f1(i), dres, f2(j));
        
        % distance between detection and track
        ctrack = centers{f2(j)};
        distance = -norm(cdet - ctrack) / dres_image.h;
        
        % aspect ratio between detection and track
        ratio = dres.h(f1(i)) ./ dres.h(f2(j));
        ratio  = min(ratio, 1/ratio);
        
        % chi square distance between color histogram
        chisq = distChiSq(hists{f1(i)}, hists{f2(j)});
        
        dres.nei(f1(i),1).features{j} = [overlap, distance, ratio, chisq];
        dres.nei(f1(i),1).scores(j) = MDP.weights(1) * overlap + ...
            MDP.weights(2) * distance + ...
            MDP.weights(3) * ratio + ...
            MDP.weights(4) * chisq;
    end
end