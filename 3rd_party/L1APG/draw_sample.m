function [outs] = draw_sample(mean_afnv, std_afnv)
%draw transformation samples from a Gaussian distribution

nsamples = size(mean_afnv, 1);
MV_LEN = 6;
mean_afnv(:, 1) = log(mean_afnv(:, 1));
mean_afnv(:, 4) = log(mean_afnv(:, 4));

outs = zeros([nsamples, MV_LEN]); 

outs(:,1:MV_LEN) = randn([nsamples, MV_LEN])*diag(std_afnv) ...
    + mean_afnv;

outs(:,1) = exp(outs(:,1));
outs(:,4) = exp(outs(:,4));
