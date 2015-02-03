% build the graph between two consecutive frames
function dres = build_graph(dres)

fr = unique(dres.fr);
assert(numel(fr) == 2);

fmin = min(fr);
fmax = max(fr);
assert(fmax == fmin + 1);

ov_thresh = 0.5;

f1 = find(dres.fr == fmax);   % indices for detections on this frame
f2 = find(dres.fr == fmin);   % indices for detections on the previous frame
for i = 1:length(f1)
    % find overlapping bounding boxes.  
    ovs1  = calc_overlap(dres, f1(i), dres, f2);   
    inds1 = find(ovs1 > ov_thresh);

    % we ignore transitions with large change in the size of bounding boxes.
    ratio1 = dres.h(f1(i)) ./ dres.h(f2(inds1));
    inds2  = (min(ratio1, 1./ratio1) > 0.8);          

    % each detction window will have a list of indices pointing to its neighbors in the previous frame.
    dres.nei(f1(i),1).inds  = f2(inds1(inds2))';
end