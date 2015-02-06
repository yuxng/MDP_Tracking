function occ = reason_occlusions(dres)

num = numel(dres.x);
occ = zeros(num, num);
y = dres.y + dres.h;

for i = 1:num
    [~, ov] = calc_overlap(dres, i, dres, 1:num);
    occ(i,:) = ov > 0.5 & y(i) < y';
end

for i = 1:num
    ind = find(occ(i,:) == 1);
    if isempty(ind) == 0
        fprintf('target %d is occluded by ', dres.id(i));
        for j = 1:numel(ind)
            fprintf('target %d ', dres.id(ind(j)));
        end
        fprintf('\n');
    end
end