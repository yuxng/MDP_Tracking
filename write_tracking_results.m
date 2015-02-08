function write_tracking_results(filename, dres)

% compute the length of each targets
num = max(dres.id);
len = zeros(num, 1);
for i = 1:num
    len(i) = numel(find(dres.id == i));
end
threshold_len = 5;

fid = fopen(filename, 'w');

N = numel(dres.x);
for i = 1:N
    % <frame>, <id>, <bb_left>, <bb_top>, <bb_width>, <bb_height>, <conf>, <x>, <y>, <z>
    if len(dres.id(i)) > threshold_len
        fprintf(fid, '%d,%d,%f,%f,%f,%f,%f,%f,%f,%f\n', ...
            dres.fr(i), dres.id(i), dres.x(i), dres.y(i), dres.w(i), dres.h(i), ...
            -1, -1, -1, -1);
    end
end

fclose(fid);