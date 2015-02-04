function [res min_cs] = tracking_dp(dres, c_en, c_ex, c_ij, betta, thr_cost, max_it, nms_in_loop)

if ~exist('max_it')
  max_it = 1e5;
end
if ~exist('thr_cost')
  thr_cost = 0;
end

thr_nms = 0.5;

dnum = length(dres.x);

dres.c = betta - dres.r;

dres.dp_c     = [];
dres.dp_link  = [];
dres.orig     = [];

min_c     = -inf;
it        = 0;
k         = 0;
inds_all  = zeros(1,1e5);
id_s      = zeros(1,1e5);
redo_nodes = [1:dnum]';
while (min_c < thr_cost) && (it < max_it)
  it = it+1;
  
  dres.dp_c(redo_nodes,1) = dres.c(redo_nodes) + c_en;
  dres.dp_link(redo_nodes,1) = 0;
  dres.orig(redo_nodes,1) = redo_nodes;
  
  for ii=1:length(redo_nodes)
    i = redo_nodes(ii);
    f2 = dres.nei(i).inds;
    if isempty(f2)
      continue
    end
    
    [min_cost j] = min(c_ij + dres.c(i) + dres.dp_c(f2));
    min_link = f2(j);
    if dres.dp_c(i,1) > min_cost
      dres.dp_c(i,1) = min_cost;
      dres.dp_link(i,1) = min_link;
      dres.orig(i,1) = dres.orig(min_link);
    end
  end
  
  [min_c ind] = min(dres.dp_c + c_ex);
  
  inds = zeros(dnum,1);
  
  k1 = 0;
  while ind~=0
    k1 = k1+1;
    inds(k1) = ind;
    ind = dres.dp_link(ind);
  end
  inds = inds(1:k1);
  
  inds_all(k+1:k+length(inds)) = inds;
  id_s(k+1:k+length(inds)) = it;
  k = k+length(inds);
  
  if nms_in_loop
    supp_inds = nms_aggressive(dres, inds, thr_nms);
    origs = unique(dres.orig(supp_inds));
    redo_nodes = find(ismember(dres.orig, origs));
  else
    supp_inds = inds;
    origs = inds(end);
    redo_nodes = find(dres.orig == origs);
  end
  redo_nodes = setdiff(redo_nodes, supp_inds);
  dres.dp_c(supp_inds) = inf;
  dres.c(supp_inds) = inf;

  min_cs(it) = min_c;
end
inds_all = inds_all(1:k);
id_s = id_s(1:k);

res = sub(dres, inds_all);
res.id = id_s';

