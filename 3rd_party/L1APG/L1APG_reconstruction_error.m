% compute the reconstruction error
function err = L1APG_reconstruction_error(img, model, x1, y1, x2, y2)

para = model.para;
para.Lambda = model.Lambda;
pos = [y1, y2, y1; x1 x1 x2];
sz_T = para.sz_T;
nT = para.nT;

% get affine transformation parameters from the corner points
aff_obj = corners2affine(pos, sz_T);
map_aff = aff_obj.afnv;

%-Crop candidate targets "Y" according to the transformation samples
[Y, Y_inrange] = crop_candidates(im2double(img), map_aff, sz_T);
if Y_inrange == 0
    fprintf('Target is out of the frame!\n');
end

Y = whitening(Y); % zero-mean-unit-variance
Y = normalizeTemplates(Y);    % norm one
c = APGLASSOup(model.Temp'*Y, model.Dict, para);
D_s = (Y - model.A(:,1:nT)*c(1:nT)).^2; % reconstruction error
err = sum(D_s);