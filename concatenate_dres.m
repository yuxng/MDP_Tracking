% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
function dres_new = concatenate_dres(dres1, dres2)

if isempty(dres2) == 1
    dres_new = dres1;
else
    n = fieldnames(dres1);
    for i = 1:length(n),
        f = n{i};
        dres_new.(f) = [dres1.(f); dres2.(f)];
    end
end