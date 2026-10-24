%% run_and_save_results.m
% Step 4a (per session): compute the state-conditioned neuron x stimulus RESPONSE
% matrices for the many_faces sessions and save ONE file per session. A separate
% combine step (combine_responses.m) assembles these into the pooled summaries the
% figures load. This per-session layout is what makes step 4a parallelizable:
% run several copies with disjoint session_list values, then combine once.
%
% Responses-only: no per-session reconstruction/EV/decoding. The figure-time
% pooling (across_sessions_analysis_axes_aux) stitches the per-session response
% matrices into a cross-session pseudo-population and does PCA/OLS/EV/reconstruction/
% decoding ONCE on the pool.
%
% One load per session: priming + all variants x (state 1, state 2) are computed
% from the single loaded session. States are attached here if the session does not
% already carry them (so a separate step 3 save is not required).

paths = set_paths;
data  = switches_config_release;

% By default process every session; sessions without the many_stimuli (reconstruction)
% paradigm are skipped automatically below. Set session_list in the workspace to a
% subset to split the work across parallel runs.
if ~exist('session_list','var') || isempty(session_list)
    session_list = 1:numel(data.sessions);
end

output_directory = fullfile(paths.results,'per_session_responses');
if ~exist(output_directory,'dir'); mkdir(output_directory); end

% Reconstruction variants: each is a state scheme applied to the same loaded spikes.
% IT full/half -> Fig 2/3; PFC full/half -> Fig 6; ML-only/AM-only HMM -> Fig 5
% cross-area interaction (states inferred in one area, features reconstructed from the other).
variant_names = {'Fixed rate LLR IT 10 ms', 'Fixed rate LLR IT 10 ms half neurons', ...
                 'Fixed rate LLR PFC 10 ms', 'Fixed rate LLR PFC 10 ms half neurons', ...
                 'Fixed rate HMM ML', 'Fixed rate HMM AM'};
state_values  = [1 2];

