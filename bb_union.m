% compute union of two boxes
function BB = bb_union(BB1, BB2)

BB = zeros(size(BB1));
BB(1) = min(BB1(1), BB2(1));
BB(2) = min(BB1(2), BB2(2));
BB(3) = max(BB1(3), BB2(3));
BB(4) = max(BB1(4), BB2(4));