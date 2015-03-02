% use LK trackers for association
function tracker = LK_associate(frame_id, dres_image, dres_det, tracker)

% current frame
J = dres_image.Igray{frame_id};

% crop image with bounding box
rect = [dres_det.x dres_det.y dres_det.w dres_det.h];
J = imcrop(J, rect);

for i = 1:tracker.num
    I = dres_image.Igray{tracker.frame_ids(i)};
    BB1 = [tracker.x1(i); tracker.y1(i); tracker.x2(i); tracker.y2(i)];
    
    % crop image with bounding box
    rect = [BB1(1) BB1(2) BB1(3)-BB1(1) BB1(4)-BB1(2)];
    I = imcrop(I, rect);
    
    % resize the image
    I = imresize(I, size(J));
    BB1 = [1; 1; size(I,2); size(I,1)];
    
    BB1 = bb_rescale_relative(BB1, tracker.rescale_box);
    [BB2, xFJ, flag, medFB, medNCC] = LK(BB1, I, J);
    BB2 = bb_rescale_relative(BB2, 1./tracker.rescale_box);
    
    tracker.bbs{i} = BB2;
    tracker.points{i} = xFJ;
    tracker.flags(i) = flag;
    tracker.medFBs(i) = medFB;
    tracker.medNCCs(i) = medNCC;
end