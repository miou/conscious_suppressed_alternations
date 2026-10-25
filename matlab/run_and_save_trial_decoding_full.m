%% run_and_save_trial_decoding_full.m
% Full-population IT single-trial decoding (Fig 2k/l): states inferred from ALL IT neurons
% (scheme 'Fixed rate LLR IT 10 ms', si=50) and decoding measured on all neurons (no
% held-out exclusion -- the full scheme has no selected_indices_for_state_inference).
% Mirrors run_and_save_modulation's per-session machinery but computes ONLY trial_decoding
% (no modulation) for the full-IT variant. One file per session; combine_trial_decoding_full
% assembles the per-state summaries generate_fig_2_ev_decoding loads for its single-trial panels.

paths = set_paths;
data  = switches_config_release;
if ~exist('session_list','var') || isempty(session_list)
    session_list = 1:numel(data.sessions);
end
output_directory = fullfile(paths.results,'per_session_trialdec_full');
if ~exist(output_directory,'dir'); mkdir(output_directory); end

variant_names = {'Fixed rate LLR IT 10 ms'};   % FULL IT (all neurons) -- Fig 2 single-trial
state_values  = [1 2];

for session_index = session_list
    session_name = data.sessions(session_index).session_name;
    if ~strcmp(data.sessions(session_index).group,'many_combinations'); continue; end
    session_file = fullfile(paths.sessions, [session_name '.mat']);
    if ~exist(session_file,'file'); fprintf('skip (missing): %s\n', session_file); continue; end
    fprintf('Loading %s ...\n', session_file); load_timer = tic;
    try
        load(session_file,'session'); fprintf('  loaded %.0fs\n', toc(load_timer));
    catch load_error
        fprintf('  SKIP %s -- load failed: %s\n', session_name, load_error.message); continue;
    end
    if ~isfield(session,'simulation'); session.simulation = []; end
    for lfp_clear_paradigm = 1:numel(session.paradigms_data)
        if ~isempty(session.paradigms_data{lfp_clear_paradigm})
            if isfield(session.paradigms_data{lfp_clear_paradigm},'lfp_timecourse_all_probes');   session.paradigms_data{lfp_clear_paradigm}.lfp_timecourse_all_probes   = []; end
            if isfield(session.paradigms_data{lfp_clear_paradigm},'lfp_timecourse_all_channels'); session.paradigms_data{lfp_clear_paradigm}.lfp_timecourse_all_channels = []; end
        end
    end
    fprintf('  attaching states...\n'); attach_timer = tic;
    [session.inference_schemes, session.inference_results] = switches_infer_states(data, session);
    fprintf('  states attached %.0fs\n', toc(attach_timer));
    paradigm_indices = find(cellfun(@(x)~isempty(x) && contains(x,'flash_suppression') && ~contains(x,'many_stimuli'), session.paradigm_names));
    if isempty(paradigm_indices); fprintf('  no all-combinations paradigm, skipping\n'); clear session; continue; end

    session_result = struct('session_index',session_index,'session_name',session_name, ...
        'variant_names',{variant_names},'state_values',state_values, ...
        'variants',{cell(numel(variant_names),numel(state_values))});

    for paradigm_index = paradigm_indices
        paradigm_data = session.paradigms_data{paradigm_index};
        config = struct();
        config.b_normalize_raster_for_axes = true;
        config.avg_first_dimension = 0;
        config.b_use_control_1_stimuli = false;
        config.balance_states_each_trial = false;
        config.minimum_state_proportion_per_trial = [];
        config.remove_other_stimulus_from_training = true;
        config.time_window_priming = [300 1000];
        trial_time_window = 300:1000;
        nanmean_function = @(x) squeeze(nanmean(reshape(x,[],1,size(x,3)),1)); %#ok<NASGU>

        flash_suppression_get_variables;    % raster + trial/stimulus structure

        for variant_index = 1:numel(variant_names)
            scheme_index = find(strcmp({session.inference_schemes.name}, variant_names{variant_index}), 1);
            if isempty(scheme_index) || isempty(session.inference_results{paradigm_index, scheme_index})
                continue;
            end
            for state_index = 1:numel(state_values)
                config.states_to_use = struct('inference_scheme',variant_names{variant_index}, ...
                    'state_value',state_values(state_index),'only_apply_to_testing',true);
                peristimulus_index_range_of_interest = find(peri_stimulus_range == trial_time_window(1)) : ...
                    find(peri_stimulus_range == trial_time_window(end)); %#ok<NASGU>
                raster_state = turn_non_states_into_nan(raster,config,session,paradigm_index,peristimulus_index_range_of_interest); %#ok<NASGU>
                flash_suppression_results = struct();
                flash_suppression_trial_decoding;   % full population (no held-out exclusion for the full scheme)
                flash_suppression_results.unit_probes_index = session.unit_probes_index;
                flash_suppression_results.regions           = session.regions;
                flash_suppression_results.session_name      = session.session_name;
                flash_suppression_results.unit_regions      = session.regions(session.unit_probes_index);
                session_result.variants{variant_index,state_index} = flash_suppression_results;
                fprintf('  %s state %d done\n', variant_names{variant_index}, state_values(state_index));
            end
        end
    end

    output_file = fullfile(output_directory, ['trialdec_full_' session_name '.mat']);
    save(output_file, 'session_result', '-v7.3');
    fprintf('saved %s\n', output_file);
    clear session raster raster_state session_result;
end
fprintf('run_and_save_trial_decoding_full done. Run combine_trial_decoding_full to build the summaries.\n');
