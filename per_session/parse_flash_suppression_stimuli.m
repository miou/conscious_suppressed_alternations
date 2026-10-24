function stimulus_properties = parse_flash_suppression_stimuli(paradigm_data)
image_red = cell(1,length(paradigm_data.stimulus_list));
image_cyan = cell(1,length(paradigm_data.stimulus_list));
stimulus_contents = cell(1,length(paradigm_data.stimulus_list));
stimulus_contexts = cell(1,length(paradigm_data.stimulus_list));
for stimulus_index = 1:length(paradigm_data.stimulus_list)
    stimulus_name = paradigm_data.stimulus_list{stimulus_index};
    if strcmp(stimulus_name,'gray.tif')
        stimulus_contents{stimulus_index} = 'gray';
        stimulus_contexts{stimulus_index} = 'gray';
        image_cyan{stimulus_index} = 'gray';
        image_red{stimulus_index} = 'gray';
    else
        stimulus_content = {'_red_only','_cyan_only','_binocular','_transparent'};
        stimulus_context = {'_red_suppressed','_cyan_suppressed'};
        [match, remaining_string_before,remaining_string_after] = parse_string(stimulus_name ,stimulus_content);
        stimulus_contents{stimulus_index} = stimulus_content{match};
        [match, remaining_string_before,remaining_string_after] = parse_string(remaining_string_before ,stimulus_context);
        stimulus_contexts{stimulus_index} = stimulus_context{match};
        [match, remaining_string_before,remaining_string_after] = parse_string(remaining_string_before ,'_cyan_');
        image_cyan{stimulus_index} = remaining_string_after;
        [match, remaining_string_before,remaining_string_after] = parse_string(remaining_string_before ,'_red_');
        image_red{stimulus_index} = remaining_string_after;
    end
end
is_priming = (contains(stimulus_contexts,'red_suppressed') & contains(stimulus_contents,'red_only')) | (contains(stimulus_contexts,'cyan_suppressed') & contains(stimulus_contents,'cyan_only'));
is_unambiguous = (contains(stimulus_contents,'red_only') | contains(stimulus_contents,'cyan_only')) & ~is_priming;
stimulus_properties.image_red = image_red;
stimulus_properties.image_cyan = image_cyan;
stimulus_properties.stimulus_contents = stimulus_contents;
stimulus_properties.stimulus_contexts = stimulus_contexts;
stimulus_properties.is_priming = is_priming;
stimulus_properties.is_unambiguous = is_unambiguous;
end