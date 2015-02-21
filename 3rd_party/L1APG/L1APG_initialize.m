function model = L1APG_initialize(img, id, x1, y1, x2, y2)

init_pos = [y1, y2, y1; x1 x1 x2];
sz_T = [12 15];
% sz_T = [24 12];

% parameters setting for tracking
para.lambda = [0.2, 0.001, 10]; % lambda 1, lambda 2 for a_T and a_I respectively, lambda 3 for the L2 norm parameter
% set para.lambda = [a,a,0]; then this the old model
para.angle_threshold = 40;
para.Lip = 8;
para.Maxit = 5;
para.nT = 10; % number of templates for the sparse representation
% para.rel_std_afnv = [0.03,0.0005,0.0005,0.03,1,1]; % diviation of the sampling of particle filter
para.rel_std_afnv = [0.003, 0.0005, 0.0005, 0.003, 1, 1];
para.n_sample = 300;		% number of particles
para.sz_T = sz_T;
para.init_pos = init_pos;
para.bDebug = 1;		% debugging indicator

% generate the initial templates for the 1st frame
[T, T_norm, T_mean, T_std] = InitTemplates(sz_T, para.nT, img, init_pos);
norms = T_norm .* T_std; % template norms

% get affine transformation parameters from the corner points in the first frame
aff_obj = corners2affine(init_pos, sz_T);
map_aff = aff_obj.afnv;

dim_T = size(T,1);	% number of elements in one template, sz_T(1)*sz_T(2)=12x15 = 180
A = [T eye(dim_T)]; % data matrix is composed of T, positive trivial T.
% fixT = T(:,1)/para.nT; % first template is used as a fixed template
%Temaplate Matrix
Temp = A;
Dict = Temp'*Temp;
Temp1 = T*pinv(T);

% build model
model.T = T;
model.T_mean = T_mean;
model.norms = norms;
model.occlusionNf = 0;
model.map_aff = map_aff;
model.A = A;
model.Temp = Temp;
model.Dict = Dict;
model.Temp1 = Temp1;
model.Lambda = para.lambda;
model.para = para;
model.id = id;
model.lost = 0;
model.aff_samples = ones(para.n_sample,1)*map_aff;