trial_context_list = {'priming','unambiguous','binocular','transparent'};
for trial_context_index = 1:length(trial_context_list)
    trial_context_name = trial_context_list{trial_context_index};
    flash_suppression_results.(trial_context_name) = struct();
    get_context_trial_labels;

    flash_suppression_compute_modulation_indices;
end