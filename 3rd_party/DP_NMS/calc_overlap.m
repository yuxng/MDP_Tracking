function [ov ov_n1 ov_n2] = calc_overlap(dres1, f1, dres2, f2)
%%f2 can be an array and f1 should be a scalar.
%%% this will find the overlap between dres1(f1) (only one) and all detection windows in dres2(f2(:))

f2=f2(:)';
n = length(f2);

cx1 = dres1.x(f1);
cx2 = dres1.x(f1)+dres1.w(f1)-1;
cy1 = dres1.y(f1);
cy2 = dres1.y(f1)+dres1.h(f1)-1;

gx1 = dres2.x(f2);
gx2 = dres2.x(f2)+dres2.w(f2)-1;
gy1 = dres2.y(f2);
gy2 = dres2.y(f2)+dres2.h(f2)-1;

ca = dres1.h(f1).*dres1.w(f1);  %% area
ga = dres2.h(f2).*dres2.w(f2);

%%% find the overlapping area
xx1 = max(cx1, gx1);
yy1 = max(cy1, gy1);
xx2 = min(cx2, gx2);
yy2 = min(cy2, gy2);
w = xx2-xx1+1;
h = yy2-yy1+1;

inds  = find((w > 0) .* (h > 0));  %% real overlap
ov    = zeros(1, n);
ov_n1 = zeros(1, n);
ov_n2 = zeros(1, n);
inter = w(inds).*h(inds);         %% area of overlap
u     = ca + ga(inds) - w(inds).*h(inds);     %% area of union
ov(inds)    = inter ./ u;                       %% intersection / union
ov_n1(inds) = inter / ca;                       %% intersection / area in dres1
ov_n2(inds) = inter ./ ga(inds);                  %% intersection / area in dres2

