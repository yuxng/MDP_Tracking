function [crop,crop_norm,crop_mean,crop_std] = corner2image(img, p, tsize)
%   (r1,c1) ***** (r3,c3)            (1,1) ***** (1,cols)
%     *             *                  *           *
%      *             *       ----->     *           *
%       *             *                  *           *
%     (r2,c2) ***** (r4,c4)              (rows,1) **** (rows,cols)
afnv_obj = corners2affine(p, tsize);
map_afnv = afnv_obj.afnv;

img_map = IMGaffine_c(double(img), map_afnv, tsize);

[crop, crop_mean, crop_std] = whitening( reshape(img_map, prod([tsize 3]), 1) ); % crop is a vector
crop_norm = norm(crop);
crop = crop/crop_norm;