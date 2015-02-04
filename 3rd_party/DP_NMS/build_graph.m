function dres = build_graph(dres)
ov_thresh = 0.5;
dnum = length(dres.x);
time1 = tic;
len1 = max(dres.fr);
for fr = 2:max(dres.fr)
  if toc(time1) > 2
    fprintf('%0.1f%%\n', 100*fr/len1);
    time1 = tic;
  end
  f1 = find(dres.fr == fr);     %% indices for detections on this frame
  f2 = find(dres.fr == fr-1);   %% indices for detections on the previous frame
  for i = 1:length(f1)
    ovs1  = calc_overlap(dres, f1(i), dres, f2);   
    inds1 = find(ovs1 > ov_thresh);                       %% find overlapping bounding boxes.  
    
    ratio1 = dres.h(f1(i))./dres.h(f2(inds1));
    inds2  = (min(ratio1, 1./ratio1) > 0.8);          %% we ignore transitions with large change in the size of bounding boxes.
      
    dres.nei(f1(i),1).inds  = f2(inds1(inds2))';      %% each detction window will have a list of indices pointing to its neighbors in the previous frame.
%     dres.nei(f1(i),1).ovs   = ovs1(inds1(inds2));
  end
end

