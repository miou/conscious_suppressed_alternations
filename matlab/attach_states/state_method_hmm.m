function inference_results = state_method_hmm(inference_scheme,session,paradigm_index);
inference_results = struct;

paradigm_data = session.paradigms_data{paradigm_index};

if ~isfield(inference_scheme,'selection_scheme') || isempty(inference_scheme.selection_scheme)
    inference_scheme.selection_scheme = 'all'; %Default to all cells
end
if ~isfield(inference_scheme,'bin_size') || isempty(inference_scheme.bin_size)
    inference_scheme.bin_size = 10; % Default to 10 ms.
end
paths_release = set_paths;
if isempty(session.simulation)
    hmm_file_location = [paths_release.python_states filesep inference_scheme.hmm_type filesep 'bin_' num2str(inference_scheme.bin_size) '_units_' inference_scheme.selection_scheme];
else %Load simulation HMM (simulations are not part of the public release; kept relocatable under data_root)
    hmm_file_location = [paths_release.data_root filesep 'simulated' filesep 'SIMULATED_' session.simulation.type filesep inference_scheme.hmm_type filesep 'bin_' num2str(inference_scheme.bin_size) '_units_' inference_scheme.selection_scheme];
end
if isfield(inference_scheme,'regions_to_include') && ~isempty(inference_scheme.regions_to_include)
    probe_indices = find(ismember(session.regions,inference_scheme.regions_to_include));
    if ~isempty(probe_indices)
        suffix= ['_p' num2str(probe_indices,'%d')];
    else
        disp(['Warning: Session ' session.session_name ' for inference scheme ' inference_scheme.name ' does not have any of the regions to include ' strjoin(inference_scheme.regions_to_include,', ') '. Skipping this scheme for this session.']);
        inference_results = [];
        return;   % session lacks these regions -> skip this scheme (e.g. PFC schemes on IT-only sessions)
    end
else
    suffix='';
end

hmm_file = [hmm_file_location filesep 'hmm_data_' session.session_name suffix];
if ~isfile([hmm_file '.mat'])
    disp(['Warning: no state file ' hmm_file '.mat -- skipping scheme ' inference_scheme.name ' for ' session.session_name '.']);
    inference_results = [];
    return;
end
hmm_states = load(hmm_file);

hmm_struct = hmm_states.([inference_scheme.hmm_method]);

inference_results.state_timecourse = hmm_struct.dom_sup_partition;

if isfield(hmm_struct,'stim_index_abcd')
    inference_results.stim_index_abcd = hmm_struct.stim_index_abcd;
end
if isfield(hmm_struct,'units_hmm')
    inference_results.selected_indices_for_state_inference = hmm_struct.units_hmm;
end

if isfield(hmm_struct,'model_states')
    inference_results.model_states_timecourse = hmm_struct.model_states;
    inference_results.on_off_timecourse = mod(hmm_struct.model_states+1,2);
end
flash_suppression_get_variables;%To get peristimulus_range

[inference_results.state_raster, b_in_range_states] = computeRaster(paradigm_data.timecourse_on_times,inference_results.state_timecourse',-peri_stimulus_range(1), peri_stimulus_range(end));
if ~(all(b_in_range_states==b_in_range))
    state_raster_temp = zeros(size(raster,1),size(raster,2));
    state_raster_temp(b_in_range_states,:) = inference_results.state_raster;
    inference_results.state_raster = state_raster_temp;
end

