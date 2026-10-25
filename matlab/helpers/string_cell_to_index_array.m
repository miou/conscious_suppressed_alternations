function y= string_cell_to_index_array(c,l)
a=cellfun(@(x)strcmp(c,x),l','UniformOutput',false);
b=cat(1,a{:});
[~,y] = max(b);