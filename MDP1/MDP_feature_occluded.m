% extract features for occluded state
function [feature, flag] = MDP_feature_occluded(frame_id, dres_image, dres, tracker)

f = zeros(1, tracker.fnum_occluded);
m = numel(dres.fr);
feature = zeros(m, tracker.fnum_occluded);
flag = zeros(m, 1);
for i = 1:m
    dres_one = sub(dres, i);
    tracker = LK_associate(frame_id, dres_image, dres_one, tracker);
    
    % extract minimal left or right FB error
%     [ml, indl] = min(tracker.medFBs_left);
%     [mr, indr] = min(tracker.medFBs_right);
%     if ml < mr
%         index = indl;
%         m = ml;
%     else
%         index = indr;
%         m = mr;
%     end
    
    % [~, index] = min(tracker.medFBs);
    
    f(1) = mean(exp(-tracker.medFBs / tracker.fb_factor));
    f(2) = mean(exp(-tracker.medFBs_left / tracker.fb_factor));
    f(3) = mean(exp(-tracker.medFBs_right / tracker.fb_factor));
    f(4) = mean(exp(-tracker.medFBs_up / tracker.fb_factor));
    f(5) = mean(exp(-tracker.medFBs_down / tracker.fb_factor));
    f(6) = mean(tracker.medNCCs);
    f(7) = mean(tracker.overlaps);
    f(8) = mean(tracker.nccs);
    % f(5) = mean(tracker.angles);
    feature(i,:) = f;
    
    if isempty(find(tracker.flags ~= 2, 1)) == 1
        flag(i) = 0;
    else
        flag(i) = 1;
    end
end