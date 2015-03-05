% update the LK tracker
function tracker = LK_update(frame_id, tracker, img)

% find the template with min FB error
[~, index] = max(tracker.medFBs);

% update
tracker.frame_ids(index) = frame_id;
tracker.x1(index) = tracker.bb(1);
tracker.y1(index) = tracker.bb(2);
tracker.x2(index) = tracker.bb(3);
tracker.y2(index) = tracker.bb(4);
tracker.patterns(:,index) = generate_pattern(img, tracker.bb, tracker.patchsize);