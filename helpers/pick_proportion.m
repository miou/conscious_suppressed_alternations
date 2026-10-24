function output_array = pick_proportion(input_array,proportion,dim)
%Randomly picks 0<=proportion<=1 proportion of array
if nargin==2 || isempty(dim)
    shuffled_array = shuffle_array(input_array);
    output_array = shuffled_array(1:round(length(shuffled_array)*proportion));
elseif dim == 1
    shuffled_array = shuffle_array(input_array,dim);
    output_array = shuffled_array(1:round(size(shuffled_array,1)*proportion),:);
elseif dim == 2
    shuffled_array = shuffle_array(input_array,dim);
    output_array = shuffled_array(:,1:round(size(shuffled_array,2)*proportion));
end