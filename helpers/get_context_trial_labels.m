if strcmp(trial_context_name,'priming')

    stimulus_is_context = stimulus_properties.is_priming;
    trial_is_context = trial_is_priming_selected;
    trial_is_context_all = trial_is_priming; % Do not care about previous trial for priming itself.
    context_trial_labels_dominant = trial_priming_stimuli(trial_is_context);
    context_trial_labels_suppressed = trial_dominant_image(trial_is_context); %For priming, call the flashed stimulus "suppressed" (as it is not present yet)
    context_trial_labels_dominant_all = trial_priming_stimuli(trial_is_context_all);
    context_trial_labels_suppressed_all = trial_dominant_image(trial_is_context_all);
else

    if strcmp(trial_context_name,'unambiguous')
        stimulus_is_context = stimulus_is_unambiguous;
        trial_is_context = trial_is_unambiguous_selected;
        trial_is_context_all = trial_is_unambiguous;

    elseif strcmp(trial_context_name,'binocular')
        stimulus_is_context = stimulus_is_binocular;
        trial_is_context = trial_is_binocular_selected;
        trial_is_context_all = trial_is_binocular;

    elseif strcmp(trial_context_name,'transparent')
        stimulus_is_context = stimulus_is_transparent;
        trial_is_context = trial_is_transparent_selected;
        trial_is_context_all = trial_is_transparent;

    end

    context_trial_labels_dominant = trial_dominant_image(trial_is_context);
    context_trial_labels_suppressed = trial_suppressed_image(trial_is_context);
    context_trial_labels_dominant_all = trial_dominant_image(trial_is_context_all);
    context_trial_labels_suppressed_all = trial_suppressed_image(trial_is_context_all);

end
context_trial_labels_red = trial_red_image(trial_is_context);
context_trial_labels_cyan = trial_cyan_image(trial_is_context);
context_trial_labels_red_all = trial_red_image(trial_is_context_all);
context_trial_labels_cyan_all = trial_cyan_image(trial_is_context_all);

context_trials_on_times = on_times_in_range(trial_is_context);
context_trials_on_times_all = on_times_in_range(trial_is_context_all);
context_trial_label_indices_dominant = string_cell_to_index_array(context_trial_labels_dominant,labels_list)';
context_trial_label_indices_suppressed = string_cell_to_index_array(context_trial_labels_suppressed,labels_list)';

context_trial_label_indices_red = string_cell_to_index_array(context_trial_labels_red,labels_list)';
context_trial_label_indices_cyan = string_cell_to_index_array(context_trial_labels_cyan,labels_list)';

context_trial_label_indices_dominant_all = string_cell_to_index_array(context_trial_labels_dominant_all,labels_list)';
context_trial_label_indices_suppressed_all = string_cell_to_index_array(context_trial_labels_suppressed_all,labels_list)';

context_trial_label_indices_red_all = string_cell_to_index_array(context_trial_labels_red_all,labels_list)';
context_trial_label_indices_cyan_all = string_cell_to_index_array(context_trial_labels_cyan_all,labels_list)';


context_trial_is_red_dominant = labels_list_is_red(context_trial_label_indices_dominant);
context_trial_is_red_suppressed = labels_list_is_red(context_trial_label_indices_suppressed);
context_trial_is_cyan_dominant = labels_list_is_cyan(context_trial_label_indices_dominant);
context_trial_is_cyan_suppressed = labels_list_is_cyan(context_trial_label_indices_suppressed);
context_trial_indices = find(trial_is_context);
context_trial_indices_all = find(trial_is_context_all);

label_indices = 1:length(labels_list);
