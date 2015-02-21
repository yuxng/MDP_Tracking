% update model
function [model, id_max] = L1APG_update(img, model, x1, y1, x2, y2)

% initialization
para = model.para;
para.Lambda = model.Lambda;
rel_std_afnv = para.rel_std_afnv;
sz_T = para.sz_T;
nT = para.nT;
T = model.T;
T_mean = model.T_mean;
norms = model.norms;
A = model.A;
alpha = 50;

% construct template
num = numel(x1);
map_aff = zeros(num, 6);
for i = 1:num
    pos = [y1(i), y2(i), y1(i); x1(i) x1(i) x2(i)];
    aff_obj = corners2affine(pos, sz_T);
    map_aff(i,:) = aff_obj.afnv;
end

% draw samples
n_sample = 20;
aff_samples = zeros(n_sample*num, 6);
index_samples = zeros(n_sample*num, 1);
for i = 1:num
    samples = ones(n_sample,1)*map_aff(i,:);
    sc = sqrt(sum(map_aff(i,1:4).^2)/2);
    std_aff	= 0.1 * rel_std_afnv .* [1, sc, sc, 1, sc, sc];
    samples = draw_sample(samples, std_aff); %draw transformation samples from a Gaussian distribution
    aff_samples((i-1)*n_sample+1:i*n_sample, :) = samples; 
    index_samples((i-1)*n_sample+1:i*n_sample) = i;
end

aff_samples = [aff_samples; model.map_aff];
n_sample = size(aff_samples,1);
[Y, Y_inrange] = crop_candidates(double(img), aff_samples(:,1:6), sz_T);
if(sum(Y_inrange == 0) == n_sample)
    fprintf('Target is out of the frame!\n');
end

[Y, Y_crop_mean, Y_crop_std] = whitening(Y);	 % zero-mean-unit-variance
[Y, Y_crop_norm] = normalizeTemplates(Y);        % norm one

p = zeros(n_sample,1); % observation likelihood initialization
% reconstruction coefficients
for i = 1:n_sample
    c = APGLASSOup(model.Temp'*Y(:,i), model.Dict, para);
    D_s = (Y(:,i) - A(:,1:nT)*c(1:nT)).^2;  % reconstruction error
    p(i) = exp(-alpha*(sum(D_s)));          % probability w.r.t samples    
end

% find the tempalte to be replaced
[~, indW] = min(c(1:nT));

% insert new template
[~, id_max] = max(p(1:end-1));
T(:,indW)	= Y(:,id_max);
T_mean(indW)= Y_crop_mean(id_max);
norms(indW) = Y_crop_std(id_max) * Y_crop_norm(id_max);

[T, ~] = normalizeTemplates(T);
A(:,1:nT)	= T;

%Temaplate Matrix
Temp = A;
Dict = Temp'*Temp;
Temp1 = T*pinv(T);

model.T = T;
model.T_mean = T_mean;
model.norms = norms;
model.A = A;
model.Temp = Temp;
model.Dict = Dict;
model.Temp1 = Temp1;
model.map_aff = 0.2*aff_samples(id_max,:) + 0.8*model.map_aff;
model.aff_samples = ones(para.n_sample,1)*model.map_aff;
model.occlusionNf = 0;

id_max = index_samples(id_max);