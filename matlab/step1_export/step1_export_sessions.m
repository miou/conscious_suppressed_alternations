%% step1_export_sessions.m
% Step 1 of the pipeline: export each session's flash-suppression spike data to
% an HDF5 file for the Python LLR/HMM state-inference pipeline (step 2).
%
% One '.h5' per session is written to paths.h5_export, named
% 'session_<session_name>.h5' using the session's own (original) name, so the
% file names match what the Python pipeline expects.
%
% Run step 2 (Python) on these files; the response step (step 3) then attaches the states on load.

paths = set_paths;
rivalry_config  = switches_config_release;

if ~exist(paths.h5_export,'dir'); mkdir(paths.h5_export); end

for session_index = 1:length(rivalry_config.sessions)

    session_file = fullfile(paths.sessions, [rivalry_config.sessions(session_index).session_name '.mat']);
    fprintf('Loading %s...\n', session_file);
    load(session_file, 'session');

    % Populate the flash-suppression variables each flash-suppression paradigm needs
    paradigm_indices = find(cellfun(@(x)~isempty(x) && contains(x,'flash_suppression'), session.paradigm_names));
    for paradigm_index = paradigm_indices
        paradigm_data = session.paradigms_data{paradigm_index};
        flash_suppression_get_variables;              % reads paradigm_data, defines priming/binocular variables
        flash_suppression_add_variables_to_session;   % writes session.paradigms_data{paradigm_index}.flash_suppression
    end

    % Export to HDF5 (named by the session's own name, for the Python pipeline)
    out_fpath = fullfile(paths.h5_export, ['session_' session.session_name '.h5']);
    extract_session_to_hdf5(session, session_index, out_fpath);

    clear session;
end

fprintf('Step 1 complete: %d sessions exported to %s\n', numel(rivalry_config.sessions), paths.h5_export);
