function write_tracking_results(filename, dres)

% sort dres according to fr
[~, index] = sort(dres.fr);

fid = fopen(filename, 'w');

N = numel(index);
for i = 1:N
    ind = index(i);
    % <frame>, <id>, <bb_left>, <bb_top>, <bb_width>, <bb_height>, <conf>, <x>, <y>, <z>
    fprintf(fid, '%d,%d,%f,%f,%f,%f,%f,%f,%f,%f\n', ...
        dres.fr(ind), dres.id(ind), dres.x(ind), dres.y(ind), dres.w(ind), dres.h(ind), ...
        -1, -1, -1, -1);
end

fclose(fid);