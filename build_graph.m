% build the graph between two consecutive frames
function dres = build_graph(model, dres, dres_image, opt)

fmax = max(dres.fr);
f1 = find(dres.fr == fmax);   % indices for detections on this frame
f2 = find(dres.fr < fmax);   % indices for detections on the previous frames
tr_num = numel(f2);

for i = 1:length(f1)
    % compute distances
    cdet = dres.centers{f1(i)};
    distances = zeros(tr_num, 1);
    for j = 1:tr_num
        ctrack = dres.centers{f2(j)};
        distances(j) = norm(cdet - ctrack);
    end
    index = find(distances < opt.threshold_dis);
    num = numel(index);
    
    % each detction window will have a list of indices pointing to its neighbors in the previous frame.
    dres.nei(f1(i),1).inds  = f2(index);
    
    % compute the matching scores
    dres.nei(f1(i),1).scores = zeros(num, 1);
    dres.nei(f1(i),1).features = cell(num, 1);
    for j = 1:num
        ind = index(j);
        % overlap between detection and track
        overlap = calc_overlap(dres, f1(i), dres, f2(ind));
        
        % distance between detection and track
        distance = -distances(ind) / dres_image.h;
        
        % aspect ratio between detection and track
        ratio = dres.h(f1(i)) ./ dres.h(f2(ind));
        ratio = min(ratio, 1/ratio);
        
        % chi square distance between color histogram
        chisq = -distChiSq(dres.hists{f1(i)}, dres.hists{f2(ind)});
        
        dres.nei(f1(i),1).features{j} = [overlap, distance, ratio, chisq];
        dres.nei(f1(i),1).scores(j) = model.weights(model.f_overlap) * overlap + ...
            model.weights(model.f_distance) * distance + ...
            model.weights(model.f_ratio) * ratio + ...
            model.weights(model.f_color) * chisq;
    end
end

% detection scores
dres.c = model.weights(model.f_det) * dres.r + ...
    model.weights(model.f_cover) * dres.covers + model.weights(model.f_bias);