for session_index = session_list
    session_name = data.sessions(session_index).session_name;
    if ~strcmp(data.sessions(session_index).group,'many_faces'); continue; end   % reconstruction uses the many_faces sessions only -- skip without loading
    session_file = fullfile(paths.sessions, [session_name '.mat']);
    if ~exist(session_file,'file'); fprintf('skip (missing): %s\n', session_file); continue; end
    fprintf('Loading %s ...\n', session_file); load_timer = tic;
    try
        load(session_file,'session'); fprintf('  loaded %.0fs\n', toc(load_timer));
    catch load_error
        fprintf('  SKIP %s -- load failed: %s\n', session_name, load_error.message); continue;
    end
    if ~isfield(session,'simulation'); session.simulation = []; end

    % For memory: drop the LFPs -- the responses compute never uses them, and they are
    % ~100 GB of the loaded session (matches flash_suppression_analysis.m). The LFPs stay
    % in the on-disk session for the release; this only frees the in-memory copy.
    for lfp_clear_paradigm = 1:numel(session.paradigms_data)
        if ~isempty(session.paradigms_data{lfp_clear_paradigm})
            if isfield(session.paradigms_data{lfp_clear_paradigm},'lfp_timecourse_all_probes');   session.paradigms_data{lfp_clear_paradigm}.lfp_timecourse_all_probes   = []; end
            if isfield(session.paradigms_data{lfp_clear_paradigm},'lfp_timecourse_all_channels'); session.paradigms_data{lfp_clear_paradigm}.lfp_timecourse_all_channels = []; end
        end
    end

    % Attach states fresh (step 3). A simplified session may still carry an
    % inference_results from the source pipeline whose schemes are not the ones the
    % figures use, so (re)attach the release schemes unconditionally rather than trust
    % whatever is already on the session -- otherwise the variants below are all skipped.
    fprintf('  attaching states...\n'); attach_timer = tic;
    [session.inference_schemes, session.inference_results] = switches_infer_states(data, session);
    fprintf('  states attached %.0fs\n', toc(attach_timer));

    paradigm_indices = find(cellfun(@(x)~isempty(x) && contains(x,'flash_suppression_many_stimuli'), session.paradigm_names));
    if isempty(paradigm_indices); fprintf('  no many_stimuli paradigm, skipping\n'); clear session; continue; end

    session_result = struct('session_index',session_index,'session_name',session_name, ...
        'variant_names',{variant_names},'state_values',state_values, ...
        'priming',[],'variants',{cell(numel(variant_names),numel(state_values))});

    for paradigm_index = paradigm_indices
        paradigm_data = session.paradigms_data{paradigm_index};

        % ---- base config (as in flash_suppression_analysis) ----
        config = struct();
        config.b_use_same_random_stimuli_across_iterations = false;
        config.use_axes_from_first_paradigm = 0;
        config.b_normalize_raster_for_axes = true;
        config.time_window_priming = [300 1000];
        config.time_window_binocular = [300 1000];
        config.b_concatenate_features_other = false;
        config.use_for_training = 'priming';
        config.use_half_stimuli = 0;
        config.min_number_occurences = 1;
        config.b_plot_single_cells = false;
        config.avg_first_dimension = 0;
        config.balance_states_each_trial = false;
        config.minimum_state_proportion_per_trial = [];
        config.remove_other_stimulus_from_training = true;
        config.b_use_control_1_stimuli = false;
        trial_time_window = 300:1000;
        nanmean_function = @(x) squeeze(nanmean(reshape(x,[],1,size(x,3)),1)); %#ok<NASGU>

        % the trial raster is computed ONCE per session
        flash_suppression_get_variables;

        % ---- priming (state-independent) ----
        config.use_for_testing = 'priming';
        config.states_to_use = [];
        raster_state = raster; %#ok<NASGU>
        flash_suppression_results = struct();
        flash_suppression_compute_axes;
        session_result.priming = add_meta(flash_suppression_results, session, paradigm_data);

        % ---- each variant x binocular state ----
        for variant_index = 1:numel(variant_names)
            scheme_index = find(strcmp({session.inference_schemes.name}, variant_names{variant_index}), 1);
            if isempty(scheme_index) || isempty(session.inference_results{paradigm_index, scheme_index})
                continue;   % this variant's states were not attached for this session
            end
            for state_index = 1:numel(state_values)
                config.use_for_testing = 'dominant_binocular';
                config.states_to_use = struct('inference_scheme',variant_names{variant_index}, ...
                    'state_value',state_values(state_index),'only_apply_to_testing',true);
                peristimulus_index_range_of_interest = find(peri_stimulus_range == trial_time_window(1)) : ...
                    find(peri_stimulus_range == trial_time_window(end)); %#ok<NASGU>
                raster_state = turn_non_states_into_nan(raster,config,session,paradigm_index,peristimulus_index_range_of_interest); %#ok<NASGU>
                flash_suppression_results = struct();
                flash_suppression_compute_axes;
                session_result.variants{variant_index,state_index} = add_meta(flash_suppression_results, session, paradigm_data);
                fprintf('  %s state %d done\n', variant_names{variant_index}, state_values(state_index));
            end
        end
    end

    output_file = fullfile(output_directory, ['responses_' session_name '.mat']);
    save(output_file, 'session_result', '-v7.3');
    fprintf('saved %s\n', output_file);
    clear session raster raster_state session_result;
end
fprintf('run_and_save_results done (per-session). Run combine_responses to build the pooled summaries.\n');

% ===== local functions =====
function result = add_meta(result, session, paradigm_data)
    result.unit_probes_index    = session.unit_probes_index;
    result.regions              = session.regions;
    result.session_name         = session.session_name;
    result.simulation           = session.simulation;
    result.fsi                  = session.face_vs_object(paradigm_data.paradigm_index_for_selectivity).fsi;
    result.fsi_pvalue           = session.face_vs_object(paradigm_data.paradigm_index_for_selectivity).p_value_face_vs_object;
    result.p_value_visual_response = session.face_vs_object(paradigm_data.paradigm_index_for_selectivity).p_value_visual_response;
    result.responsiveness_index = session.face_vs_object(paradigm_data.paradigm_index_for_selectivity).responsiveness_index;
end
