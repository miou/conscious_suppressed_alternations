function p = gen_randn_param( np, data, seed)
% p = gen_randn_param( np, data)
% generate gaussian distributed random parameters
% np: number of parameter vectors to generate
% cut off to the max/min values 
rng(seed);

ndim = length(data.score_mean);
p = zeros(ndim, np);
for i = 1:ndim
    mean_1dim = data.score_mean(i);
    std_1dim = data.score_std(i);
    max_1dim = data.score_max(i);
    min_1dim = data.score_min(i);
  
    for j = 1:np
        r = randn * std_1dim + mean_1dim;
        while r >max_1dim || r <min_1dim
            r = randn * std_1dim + mean_1dim;
        end
        p(i,j) = r;
    end
end

end