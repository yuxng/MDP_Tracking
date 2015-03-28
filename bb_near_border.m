% check if the bounding box is near image border or not
function flag = bb_near_border(bb, width, height)

frac = 0.05;
flag = bb(1) > frac*width & bb(2) > frac*height & bb(3) < (1-frac)*width & bb(4) < (1-frac)*height;
flag = ~flag;