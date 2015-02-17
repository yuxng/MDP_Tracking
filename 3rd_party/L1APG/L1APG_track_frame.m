function [track_res, min_err] = L1APG_track_frame(img, model)

paraT = model.para;

% parameters
n_sample = paraT.n_sample;
sz_T = paraT.sz_T;
rel_std_afnv = paraT.rel_std_afnv;
nT = paraT.nT;

% L1 function settings
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
aff_samples = ones(n_sample,1)*map_aff;
sc			= sqrt(sum(map_aff(1:4).^2)/2);
std_aff		= rel_std_afnv .* [1, sc, sc, 1, sc, sc];
aff_samples = draw_sample(aff_samples, std_aff); %draw transformation samples from a Gaussian distribution

%-Crop candidate targets "Y" according to the transformation samples
[Y, Y_inrange] = crop_candidates(im2double(img), aff_samples(:,1:6), sz_T);
if(sum(Y_inrange==0) == n_sample)
    sprintf('Target is out of the frame!\n');
end

Y = whitening(Y);	 % zero-mean-unit-variance
Y = normalizeTemplates(Y);    % norm one

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

    [c] = APGLASSOup(Temp'*Y(:,indq(n)), Dict, para);

    D_s = (Y(:,indq(n)) - A(:,1:nT)*c(1:nT)).^2;  % reconstruction error
    p(indq(n)) = exp(-alpha*(sum(D_s)));          % probability w.r.t samples
    tau = tau + p(indq(n))/(2*n_sample-1);        % update the threshold

    if(sum(c(1:nT)) < 0) %remove the inverse intensity patterns
        continue;
    elseif(p(indq(n)) > eta_max)
        id_max	= indq(n);
        eta_max = p(indq(n));
        min_err = sum(D_s);
    end
    n = n + 1;
end

% target transformation parameters with the maximum probability
map_aff = aff_samples(id_max,1:6); 

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