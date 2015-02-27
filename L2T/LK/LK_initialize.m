% initialize TLD tracker
function tld = LK_initialize(img, x1, y1, x2, y2)

tld.min_win = 24;
tld.patchsize = [15 15];
tld.n_par.overlap = 0.2;
tld.n_par.num_patches = 100;
tld.thr_nn = 0.65;
tld.ncc_thesame = 0.95;
tld.valid = 0.5;

% Scanning grid
bb = [x1; y1; x2; y2];
[tld.grid, tld.scales] = bb_scan(bb, size(img), tld.min_win);

% Generate Positive Examples
overlap = bb_overlap(bb, tld.grid); % bottleneck
[pEx, bbP] = tldGeneratePositiveData(tld, overlap, img);

% Variance threshold
tld.var = var(pEx(:,1))/2;

% Generate Negative Examples
nEx = tldGenerateNegativeData(tld, overlap, img);
% disp(['# N patterns: ' num2str(size(nX,2))]);
% disp(['# N patches : ' num2str(size(nEx,2))]);

% Split Negative Data to Training set and Validation set
[nEx1, nEx2] = tldSplitNegativeData(nEx);

% Nearest Neightbour
tld.pex = [];
tld.nex = [];
tld = tldTrainNN(pEx, nEx1, tld);