config.paradigm_index = find(cellfun(@(x)~isempty(x) && (contains(x,'flash_suppression_many_stimuli') ),session.paradigm_names,'UniformOutput',true) ); %Liang's monkey faces
if contains(paradigm_data.xml_filename,'FlashSuppression_many_faces_Liang_2500_many_pairs_priming_reconstructed_0.00_transparent.xml')
    config.analyze_transparent = true;
else
    config.analyze_transparent = false;
end

stimuli_to_include_list = {''};
for stimuli_to_include_index= 1:length(stimuli_to_include_list)
    config.stimuli_to_include = stimuli_to_include_list{stimuli_to_include_index};

    proportion_of_trials_list = [1];
    for proportion_of_trials = proportion_of_trials_list
        config.proportion_of_trials = proportion_of_trials;

        cell_selection_scheme_list = {'all'};

        for cell_selection_scheme_index = 1:length(cell_selection_scheme_list)
            config.cell_selection_scheme = cell_selection_scheme_list{cell_selection_scheme_index};

            config.probe_index = [];
            if config.probe_index 
                disp(['Using only probe ' num2str(config.probe_index) '(' session.regions{probe_index}  ')'])
            end
            for paradigm_list_index = 1:length(config)
                paradigm_data = session.paradigms_data{config(paradigm_list_index).paradigm_index};

                %% Get stimuli
                [config,folder_name,peri_stimulus_range,unique_stimuli,unique_stimulus_index_other_list,unique_stimuli_is_high_repeat,unique_stimuli_is_red,unique_stimuli_is_cyan,red_cyan_pair_indices,number_of_features,xml_folder,xml_filename,feat_map,feat_map_stim_condition_stimulus,feat_map_stim_names,stimulus_index_in_range,priming_stimuli,dominant_image,suppressed_image,b_trial_in_range_is_proportion_priming,trial_is_binocular,b_trial_in_range_is_proportion,number_of_stimuli_total_list,number_of_stimuli_for_decoding_list]...
                    =flash_suppression_axes_get_stimuli(...
                    config,session,paradigm_data,flash_suppression_results);
                %% Compute features and responses
                [b_selected,features,responses_to_use_training,responses_to_use_testing,responses_st,responses_ot_stimulus,responses_priming,responses_dominant_binocular,responses_suppressed_binocular]...
                    = flash_suppression_axes_get_features_responses...
                    (config,session,paradigm_data,raster_state,unique_stimuli,unique_stimulus_index_other_list,number_of_features,feat_map,feat_map_stim_condition_stimulus,feat_map_stim_names,stimulus_index_in_range,priming_stimuli,dominant_image,suppressed_image,b_trial_in_range_is_proportion_priming,trial_is_binocular,b_trial_in_range_is_proportion);
                


                flash_suppression_results.axes.features=features;
                flash_suppression_results.axes.responses_to_use_training=responses_to_use_training;
                flash_suppression_results.axes.responses_to_use_testing=responses_to_use_testing;
                flash_suppression_results.axes.responses_st=responses_st;
                flash_suppression_results.axes.responses_ot_stimulus=responses_ot_stimulus;
                flash_suppression_results.axes.responses_priming=responses_priming;
                flash_suppression_results.axes.responses_dominant_binocular=responses_dominant_binocular;
                flash_suppression_results.axes.responses_suppressed_binocular=responses_suppressed_binocular;
                flash_suppression_results.axes.config = config;
                flash_suppression_results.axes.unique_stimuli = unique_stimuli;
                flash_suppression_results.axes.unique_stimuli_is_high_repeat = unique_stimuli_is_high_repeat;
                flash_suppression_results.axes.unique_stimulus_index_other_list = unique_stimulus_index_other_list;
                flash_suppression_results.axes.red_cyan_pair_indices = red_cyan_pair_indices;
                flash_suppression_results.axes.xml_folder=xml_folder;
                flash_suppression_results.axes.xml_filename=xml_filename;
                flash_suppression_results.axes.stimulus_list = paradigm_data.stimulus_list;
                flash_suppression_results.axes.priming_stimuli = priming_stimuli;
                flash_suppression_results.axes.number_of_stimuli_for_decoding_list = number_of_stimuli_for_decoding_list;
                flash_suppression_results.axes.fsi = session.face_vs_object(paradigm_data.paradigm_index_for_selectivity).fsi(b_selected);
                flash_suppression_results.axes.fsi_pvalue = session.face_vs_object(paradigm_data.paradigm_index_for_selectivity).p_value_face_vs_object(b_selected);
                flash_suppression_results.axes.p_value_visual_response = session.face_vs_object(paradigm_data.paradigm_index_for_selectivity).p_value_visual_response(b_selected);
                flash_suppression_results.axes.unit_probes_index = session.unit_probes_index(b_selected);
                flash_suppression_results.axes.unit_regions = session.regions(session.unit_probes_index(b_selected));
                flash_suppression_results.regions = session.regions;
                flash_suppression_results.axes.b_selected = b_selected;
                if isfield(config,'states_to_use') && ~isempty(config.states_to_use) % Set non-states to NaN
                    inference_schemes_index = find(strcmp({session.inference_schemes.name},config.states_to_use.inference_scheme));
                    if isfield(session.inference_results{config.paradigm_index,inference_schemes_index},'stim_index_abcd') && ~isempty(session.inference_results{config.paradigm_index,inference_schemes_index}.stim_index_abcd)
                        flash_suppression_results.axes.stim_index_abcd = session.inference_results{config.paradigm_index,inference_schemes_index}.stim_index_abcd;
                    end
                end
                %% Responses-only: per-session reconstruction / EV / decoding are NOT computed here.
                % The figure-time pooling (across_sessions_analysis_axes_aux) concatenates the
                % per-session response matrices into a cross-session pseudo-population and runs
                % PCA / OLS / explained-variance / reconstruction / decoding ONCE on the pool,
                % so doing it per session is redundant. We only save the response matrices and
                % stimulus/cell metadata above.

                %% Plotting (diagnostic plots disabled for the release -- not a main figure output)
                % flash_suppression_axes_plotting(...)

            end
        end





    end

end