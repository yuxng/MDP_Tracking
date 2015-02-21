function [track_res, min_err, model] = L1APG_track_frame(img, model)

paraT = model.para;

% parameters
n_sample = paraT.n_sample;
sz_T = paraT.sz_T;
rel_std_afnv = paraT.rel_std_afnv;
nT = paraT.nT;

% L1 function settings
angle_threshold = paraT.angle_threshold;
para.Lambda = model.Lambda;
para.nT = paraT.nT;
para.Lip = paraT.Lip;
para.Maxit = paraT.Maxit;
alpha = 50; % this parameter is used in the calculation of the likelihood of particle filter

% initialization
T = model.T;
T_mean = model.T_mean;
norms = model.norms;
map_aff = model.map_aff;
A = model.A;
Temp = model.Temp;
Dict = model.Dict;
Temp1 = model.Temp1;
min_err = 0;

%-Draw transformation samples from a Gaussian distribution
aff_samples = model.aff_samples;
sc = sqrt(sum(map_aff(1:4).^2)/2);
std_aff = rel_std_afnv .* [1, sc, sc, 1, sc, sc];
aff_samples = draw_sample(aff_samples, std_aff); %draw transformation samples from a Gaussian distribution

%-Crop candidate targets "Y" according to the transformation samples
[Y, Y_inrange] = crop_candidates(double(img), aff_samples(:,1:6), sz_T);
if(sum(Y_inrange==0) == n_sample)
    sprintf('Target is out of the frame!\n');
end

[Y, Y_crop_mean, Y_crop_std] = whitening(Y); % zero-mean-unit-variance
[Y, Y_crop_norm] = normalizeTemplates(Y);    % norm one

%-L1-LS for each candidate target
eta_max	= -inf;
q = zeros(n_sample,1); % minimal error bound initialization

% first stage L2-norm bounding
for j = 1:n_sample
    if Y_inrange(j)==0 || sum(abs(Y(:,j)))==0
        continue;
    end

    % L2 norm bounding
    q(j) = norm(Y(:,j) - Temp1*Y(:,j));
    q(j) = exp(-alpha*q(j)^2);
end
%  sort samples according to descend order of q
[q, indq] = sort(q, 'descend');    

% second stage
p = zeros(n_sample,1); % observation likelihood initialization
n = 1;
tau = 0;
while (n < n_sample) && (q(n) >= tau)
    c = APGLASSOup(Temp'*Y(:,indq(n)), Dict, para);
    D_s = (Y(:,indq(n)) - A(:,1:nT)*c(1:nT)).^2;  % reconstruction error
    p(indq(n)) = exp(-alpha*(sum(D_s)));          % probability w.r.t samples
    tau = tau + p(indq(n))/(2*n_sample-1);        % update the threshold

    if(sum(c(1:nT)) < 0) %remove the inverse intensity patterns
        continue;
    elseif(p(indq(n)) > eta_max)
        id_max	= indq(n);
        c_max	= c;
        eta_max = p(indq(n));
        min_err = sum(D_s);
    end
    n = n + 1;
end

% target transformation parameters with the maximum probability
map_aff = aff_samples(id_max,1:6);
a_max	= c_max(1:nT);
% resample the samples wrt. the probability
[aff_samples, ~] = resample(aff_samples, p, map_aff); 
[~, indA] = max(a_max);
min_angle = images_angle(Y(:,id_max), A(:,indA));

%-Template update
model.occlusionNf = model.occlusionNf - 1;
level = 0.03;
if (min_angle > angle_threshold && model.occlusionNf < 0)
    trivial_coef = c_max(nT+1:end);
    trivial_coef = reshape(trivial_coef, [sz_T 3]);
    trivial_coef = rgb2gray(trivial_coef);
    trivial_coef = im2bw(trivial_coef, level);

    se = [0 0 0 0 0;
          0 0 1 0 0;
          0 1 1 1 0;
          0 0 1 0 0;
          0 0 0 0 0];
    trivial_coef = imclose(trivial_coef, se);

    cc = bwconncomp(trivial_coef);
    stats = regionprops(cc, 'Area');
    areas = [stats.Area];

    % occlusion detection 
    if isempty(areas) == 1 || max(areas) < round(0.25*prod(sz_T))
        disp('Update!')
        % find the tempalte to be replaced
        [~,indW] = min(a_max(1:nT));

        % insert new template
        T(:,indW)	= Y(:,id_max);
        T_mean(indW)= Y_crop_mean(id_max);
        norms(indW) = Y_crop_std(id_max)*Y_crop_norm(id_max);

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
    else
        model.occlusionNf = 5;
        % update L2 regularized term
        para.Lambda(3) = 0;
        fprintf('target %d occluded in online mode!\n', model.id);
    end
elseif model.occlusionNf < 0
    para.Lambda(3) = paraT.lambda(3);
end
model.Lambda = para.Lambda;
model.map_aff = map_aff;
model.aff_samples = aff_samples;

%-Store tracking result
track_res = map_aff';

%-Demostration and debugging
if paraT.bDebug
    % draw tracking results
    img	= showTemplates(img, T, T_mean, norms, sz_T, nT);
    imshow(uint8(img));
    color = [1 0 0];
    drawAffine(map_aff, sz_T, color, 2);
    drawnow;
end