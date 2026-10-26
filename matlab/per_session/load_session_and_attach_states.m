function session = load_session_and_attach_states(session_file, rivalry_config)
%LOAD_SESSION_AND_ATTACH_STATES  Load a simplified session, free its in-memory LFP, and
% attach the release inference schemes/states. Returns [] if the file cannot be loaded.
%
% The LFPs are cleared from the in-memory copy only (they stay in the on-disk session); the
% step-3 compute never uses them and they are the bulk of the loaded session. States are
% (re)attached unconditionally: a simplified session may carry an inference_results from the
% source pipeline whose schemes are not the ones the figures use, which would otherwise make
% every state-conditioned variant skip.
fprintf('Loading %s ...\n', session_file); load_timer = tic;
try
    loaded = load(session_file, 'session');
catch load_error
    fprintf('  load failed: %s\n', load_error.message); session = []; return;
end
session = loaded.session; fprintf('  loaded %.0fs\n', toc(load_timer));
if ~isfield(session, 'simulation'); session.simulation = []; end

for paradigm_index = 1:numel(session.paradigms_data)
    if ~isempty(session.paradigms_data{paradigm_index})
        if isfield(session.paradigms_data{paradigm_index}, 'lfp_timecourse_all_probes');   session.paradigms_data{paradigm_index}.lfp_timecourse_all_probes   = []; end
        if isfield(session.paradigms_data{paradigm_index}, 'lfp_timecourse_all_channels'); session.paradigms_data{paradigm_index}.lfp_timecourse_all_channels = []; end
    end
end

fprintf('  attaching states...\n'); attach_timer = tic;
[session.inference_schemes, session.inference_results] = switches_infer_states(rivalry_config, session);
fprintf('  states attached %.0fs\n', toc(attach_timer));
end
