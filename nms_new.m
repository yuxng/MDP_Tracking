function pick = nms_new(boxes, overlap)

% pick = nms(boxes, overlap) 
% Non-maximum suppression.
% Greedily select high-scoring detections and skip detections
% that are significantly covered by a previously selected detection.

if isempty(boxes)
  pick = [];
else
  x1 = boxes(:,1);
  y1 = boxes(:,2);
  x2 = boxes(:,3);
  y2 = boxes(:,4);
  s = boxes(:,end);
  area = (x2-x1+1) .* (y2-y1+1);

  [vals, I] = sort(s, 'descend');
  n = numel(I);
  pick = ones(n, 1);
    for i = 1:n
        ii = I(i);
        for j = 1:i-1
            jj = I(j);
            if pick(jj)

                xx1 = max(x1(ii), x1(jj));
                yy1 = max(y1(ii), y1(jj));
                xx2 = min(x2(ii), x2(jj));
                yy2 = min(y2(ii), y2(jj));
                w = xx2-xx1+1;
                h = yy2-yy1+1;
                if w > 0 && h > 0
                    % compute overlap 
                    o = w * h / (area(ii) + area(jj) - w*h);
                    o1 = w * h / area(ii);
                    o2 = w * h / area(jj);
                    if o > overlap || o1 > 0.95 || o2 > 0.95
                        pick(ii) = 0;
                        break;
                    end
                end
            end
        end
    end
    
    pick = find(pick == 1);
end