% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
%
% add dres2 to dres1 and interpolate
function dres_new = interpolate_dres(dres1, dres2)

if isempty(dres2) == 1
    dres_new = dres1;
    return;
end

index = find(dres1.state == 2);
if isempty(index) == 0
    ind = index(end);
    fr1 = double(dres1.fr(ind));
    fr2 = double(dres2.fr(1));

    if fr2 - fr1 <= 5 && fr2 - fr1 > 1
        dres1 = sub(dres1, 1:ind);

        % box1
        x1 = dres1.x(end);
        y1 = dres1.y(end);
        w1 = dres1.w(end);
        h1 = dres1.h(end);
        r1 = dres1.r(end);

        % box2
        x2 = dres2.x(1);
        y2 = dres2.y(1);
        w2 = dres2.w(1);
        h2 = dres2.h(1);
        r2 = dres2.r(1);

        % linear interpolation
        n = fieldnames(dres1);
        for fr = fr1+1:fr2-1
            dres_one = sub(dres2, 1);
            dres_one.fr = fr;
            dres_one.x = x1 + ((x2 - x1) / (fr2 - fr1)) * (fr - fr1);
            dres_one.y = y1 + ((y2 - y1) / (fr2 - fr1)) * (fr - fr1);
            dres_one.w = w1 + ((w2 - w1) / (fr2 - fr1)) * (fr - fr1);
            dres_one.h = h1 + ((h2 - h1) / (fr2 - fr1)) * (fr - fr1);
            dres_one.r = r1 + ((r2 - r1) / (fr2 - fr1)) * (fr - fr1);

            for i = 1:length(n),
                f = n{i};
                dres1.(f) = [dres1.(f); dres_one.(f)];
            end    
        end
    end
end

% concatenation
n = fieldnames(dres1);
for i = 1:length(n),
    f = n{i};
    dres_new.(f) = [dres1.(f); dres2.(f)];
end