% flash_suppression_add_variables_to_session  (SCRIPT — runs in the caller's workspace)
% Writes the variables defined by flash_suppression_get_variables back into the session, under
% session.paradigms_data{paradigm_index}.flash_suppression.*, so they can be saved (used by the
% step-1 HDF5 export for the Python pipeline).
%   Expects: session, paradigm_index, and the workspace from flash_suppression_get_variables.
%   Produces: the flash_suppression.* fields (trial-context masks, priming-stimulus lists,
%     priming responses, dominant/suppressed image indices) on session.paradigms_data{paradigm_index}.
session.paradigms_data{paradigm_index}.b_in_range = b_in_range;
session.paradigms_data{paradigm_index}.flash_suppression.trial_is_priming = trial_is_priming;
session.paradigms_data{paradigm_index}.flash_suppression.trial_is_unambiguous = trial_is_unambiguous;
session.paradigms_data{paradigm_index}.flash_suppression.trial_is_binocular = trial_is_binocular;
session.paradigms_data{paradigm_index}.flash_suppression.trial_is_transparent = trial_is_transparent;
session.paradigms_data{paradigm_index}.flash_suppression.trial_is_gray = trial_is_gray;
[session.paradigms_data{paradigm_index}.flash_suppression.responses_priming, ~,~] = flash_suppression_get_priming_responses(raster,peri_stimulus_range,[50,median(on_durations_in_range(trial_is_priming))],priming_stimuli_list,priming_stimuli,stimulus_index_in_range);
session.paradigms_data{paradigm_index}.flash_suppression.priming_stimuli_list = priming_stimuli_list;
session.paradigms_data{paradigm_index}.flash_suppression.priming_stimuli_red_list = priming_stimuli_red_list;
session.paradigms_data{paradigm_index}.flash_suppression.priming_stimuli_cyan_list = priming_stimuli_cyan_list;
session.paradigms_data{paradigm_index}.flash_suppression.priming_stimuli_list_is_red = priming_stimuli_list_is_red;
session.paradigms_data{paradigm_index}.flash_suppression.priming_stimuli_list_is_cyan = priming_stimuli_list_is_cyan;

session.paradigms_data{paradigm_index}.flash_suppression.trial_dominant_image_index = nan(size(trial_is_priming)); 
session.paradigms_data{paradigm_index}.flash_suppression.trial_suppressed_image_index = nan(size(trial_is_priming)); 
for trial_index = 1:length(trial_is_priming)
    if trial_is_priming(trial_index) %Reverse suppressed and dominant for priming
        session.paradigms_data{paradigm_index}.flash_suppression.trial_dominant_image_index(trial_index) = find(strcmp(trial_suppressed_image(trial_index),priming_stimuli_list));
        session.paradigms_data{paradigm_index}.flash_suppression.trial_suppressed_image_index(trial_index) = find(strcmp(trial_dominant_image(trial_index),priming_stimuli_list));
    elseif ~trial_is_gray(trial_index)
        session.paradigms_data{paradigm_index}.flash_suppression.trial_dominant_image_index(trial_index) = find(strcmp(trial_dominant_image(trial_index),priming_stimuli_list));
        session.paradigms_data{paradigm_index}.flash_suppression.trial_suppressed_image_index(trial_index) = find(strcmp(trial_suppressed_image(trial_index),priming_stimuli_list));       
    end

end