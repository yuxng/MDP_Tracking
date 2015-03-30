% compute reward in tracked state
function [reward, label, is_end] = MDP_reward_tracked(fr, dres_gt, tracker, opt, is_text)

% check if tracking result overlaps with gt
is_end = 0;
label = 0;
index = find(dres_gt.fr == fr);
if isempty(index) == 1
    overlap = 0;
else
    if dres_gt.covered(index) > opt.overlap_occ
        overlap = 0;
    else
        overlap = calc_overlap(dres_gt, index, tracker.dres, numel(tracker.dres.fr));
    end
end
if is_text
    fprintf('overlap in tracked %.2f\n', overlap);
end
if overlap > opt.overlap_pos
    if tracker.state == 2
        reward = 1;
    else
        reward = -1;
        label = 1;
        if isempty(find(tracker.flags ~= 2, 1)) == 1
            reward = 0;  % no update
%         else
%             if dres_gt.covered(index) == 0
%                 is_end = 1;
%                 if is_text
%                     fprintf('target not tracked! Game over\n');
%                 end
%             else
%                 reward = 0;
%             end
        end
    end
else
    if tracker.state == 3
        reward = 1;
    else
        if overlap < opt.overlap_neg
            reward = -1;                       
        else
            reward = 0;  % no update
        end
%         reward = -1;
        label = -1;
        % possible drift
%         if isempty(index) == 0 && dres_gt.covered(index) > 0.9
%             is_end = 1;
%             if is_text
%                 fprintf('target drift! Game over\n');
%             end
%         end
    end
end
if is_text
    fprintf('reward %.1f\n', reward);
end