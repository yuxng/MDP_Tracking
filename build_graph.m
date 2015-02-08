% build the graph between two consecutive frames
function [dres, tr_num] = build_graph(img, dres, models)

fmax = max(dres.fr);
f1 = find(dres.fr == fmax);   % indices for detections on this frame
f2 = find(dres.fr < fmax);   % indices for detections on the previous frames

for i = 1:length(f1)
    x1 = dres.x(f1(i));
    y1 = dres.y(f1(i));
    x2 = dres.x(f1(i)) + dres.w(f1(i));
    y2 = dres.y(f1(i)) + dres.h(f1(i));
    cx = (x1 + x2) / 2;
    cy = (y1 + y2) / 2;
    
    % compute the distance between detection and prediction
    num = numel(f2);
    dis = zeros(num, 1);
    for j = 1:num
        dis(j) = norm(models{dres.id(f2(j))}.prediction - [cx cy]);
    end
    
    % we ignore transitions with large change in the size of bounding boxes.
    ratio1 = dres.h(f1(i)) ./ dres.h(f2);
    inds  = find(min(ratio1, 1./ratio1) > 0.7 & dis < 50);          

    % each detction window will have a list of indices pointing to its neighbors in the previous frame.
    dres.nei(f1(i),1).inds  = f2(inds)';
    
    % compute the matching scores
    num = numel(inds);
    dres.nei(f1(i),1).scores = zeros(num, 1);
    for j = 1:num
        id = dres.id(inds(j));
        err = L1APG_reconstruction_error(img, models{id}, x1, y1, x2, y2); % appearance affinity
        dres.nei(f1(i),1).scores(j) = err * (1 - pdf('Normal', dis(inds(j)), 0, 10));
    end
end

tr_num = numel(f2);