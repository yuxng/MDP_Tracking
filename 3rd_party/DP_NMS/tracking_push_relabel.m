function [res] = tracking_push_relabel(dres, c_en, c_ex, c_ij, betta, max_it)

dnum = length(dres.x);

dres.c = betta - dres.r; %% cost for each detection window

%%% The mex function works with large numbers.
dres.c  = dres.c  *1e6;
c_en    = c_en    *1e6;
c_ex    = c_ex    *1e6;
c_ij    = c_ij    *1e6;

n_nodes = 2*dnum+2; %% number of nodes in the graph
n_edges = 0;

dat_in = zeros(1e7,3); %% each row represents an edge from node in column 1 to node in column 2 with cost in column 3.
k_dat = 0;
for i = 1:dnum
  k_dat = k_dat+3;
  dat_in(k_dat-2,:) = [1      2*i     c_en      ];
  dat_in(k_dat-1,:) = [2*i    2*i+1   dres.c(i) ];
  dat_in(k_dat,:)   = [2*i+1  n_nodes c_ex      ];
end
for i=1:dnum
  f2 = dres.nei(i).inds;
  for j = 1:length(f2)
    k_dat = k_dat+1;
    dat_in(k_dat,:) = [2*f2(j)+1 2*i c_ij];
  end
end
dat_in = [dat_in repmat([0 1],size(dat_in,1),1)];  %% add two columns: 0 for min capacity in column 4 and 1 for max capacity in column 5 for all edges.

excess_node = [1 n_nodes];  %% push flow in the first node and collect it in the last node.

k = 0;
dat2_old = [0 0 0];

inds_all = [];
tic
lb=1;
ub=1e4;
tr_num_old = 1;

tic

while ub-lb > 1     %% bisection search for the optimum amount of flow. This can be implemented by Golden section search more efficiently.
  tr_num = round((lb+ub)/2);
  
  [cost_l, dat_l] = cs2_func(dat_in(1:k_dat,:), excess_node, [tr_num -tr_num]);      %% try flow = tr_num
  [cost_u, dat_u] = cs2_func(dat_in(1:k_dat,:), excess_node, [tr_num+1 -tr_num-1]);  %% try flow = tr_num+1
  if cost_u-cost_l > 0
    ub = tr_num;
  else
    lb = tr_num;
  end
  k=k+1;
end

if cost_u < cost_l
  dat1 = dat_u;
else
  cost1 = cost_l;
  dat1 = dat_l;
end

%%%% backtrack tracks to get ids
tmp   = find( dat1(:, 1) == 1);
start = dat1(tmp, 2);       %% starting nodes; is even

tmp   = find( ~mod(dat1(:, 1), 2) .* (dat1(:, 2)-dat1(:, 1) == 11) );
detcs = dat1(tmp, 1);       %% detection nodes; is even

tmp   = find( mod(dat1(:, 1), 2) .* ~mod(dat1(:, 2), 2) .* (dat1(:, 2)-dat1(:, 1) ~= 1) );
links = dat1(tmp, 1:2);     %% links; is [even  odd]

res_inds  = zeros(1, 1e5);
res_ids   = zeros(1, 1e5);

k = 0;
for i = 1:length(start);    %% for each track
  this1 = start(i);
  while this1 ~= n_nodes
    k = k+1;
    res_inds(k) = this1/2;
    res_ids(k) = i;
    this1 = links(find(links(:,1) == this1+1), 2);  %% should have only one value
    if mod(this1, 2) + (length(this1) ~= 1)         %% sanity check
      display('error in the output of solver');
    end
  end
end
res_inds  = res_inds(1:k);    %% only these detection windows are used in tracks.
res_ids   = res_ids(1:k);     %% track id for each detection window

%%% Calculate the cost value to sort tracks
this_cost = zeros(1, max(res_ids));
for i = 1:max(res_ids)  %% for each track
  inds = find(res_ids == i);
  len1= length(inds);
  track_cost(i) = sum(dres.c(res_inds(inds))) + (len1-1) * c_ij + c_en + c_ex;
end
[dummy sort_inds] = sort(track_cost);

for i = 1:length(sort_inds)
  res_ids_sorted(res_ids == sort_inds(i)) = i;
end

res = sub(dres, res_inds);
res.id = res_ids_sorted(:);

% [dummy tmp] = sort(res.id);
% res = sub(res,tmp);
% % res = sub(dres,inds_all_its(1).inds);
% % res.r = res.r/1e6;

