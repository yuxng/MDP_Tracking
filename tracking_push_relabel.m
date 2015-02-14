function res = tracking_push_relabel(dres, c_en, c_ex, betta, tr_num)

dnum = length(dres.x);

% cost for each detection window
dres.c = -betta * dres.r; 

% The mex function works with large numbers.
dres.c  = dres.c  *1e6;
c_en    = c_en    *1e6;
c_ex    = c_ex    *1e6;

% number of nodes in the graph
n_nodes = 2*dnum+2; 

% each row represents an edge from node in column 1 to node in column 2 with cost in column 3
dat_in = zeros(10000, 3); 
k_dat = 0;
for i = 1:tr_num
    k_dat = k_dat+3;
    dat_in(k_dat-2,:) = [1      2*i     c_en      ];  % source edge
    dat_in(k_dat-1,:) = [2*i    2*i+1   dres.c(i) ];  % detection edge
    dat_in(k_dat,:)   = [2*i+1  n_nodes c_ex      ];  % sink edge
end
for i = tr_num+1:dnum
    k_dat = k_dat+2;
    dat_in(k_dat-1,:) = [2*i    2*i+1   dres.c(i) ];  % detection edge
    dat_in(k_dat,:)   = [2*i+1  n_nodes c_ex      ];  % sink edge
end
for i=1:dnum
    f2 = dres.nei(i).inds;
    for j = 1:length(f2)
        c_ij = -dres.nei(i).scores(j) * 1e6;
        k_dat = k_dat + 1;
        dat_in(k_dat,:) = [2*f2(j)+1 2*i c_ij];  % transition edge
    end
end
% add two columns: 0 for min capacity in column 4 and 1 for max capacity in column 5 for all edges.
dat_in = [dat_in repmat([0 1],size(dat_in,1),1)];

% push flow in the first node and collect it in the last node
excess_node = [1 n_nodes];

% run push-relabel algorithm
[~, dat1] = cs2_func(dat_in(1:k_dat,:), excess_node, [tr_num -tr_num]);

% backtrack tracks to get ids
tmp   = find( dat1(:, 1) == 1);
start = dat1(tmp, 2);       % starting nodes; is even

tmp   = find( ~mod(dat1(:, 1), 2) .* (dat1(:, 2)-dat1(:, 1) == 1) );
detcs = dat1(tmp, 1);       % detection nodes; is even

% tmp   = find( mod(dat1(:, 1), 2) .* ~mod(dat1(:, 2), 2) .* (dat1(:, 2)-dat1(:, 1) ~= 1) );
tmp   = find( mod(dat1(:, 1), 2) .* ~mod(dat1(:, 2), 2) );
links = dat1(tmp, 1:2);     % links; is [even  odd]

res_inds  = zeros(1, 1e5);
res_ids   = zeros(1, 1e5);
k = 0;
for i = 1:length(start)    % for each track
    this1 = start(i);
    while this1 ~= n_nodes
        k = k + 1;
        res_inds(k) = this1/2;
        res_ids(k) = i;
        this1 = links(find(links(:,1) == this1+1), 2);  % should have only one value
        if mod(this1, 2) + (length(this1) ~= 1)         % sanity check
            display('error in the output of solver');
        end
    end
end
res_inds  = res_inds(1:k);    % only these detection windows are used in tracks.
res_ids   = res_ids(1:k);     % track id for each detection window

res.x = dres.x;
res.y = dres.y;
res.w = dres.w;
res.h = dres.h;
res.r = dres.r;
res.fr = dres.fr;
res.state = dres.state;
res.id = -1 * ones(numel(dres.x), 1);
res.id(res_inds) = res_ids;
res.nei = dres.nei;