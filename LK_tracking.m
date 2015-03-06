% Copyright 2011 Zdenek Kalal
%
% This file is part of TLD.
% 
% TLD is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% TLD is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with TLD.  If not, see <http://www.gnu.org/licenses/>.

function tracker = LK_tracking(frame_id, dres_image, dres_det, tracker)

% current frame
J = dres_image.Igray{frame_id};

num_det = numel(dres_det.x);
for i = 1:tracker.num
    I = dres_image.Igray{tracker.frame_ids(i)};
    BB1 = [tracker.x1(i); tracker.y1(i); tracker.x2(i); tracker.y2(i)];
    BB1 = bb_rescale_relative(BB1, tracker.rescale_box);
    [BB2, xFJ, flag, medFB, medNCC] = LK(BB1, I, J);
    BB2 = bb_rescale_relative(BB2, 1./tracker.rescale_box);    
    if isnan(medFB) || isnan(medNCC) || ~bb_isdef(BB2)
        medFB = inf;
        medNCC = 0;
        o = 0;
        ind = 1;
        angle = 0;
    else
        % compute overlap
        dres.x = BB2(1);
        dres.y = BB2(2);
        dres.w = BB2(3) - BB2(1);
        dres.h = BB2(4) - BB2(2);
        overlap = calc_overlap(dres, 1, dres_det, 1:num_det);
        [o, ind] = max(overlap);
        
        % compute angle
        centerI = [(BB1(1)+BB1(3))/2 (BB1(2)+BB1(4))/2];
        centerJ = [(BB2(1)+BB2(3))/2 (BB2(2)+BB2(4))/2];
        v = compute_velocity(tracker);
        v_new = [centerJ(1)-centerI(1), centerJ(2)-centerI(2)] / double(frame_id - tracker.frame_ids(i));
        if norm(v) && norm(v_new)
            angle = dot(v, v_new) / (norm(v) * norm(v_new));
        else
            angle = 1;
        end        
    end
    
    tracker.bbs{i} = BB2;
    tracker.points{i} = xFJ;
    tracker.flags(i) = flag;
    tracker.medFBs(i) = medFB;
    tracker.medNCCs(i) = medNCC;
    tracker.overlaps(i) = o;
    tracker.indexes(i) = ind;
    tracker.angles(i) = angle;
end

% combine tracking and detection results
[~, ind] = min(tracker.medFBs);
if tracker.overlaps(ind) > 0.7
    index = tracker.indexes(ind);
    bb_det = [dres_det.x(index); dres_det.y(index); ...
        dres_det.x(index)+dres_det.w(index); dres_det.y(index)+dres_det.h(index)];
    tracker.bb = mean([repmat(tracker.bbs{ind},1,10) bb_det], 2);
else
    tracker.bb = tracker.bbs{ind};
end


fprintf('\ntarget %d: frame ids ', tracker.target_id);
for i = 1:tracker.num
    fprintf('%d ', tracker.frame_ids(i))
end
fprintf('\n');    
fprintf('target %d: medFB ', tracker.target_id);
for i = 1:tracker.num
    fprintf('%.2f ', tracker.medFBs(i))
end
fprintf('\n');
fprintf('target %d: medNCC ', tracker.target_id);
for i = 1:tracker.num
    fprintf('%.2f ', tracker.medNCCs(i))
end
fprintf('\n');
fprintf('target %d: overlap ', tracker.target_id);
for i = 1:tracker.num
    fprintf('%.2f ', tracker.overlaps(i))
end
fprintf('\n');    
fprintf('target %d: flag ', tracker.target_id);
for i = 1:tracker.num
    fprintf('%d ', tracker.flags(i))
end
fprintf('\n');
fprintf('target %d: angle ', tracker.target_id);
for i = 1:tracker.num
    fprintf('%.2f ', tracker.angles(i))
end
fprintf('\n');

if tracker.flags(ind) == 2
    fprintf('target %d: bounding box out of image\n', tracker.target_id);
elseif tracker.flags(ind) == 3
    fprintf('target %d: too unstable predictions\n', tracker.target_id);
end