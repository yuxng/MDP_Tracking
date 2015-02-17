% build the graph between two consecutive frames
function dres = build_graph(model, dres, dres_image, opt)

fmax = max(dres.fr);
f1 = find(dres.fr == fmax);   % indices for detections on this frame
f2 = find(dres.fr < fmax);   % indices for detections on the previous frames
tr_num = numel(f2);

for i = 1:length(f1)
    x1 = dres.x(f1(i));
    y1 = dres.y(f1(i));
    x2 = dres.x(f1(i)) + dres.w(f1(i));
    y2 = dres.y(f1(i)) + dres.h(f1(i));      
    
    % compute distances
    cdet = dres.centers{f1(i)};
    distances = zeros(tr_num, 1);
    ratios = zeros(tr_num, 1);
    for j = 1:tr_num
        ctrack = apply_motion_prediction(dres_image.fr, dres, dres.id(f2(j)));
        distances(j) = norm(cdet - ctrack);
        
        ratio = dres.h(f1(i)) ./ dres.h(f2(j));
        ratios(j) = min(ratio, 1/ratio);
    end
    index = find(distances < opt.threshold_dis & ratios > opt.threshold_ratio);
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
        ratio = ratios(ind);
        
        % chi square distance between color histogram
        chisq = -distChiSq(dres.hists{f1(i)}, dres.hists{f2(ind)});
        
        % reconstruction error
        id = dres.id(f2(ind));
        err = 1 - L1APG_reconstruction_error(dres_image.I, model.templates{id}, x1, y1, x2, y2);        
        
        dres.nei(f1(i),1).features{j} = [overlap, distance, ratio, chisq, err];
        dres.nei(f1(i),1).scores(j) = model.weights(model.f_overlap) * overlap + ...
            model.weights(model.f_distance) * distance + ...
            model.weights(model.f_ratio) * ratio + ...
            model.weights(model.f_color) * chisq + ...
            model.weights(model.f_recon) * err;
    end
end

% detection scores
dres.c = model.weights(model.f_det) * dres.r + ...
    model.weights(model.f_cover) * dres.covers + model.weights(model.f_bias);