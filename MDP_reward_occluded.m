% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
%
% compute reward in tracked state
function [reward, label, f, is_end] = MDP_reward_occluded(fr, f, dres_image, dres_gt, ...
    dres, index_det, tracker, opt, is_text)

is_end = 0;
label = 0;
% check if any detection overlap with gt
index = find(dres_gt.fr == fr);
if isempty(index) == 1
    overlap = 0;
else
    if dres_gt.covered(index) > opt.overlap_occ
        overlap = 0;
    else
        overlap = calc_overlap(dres_gt, index, dres, index_det);
    end
end
if is_text
    fprintf('max overlap in association %.2f\n', max(overlap));
end
if max(overlap) > opt.overlap_pos
    if tracker.state == 2
        % if the association is correct
        ov = calc_overlap(dres_gt, index, tracker.dres, numel(tracker.dres.fr));
        if ov > opt.overlap_pos
            reward = 1;
        else
            reward = -1;
            label = -1;
            is_end = 1;
            if is_text
                fprintf('associated to wrong target (%.2f, %.2f)! Game over\n', max(overlap), ov);
            end
        end
    else  % target not associated
        if dres_gt.covered(index) == 0
            if isempty(find(tracker.flags ~= 2, 1)) == 1
                reward = 0;  % no update
            else
                reward = -1;   % no association
                label = 1;
                % extract features
                [~, ind] = max(overlap);
                dres_one = sub(dres, index_det(ind));
                f = MDP_feature_occluded(fr, dres_image, dres_one, tracker);
                if is_text
                    fprintf('Missed association!\n');
                end
                is_end = 1;
            end
        else
            reward = 1;
        end
    end
else
    if tracker.state == 3
        reward = 1;
    else
        ov = calc_overlap(dres_gt, index, tracker.dres, numel(tracker.dres.fr));
        if ov < opt.overlap_neg || max(overlap) < opt.overlap_neg
            reward = -1;
            label = -1;
            is_end = 1;
            if is_text
                fprintf('associated to wrong target! Game over\n');
            end
        else
            reward = 0;
        end
    end
end
if is_text
    fprintf('reward %.1f\n', reward);
end