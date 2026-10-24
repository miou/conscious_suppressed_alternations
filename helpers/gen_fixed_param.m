function p = gen_fixed_param( nface, data, std_values)
% p = gen_fixed_param( np, data, std_values)
% Adapt from .\Model\gen_randn_param.m
% nface: number of parameter vectors to generate
% cut off to the max/min values 

ndim = length(data.score_mean);
p = zeros(ndim, nface);
for idim = 1:ndim
    mean_1dim = data.score_mean(idim);
    std_1dim = data.score_std(idim);
    max_1dim = data.score_max(idim);
    min_1dim = data.score_min(idim);
    
    for jface = 1:nface
        r = std_values(idim,jface) * std_1dim + mean_1dim;
        p(idim,jface) = r;
    end
end

end