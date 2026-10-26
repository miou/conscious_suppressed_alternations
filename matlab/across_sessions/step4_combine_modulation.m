%% step4_combine_modulation.m
% Assemble the per-session modulation files from step3_run_and_save_modulation into the
% per-(variant,state) summaries the modulation figures load. Each summary is a cell
% array flash_suppression_results_all_sessions{session_index}; the modulation aux
% (across_sessions_analysis_all_combinations_modulation_aux) pools them.
% Run once after the per-session modulation files exist.

paths = set_paths;
rivalry_config  = switches_config_release;
n_sessions = numel(rivalry_config.sessions);

input_directory = fullfile(paths.results,'per_session_modulation');
modulation_files = dir(fullfile(input_directory,'modulation_*.mat'));
if isempty(modulation_files); error('No per-session modulation files in %s', input_directory); end
fprintf('Combining %d per-session modulation files.\n', numel(modulation_files));

variant_names = {}; state_values = [];
per_session_results = cell(1,n_sessions);
for file_index = 1:numel(modulation_files)
    loaded = load(fullfile(input_directory, modulation_files(file_index).name), 'session_result');
    per_session_results{loaded.session_result.session_index} = loaded.session_result;
    variant_names = loaded.session_result.variant_names;
    state_values  = loaded.session_result.state_values;
end

for variant_index = 1:numel(variant_names)
    for state_index = 1:numel(state_values)
        flash_suppression_results_all_sessions = cell(1,n_sessions);
        for session_index = 1:n_sessions
            if ~isempty(per_session_results{session_index}) && ~isempty(per_session_results{session_index}.variants{variant_index,state_index})
                flash_suppression_results_all_sessions{session_index} = per_session_results{session_index}.variants{variant_index,state_index};
            end
        end
        output_file = release_modulation_summary(paths, variant_names{variant_index}, state_values(state_index), true);
        save(output_file, 'flash_suppression_results_all_sessions', '-v7.3');
        fprintf('saved %s\n', output_file);
    end
end
fprintf('step4_combine_modulation done.\n');
