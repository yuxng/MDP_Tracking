function inds_out = nms_aggressive(dres, inds, thr)

inds_out = zeros(length(dres.x),1);
k = 0;
for i=1:length(inds)
  f1 = inds(i);                       %% index of this detetion
  f2 = find(dres.fr == dres.fr(f1));  %% indices of all detections on the same frame
  
  [ovs ovs_n1] = calc_overlap(dres,f1,dres,f2);
  f3 = f2(find((ovs > thr) + (ovs_n1 > 0.9)));  
  inds_out(k+1:k+length(f3)) = f3;
  k = k + length(f3);
end
inds_out = inds_out(1:k);
