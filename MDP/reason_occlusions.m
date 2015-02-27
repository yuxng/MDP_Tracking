function occ = reason_occlusions(img, dres, models)

num = numel(dres.x);
occ = zeros(num, num);
y = dres.y + dres.h;

for i = 1:num
    [~, ov] = calc_overlap(dres, i, dres, 1:num);
    % check if target i is occluded
    ov(i) = 0;
    ind = find(ov > 0.6);
    for j = 1:numel(ind)
        if (y(ind(j)) - y(i)) / y(ind(j)) > 0.1
            occ(i, ind(j)) = 1;
        elseif abs(y(ind(j)) - y(i)) / y(ind(j)) < 0.1
            % compute reconstruction error
            err_i = L1APG_reconstruction_error(img, models{dres.id(i)}, ...
                dres.x(i), dres.y(i), dres.x(i)+dres.w(i), dres.y(i)+dres.h(i));
            
            err_j = L1APG_reconstruction_error(img, models{dres.id(ind(j))}, ...
                dres.x(ind(j)), dres.y(ind(j)), ...
                dres.x(ind(j))+dres.w(ind(j)), dres.y(ind(j))+dres.h(ind(j)));
            
            if err_j < err_i
                occ(i, ind(j)) = 1;
            end
        end
    end
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