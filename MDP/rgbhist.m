function H = rgbhist(I,nBins,Nind)
%% RGBHIST: color Histogram of an RGB image.
%
% nBins   : number of bins per EACH color => histogram is 'nBins^3' long.
% Nind    : Normalization index
%
%           0 -> Un-Normalized historam
%           1 -> l1 normalized
%           2 -> l2 normalized
%
% H       : The vectorized histogram.
%
% Author  : Mopuri K Reddy, SERC, IISc, Bengalur, INDIA.
% Date    : 25/10/2013.

if (size(I, 3) ~= 3)
    error('rgbhist:numberOfSamples', 'Input image must be RGB.')
end

if(nargin<3)
    Nind=0;
    % Default is un-normalized histogram
end

H=zeros([nBins nBins nBins]);

% for i=1:size(I,1)
%     for j=1:size(I,2)
%         p=double(reshape(I(i,j,:),[1 3]));
%         p=floor(p/(256/nBins))+1;
%         H(p(1),p(2),p(3))=H(p(1),p(2),p(3))+1;
%     end
% end

im=reshape(I,[size(I,1)*size(I,2) 3]);

for i=1:size(I,1)*size(I,2)
        p=double(im(i,:));
        p=floor(p/(256/nBins))+1;
        H(p(1),p(2),p(3))=H(p(1),p(2),p(3))+1;
end

H=H(:);
% Un-Normalized histogram

if(Nind==1)
    H=H./sum(H);
    % l1 normalization
else if(Nind==2)
        H=normc(H);
        % l2 normalization
    end
end
% We can use 'reshape' to get back to 3D histogram