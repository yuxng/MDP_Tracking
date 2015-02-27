function afnv_obj = corners2affine(corners_in, size_out)
%Compute the affine parameter to the desired output size.
%The affine transformation is: inpoints = R *outpoints;
%
% afnv = 3corner2afnv(corners_in, size_out)
%   corners_in -- cornner points in the input image, 2x3 [r1 r2 r3; c1 c2 c3]
%   size_out -- output size
%   afnv_obj.afnv -- affine parameters
%   afnv_obj.R -- transformation matrix, 
%   afnv_obj.size -- size_out
%   (r1,c1) ***** (r3,c3)            (1,1) ***** (1,cols)
%     *             *                  *           *
%      *             *       ----->     *           *
%       *             *                  *           *
%     (r2,c2) ***** (r4,c4)              (rows,1) **** (rows,cols)


if nargin ~= 2
  error('illegal # of nargin');
end

rows = size_out(1);
cols = size_out(2);

inp = [corners_in; 1,1,1];

outp = ...
  [1, rows, 1; ...
   1, 1,  cols; ...
   1, 1, 1];

%outp = B * inp
R = inp/outp;
afnv_obj.R = R;
afnv_obj.afnv = [R(1,1), R(1,2), R(2,1), R(2,2), R(1,3), R(2,3)];
afnv_obj.size = size_out;