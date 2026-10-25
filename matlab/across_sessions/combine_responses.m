%% combine_responses.m
% Assemble the per-session response files written by run_and_save_results into the
% pooled summaries the figures load. Each summary is a cell array
% flash_suppression_results_all_sessions{session_index}; the figure-time pooling
% (across_sessions_analysis_axes_aux) then stitches them into a cross-session
% pseudo-population. Run once after the per-session response files exist.

paths = set_paths;
data  = switches_config_release;
n_sessions = numel(data.sessions);

input_directory = fullfile(paths.results,'per_session_responses');
response_files = dir(fullfile(input_directory,'responses_*.mat'));
if isempty(response_files); error('No per-session response files in %s', input_directory); end
fprintf('Combining %d per-session response files.\n', numel(response_files));

variant_names = {}; state_values = [];
per_session_results = cell(1,n_sessions);
for file_index = 1:numel(response_files)
    loaded = load(fullfile(input_directory, response_files(file_index).name), 'session_result');
    per_session_results{loaded.session_result.session_index} = loaded.session_result;
    variant_names = loaded.session_result.variant_names;
    state_values  = loaded.session_result.state_values;
end

% ---- priming summary (state-independent) ----
flash_suppression_results_all_sessions = cell(1,n_sessions);
for session_index = 1:n_sessions
    if ~isempty(per_session_results{session_index})
        flash_suppression_results_all_sessions{session_index} = per_session_results{session_index}.priming;
    end
end
save_axes_summary(flash_suppression_results_all_sessions, paths, 'priming', '');

% ---- per variant x state ----
for variant_index = 1:numel(variant_names)
    for state_index = 1:numel(state_values)
        flash_suppression_results_all_sessions = cell(1,n_sessions);
        for session_index = 1:n_sessions
            if ~isempty(per_session_results{session_index}) && ~isempty(per_session_results{session_index}.variants{variant_index,state_index})
                flash_suppression_results_all_sessions{session_index} = per_session_results{session_index}.variants{variant_index,state_index};
            end
        end
        states_string = ['states_' variant_names{variant_index} '_' num2str(state_values(state_index)) '_1'];
        save_axes_summary(flash_suppression_results_all_sessions, paths, 'dominant_binocular', states_string);
    end
end
fprintf('combine_responses done.\n');

function save_axes_summary(flash_suppression_results_all_sessions, paths, use_for_testing, states_string) %#ok<INUSD>
    output_file = release_axes_summary(paths, use_for_testing, states_string, true);
    save(output_file, 'flash_suppression_results_all_sessions', '-v7.3');
    fprintf('saved %s\n', output_file);
end
