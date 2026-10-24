function normalized_responses = normalize_neurons(responses,normalizing_responses,dimension,normalization_method);
%% dimension is the neuron dimension
%% normalization_method == 1 for using min and max for normalization to [0, 1]. normalization_method == 3 for z-scoring (time_course - mean )/std
if dimension == 1
    other_dimension = 2;
elseif dimension ==2 
    other_dimension = 1;
end
if normalization_method == 1
minimum_responses = min(normalizing_responses,[],other_dimension);
maximum_responses = max(normalizing_responses,[],other_dimension) - minimum_responses;
if dimension == 1
    normalized_responses = (responses - repmat(minimum_responses,[1,size(responses,other_dimension)]))./repmat(maximum_responses,[1,size(responses,other_dimension)]);
elseif dimension ==2 
    normalized_responses = (responses - repmat(minimum_responses,[size(responses,other_dimension),1]))./repmat(maximum_responses,[size(responses,other_dimension),1]);
end
elseif normalization_method == 3
    mean_responses = nanmean(normalizing_responses,other_dimension);
    std_responses = nanstd(normalizing_responses,0,other_dimension);
    std_responses(std_responses==0) = nan;
    if dimension == 1
            normalized_responses = (responses - repmat(mean_responses,[1,size(responses,other_dimension)]))./repmat(std_responses,[1,size(responses,other_dimension)]);
    elseif dimension ==2 
        normalized_responses = (responses - repmat(mean_responses,[size(responses,other_dimension),1]))./repmat(std_responses,[size(responses,other_dimension),1]);
    end
end
