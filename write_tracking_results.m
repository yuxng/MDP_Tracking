function write_tracking_results(filename, dres)

fid = fopen(filename, 'w');

N = numel(dres.x);
for i = 1:N
    % <frame>, <id>, <bb_left>, <bb_top>, <bb_width>, <bb_height>, <conf>, <x>, <y>, <z>
    fprintf(fid, '%d,%d,%f,%f,%f,%f,%f,%f,%f,%f\n', ...
        dres.fr(i), dres.id(i), dres.x(i), dres.y(i), dres.w(i), dres.h(i), ...
        -1, -1, -1, -1);
end

fclose(fid);