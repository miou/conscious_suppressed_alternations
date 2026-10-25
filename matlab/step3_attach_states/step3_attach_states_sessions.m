%% step3_attach_states_sessions.m
% Step 3 of the pipeline: load each session, attach the states inferred by the
% Python LLR/HMM pipeline (step 2), and save the session with the states in it.
%
% Reads the state files from paths.conor_states (produced by step 2) and writes
% them into session.inference_results. After this, each session_*.mat is ready
% for the figure scripts (step 4).

paths = set_paths;
data  = switches_config_release;

for session_index = 1:numel(data.sessions)

    session_file = fullfile(paths.sessions, [data.sessions(session_index).session_name '.mat']);
    fprintf('Loading %s...\n', session_file);
    load(session_file, 'session');
    if ~isfield(session,'simulation'); session.simulation = []; end

    [session.inference_schemes, session.inference_results] = switches_infer_states(data, session);

    save(session_file, 'session', '-v7.3', '-nocompression');
    fprintf('  attached states and saved.\n');
    clear session;
end

fprintf('Step 3 complete: states attached to %d sessions.\n', numel(data.sessions));
