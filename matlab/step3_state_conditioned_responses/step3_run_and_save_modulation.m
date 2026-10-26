%% step3_run_and_save_modulation.m
% Step 3 (modulation): compute per-cell modulation indices for the many_combinations
% (all-combinations / "fso") sessions and save ONE file per session. step4_combine_modulation.m
% then assembles the per-state summaries the modulation figures load (fig_1_modulation,
% fig_6 PFC panels). Parallelizable: run with disjoint session_list, then combine once.
%
% One load per session: all variants (IT, PFC, PFC half) x (state 1, state 2) are
% computed from the single loaded session. States attached here if absent.

paths = set_paths;
rivalry_config  = switches_config_release;

% By default process every session; sessions without the all-combinations paradigm are
% skipped automatically below. Set session_list in the workspace for parallel subsets.
if ~exist('session_list','var') || isempty(session_list)
    session_list = 1:numel(rivalry_config.sessions);
end

output_directory = fullfile(paths.results,'per_session_modulation');
if ~exist(output_directory,'dir'); mkdir(output_directory); end

% Modulation indices are half-neuron cross-validated in the paper (states inferred from
% one half of the neurons, modulation measured on the other half), so use only the
% half-neuron variants: IT half (ML/AM) for Fig 1/4, PFC half for Fig 6.
variant_names = {'Fixed rate LLR IT 10 ms half neurons', 'Fixed rate LLR PFC 10 ms half neurons'};
state_values  = [1 2];

for session_index = session_list
    session_name = rivalry_config.sessions(session_index).session_name;
    if ~strcmp(rivalry_config.sessions(session_index).group,'many_combinations'); continue; end   % modulation uses the many_combinations sessions only -- skip without loading
    session_file = fullfile(paths.sessions, [session_name '.mat']);
    if ~exist(session_file,'file'); fprintf('skip (missing): %s\n', session_file); continue; end
    session = load_session_and_attach_states(session_file, rivalry_config);
    if isempty(session); continue; end
    % all-combinations sessions carry the flash_suppression_optimized paradigm (not many_stimuli)
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
        trial_time_window = rivalry_config.trial_time_window;
        nanmean_function = @(x) squeeze(nanmean(reshape(x,[],1,size(x,3)),1)); %#ok<NASGU>

        flash_suppression_get_variables;    % raster + trial/stimulus structure

        % Per-neuron gray-baseline mean/std and visual-response selectivity (state-independent;
        % used by the slope-equalized modulation plot, Fig 4).
        gray_duration = median(on_durations_in_range(trial_is_gray));
        neurons_mean = mean(mean(raster(trial_is_gray,find(50==peri_stimulus_range):find(gray_duration==peri_stimulus_range),:),2),1);
        neurons_std  = std(mean(raster(trial_is_gray,find(50==peri_stimulus_range):find(gray_duration==peri_stimulus_range),:)),[],2);
        selectivity  = session.face_vs_object(paradigm_data.paradigm_index_for_selectivity);

        for variant_index = 1:numel(variant_names)
            scheme_index = find(strcmp({session.inference_schemes.name}, variant_names{variant_index}), 1);
            if isempty(scheme_index) || isempty(session.inference_results{paradigm_index, scheme_index})
                continue;   % variant's states not attached for this session
            end
            for state_index = 1:numel(state_values)
                config.states_to_use = struct('inference_scheme',variant_names{variant_index}, ...
                    'state_value',state_values(state_index),'only_apply_to_testing',true);
                peristimulus_index_range_of_interest = find(peri_stimulus_range == trial_time_window(1)) : ...
                    find(peri_stimulus_range == trial_time_window(end)); %#ok<NASGU>
                raster_state = turn_non_states_into_nan(raster,config,session,paradigm_index,peristimulus_index_range_of_interest); %#ok<NASGU>
                flash_suppression_results = struct();
                flash_suppression_compute_modulation_indices_all;   % fills .<context>.modulation_indices

                % Half-neuron held-out control: mark the neurons NOT used for state inference.
                % The figure-time aux (across_sessions_analysis_all_combinations_modulation_aux,
                % line 191) applies this mask so modulation is measured only on the held-out half.
                % flash_suppression_compute_modulation_indices measures ALL neurons, so without
                % this field the modulation pools both halves (~2x the cell-stimulus pairs) and
                % does not match the paper. Mirrors flash_suppression_trial_decoding.m.
                infres = session.inference_results{paradigm_index, scheme_index};
                if isfield(infres,'selected_indices_for_state_inference') && ~isempty(infres.selected_indices_for_state_inference)
                    flash_suppression_results.b_neuron_is_not_for_state_inference = ...
                        ~ismember(1:size(raster,3), infres.selected_indices_for_state_inference);
                end

                % Single-trial decoding, computed in the SAME session load as the modulation
                % (as in the lab pipeline). Fills flash_suppression_results.trial_decoding.<region>
                % for the single-trial panels (Fig 2k/l, 3h/i, 6). Train-once inside the helper.
                config.time_window_priming = rivalry_config.time_window_priming;
                flash_suppression_trial_decoding;

                flash_suppression_results.unit_probes_index = session.unit_probes_index;
                flash_suppression_results.regions           = session.regions;
                flash_suppression_results.session_name      = session.session_name;
                flash_suppression_results.unit_regions      = session.regions(session.unit_probes_index);
                flash_suppression_results.neurons_mean      = neurons_mean;
                flash_suppression_results.neurons_std       = neurons_std;
                flash_suppression_results.fsi               = selectivity.fsi;
                flash_suppression_results.p_value_visual_response = selectivity.p_value_visual_response;
                flash_suppression_results.responsiveness_index    = selectivity.responsiveness_index;
                session_result.variants{variant_index,state_index} = flash_suppression_results;
                fprintf('  %s state %d done\n', variant_names{variant_index}, state_values(state_index));
            end
        end
    end

    output_file = fullfile(output_directory, ['modulation_' session_name '.mat']);
    save(output_file, 'session_result', '-v7.3');
    fprintf('saved %s\n', output_file);
    clear session raster raster_state session_result;
end
fprintf('step3_run_and_save_modulation done (per-session). Run step4_combine_modulation to build the summaries.\n');
