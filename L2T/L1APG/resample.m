function [map_afnv, count] = resample(curr_samples, prob, afnv)
%% resample with respect to observation likelihood

nsamples = size(curr_samples, 1);
if(sum(prob) == 0)
    map_afnv = ones(nsamples, 1)*afnv;
    count = zeros(size(prob));
else
    prob = prob / sum(prob);
    count = round(nsamples * prob);

    map_afnv = [];
    for i=1:nsamples
        for j = 1:count(i)
            map_afnv = [map_afnv; curr_samples(i,:)];
        end
    end
    ns = sum(count); %number of resampled samples can be less or greater than nsamples
    map_afnv = [map_afnv; ones(nsamples-ns, 1)*afnv]; %if less
    map_afnv = map_afnv(1:nsamples, :); %if more
end
