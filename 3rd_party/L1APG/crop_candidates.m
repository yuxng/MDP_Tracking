function [gly_crop, gly_inrange] = crop_candidates(img_frame, curr_samples, template_size)
%create gly_crop, gly_inrange

nsamples = size(curr_samples,1);
c = prod([template_size 3]);
gly_inrange = zeros(nsamples,1);
gly_crop = zeros(c,nsamples);

for n = 1:nsamples
    curr_afnv = curr_samples(n, :);    
    
    %    [img_cut, gly_inrange(n)] = IMGaffine_r(img_frame, curr_afnv, template_size);
    [img_cut, gly_inrange(n)] = IMGaffine_c(img_frame, curr_afnv, template_size);
    
    gly_crop(:,n) = reshape(img_cut, c , 1);
end
