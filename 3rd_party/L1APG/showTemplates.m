function [img, templates] = showTemplates(img, A, A_mean, A_norm, tsize, nt)
if(size(img,3) == 1)
    for i=1:3
        img_color(:,:,i) = img;
    end
    img = img_color;
end

for i=1:nt
    tt = A(:,i);
    tt = tt*A_norm(i)+A_mean(:,i);
    tt = reshape(tt,tsize);
    for j=1:3
        img(end-tsize(1)+1:end,(i-1)*tsize(2)+1:i*tsize(2),j) = tt;
    end
    templates(:,:,i) = tt;
end
%save templates templates;

