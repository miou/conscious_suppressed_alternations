%% step4_combine_trial_decoding_full.m
% Assemble the per-session full-IT trial-decoding files (step3_run_and_save_trial_decoding_full)
% into the per-state summaries generate_fig_2_ev_decoding loads for its single-trial panels.
% Format matches the modulation summaries: flash_suppression_results_all_sessions{session_index}.

paths = set_paths;
rivalry_config  = switches_config_release;
n_sessions = numel(rivalry_config.sessions);

input_directory = fullfile(paths.results,'per_session_trialdec_full');
files = dir(fullfile(input_directory,'trialdec_full_*.mat'));
if isempty(files); error('No per-session full-IT trial-decoding files in %s', input_directory); end
fprintf('Combining %d per-session full-IT trial-decoding files.\n', numel(files));

per_session = cell(1,n_sessions);
for i = 1:numel(files)
    L = load(fullfile(files(i).folder, files(i).name), 'session_result');
    per_session{L.session_result.session_index} = L.session_result;
end

outdir = fullfile(paths.results,'trial_decoding_full');
if ~exist(outdir,'dir'); mkdir(outdir); end
for state_index = 1:2
    flash_suppression_results_all_sessions = cell(1,n_sessions);
    for s = 1:n_sessions
        if ~isempty(per_session{s}) && ~isempty(per_session{s}.variants{1,state_index})
            flash_suppression_results_all_sessions{s} = per_session{s}.variants{1,state_index};
        end
    end
    out = fullfile(outdir, sprintf('summary_IT_full_s%d.mat', state_index));
    save(out, 'flash_suppression_results_all_sessions', '-v7.3');
    fprintf('saved %s\n', out);
end
fprintf('step4_combine_trial_decoding_full done.\n');
