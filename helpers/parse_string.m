function [match, remaining_string_before,remaining_string_after] = parse_string(input_string,patterns)
if ~iscell(patterns)
    patterns = {patterns};
end
remaining_string_before = input_string;
remaining_string_after = input_string;
match = nan;
for pattern_index = 1:length(patterns)
    position = strfind(input_string,patterns{pattern_index});
    if ~isempty(position)
        match = pattern_index;
        if position >1
            remaining_string_before = input_string(1:position-1);
        else
            remaining_string_before = '';
        end
        if position+length(patterns{pattern_index})<=length(input_string)
            remaining_string_after = input_string((position+length(patterns{pattern_index})):end);
        else
            remaining_string_after = '';
        end
    end
end
end