function dres = model_compute_features(dres, dres_image)

% compute features for the dres
n = numel(dres.x);
centers = cell(n, 1);
hists = cell(n, 1);
covers = zeros(n, 1);
for i = 1:n
    centers{i} = [dres.x(i)+dres.w(i)/2 dres.y(i)+dres.h(i)/2];
    I = imcrop(dres_image.I, [dres.x(i) dres.y(i) dres.w(i) dres.h(i)]);
    I = imresize(I, [24 12]);
    hists{i} = rgbhist(I, 4, 1)';
    [~, ov] = calc_overlap(dres, i, dres, 1:n);
    covers(i) = -sum(ov(dres.r(i) < dres.r));
end
dres.centers = centers;
dres.hists = hists;
dres.covers = covers;