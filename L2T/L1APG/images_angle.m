function a = images_angle(I1, I2)
I1v = double(I1(:));
I2v = double(I2(:));
I1vn = I1v./sqrt(sum(I1v.^2));
I2vn = I2v./sqrt(sum(I2v.^2));
a = acosd(I1vn'*I2vn);