%% Pool responses across sessions
responses_to_use_training=[];
responses_to_use_testing=[];
responses_st=[];
responses_ot_stimulus=[];
responses_priming=[];
responses_dominant_binocular=[];
responses_suppressed_binocular=[];

    session_names_all = cell(size(flash_suppression_results_all_sessions));
    session_names_not_empty = {};
for session_index_across_sessions = 1:length(flash_suppression_results_all_sessions)
    if ~isempty(flash_suppression_results_all_sessions{session_index_across_sessions}) && isfield(flash_suppression_results_all_sessions{session_index_across_sessions},'axes') && (isempty(monkeys_to_include) || contains(flash_suppression_results_all_sessions{session_index_across_sessions}.session_name,monkeys_to_include))
        session_names_all{session_index_across_sessions} = flash_suppression_results_all_sessions{session_index_across_sessions}.session_name;
        session_names_not_empty = [session_names_not_empty {flash_suppression_results_all_sessions{session_index_across_sessions}.session_name}];
        flash_suppression_results = flash_suppression_results_all_sessions{session_index_across_sessions};
        config = flash_suppression_results.axes.config;
        if length(session_names_not_empty)>1
            assert(isequal(flash_suppression_results.axes.features(summary_config.stimuli_to_include,1:64),features(:,1:64))) %Somehow the features after 64 diverge?
            assert(isequal(flash_suppression_results.axes.unique_stimuli(summary_config.stimuli_to_include),unique_stimuli))
        end

        features = flash_suppression_results.axes.features(summary_config.stimuli_to_include,:);
        unique_stimuli = flash_suppression_results.axes.unique_stimuli(summary_config.stimuli_to_include);
        unique_stimuli_is_high_repeat = flash_suppression_results.axes.unique_stimuli_is_high_repeat(summary_config.stimuli_to_include);
        unique_stimulus_index_other_list = flash_suppression_results.axes.unique_stimulus_index_other_list(summary_config.stimuli_to_include);
        red_cyan_pair_indices = flash_suppression_results.axes.red_cyan_pair_indices;
        number_of_stimuli_total_list = length(unique_stimuli);
        number_of_stimuli_for_decoding_list = flash_suppression_results.axes.number_of_stimuli_for_decoding_list;

        if isfield(flash_suppression_results.axes,'stim_index_abcd')
            if isfield(config,'stim_index_abcd')
                assert(all(all(flash_suppression_results.axes.stim_index_abcd == config.stim_index_abcd)))
            end
            config.stim_index_abcd = flash_suppression_results.axes.stim_index_abcd;
        end


        switch summary_config.cell_selection_scheme
            case 'all'
                b_selected = true(1,size(flash_suppression_results.axes.responses_to_use_training,2));
            case 'visual_cells'
                b_selected = flash_suppression_results.axes.p_value_visual_response<0.05;
            case 'face_cells'
                b_selected = flash_suppression_results.axes.fsi>0 & flash_suppression_results.axes.fsi_pvalue<0.05;
            case 'MI_correlation'
                b_selected = flash_suppression_results.correlation_priming_binocular_p_value'<0.05;
            case 'explained_variance_cv_high_repeat'
                b_selected = flash_suppression_results.axes.explained_variance_responses_cv_high_repeat'>0;
        end
        if ~isempty(regions_to_include)
            b_selected = b_selected &  ismember(flash_suppression_results.axes.unit_regions,regions_to_include);
        end
        if  isfield(summary_config,'cell_proportion')
            b_selected = b_selected & (rand(size(b_selected))<summary_config.cell_proportion);
        end

        disp([flash_suppression_results.session_name ': ' num2str(sum(b_selected)) ' selected cells.'])
        %Concatenate responses
        responses_to_use_training=[responses_to_use_training, flash_suppression_results.axes.responses_to_use_training(summary_config.stimuli_to_include,b_selected)];
        responses_to_use_testing=[responses_to_use_testing, flash_suppression_results.axes.responses_to_use_testing(summary_config.stimuli_to_include,b_selected)];
        responses_st=[responses_st, flash_suppression_results.axes.responses_st(summary_config.stimuli_to_include,b_selected)];
        responses_ot_stimulus=[responses_ot_stimulus, flash_suppression_results.axes.responses_ot_stimulus(summary_config.stimuli_to_include,b_selected)];
        responses_priming=[responses_priming, flash_suppression_results.axes.responses_priming(summary_config.stimuli_to_include,b_selected)];
        responses_dominant_binocular=[responses_dominant_binocular, flash_suppression_results.axes.responses_dominant_binocular(summary_config.stimuli_to_include,b_selected)];
        responses_suppressed_binocular=[responses_suppressed_binocular, flash_suppression_results.axes.responses_suppressed_binocular(summary_config.stimuli_to_include,b_selected)];

    end
end

%Set defaults for old session summaries
if ~isfield(config,'balance_states_each_trial')
    config.balance_states_each_trial = false;
end
if ~isfield(config,'minimum_state_proportion_per_trial')
    config.minimum_state_proportion_per_trial = [];
end
if ~isfield(config,'avg_first_dimension')
    config.avg_first_dimension = 1; %Old default
end

if ~isempty(summary_config.b_use_control_1_stimuli)
    config.b_use_control_1_stimuli = summary_config.b_use_control_1_stimuli;
end

if config.balance_states_each_trial %Fix NaNs (mmissing entries) by setting to mean response
    avg_responses_neurons = nanmean(responses_to_use_testing,1);
    for cell_index=1:size(responses_to_use_testing,2)
        responses_to_use_testing(isnan(responses_to_use_testing(:,cell_index)),cell_index) = avg_responses_neurons(cell_index);
    end
end

if isfield(summary_config,'remove_other_stimulus_from_training') 
    config.remove_other_stimulus_from_training = summary_config.remove_other_stimulus_from_training; %Overwrite
end
%% Constrain number of cells or do PCA
if summary_config.number_of_pcs %Use PCA
    [coeff, score_train, latent, tsquared, explained, mu] = pca(responses_to_use_training);

    responses_to_use_training = (responses_to_use_training - mu)* coeff(:,1:summary_config.number_of_pcs);
    responses_to_use_testing = (responses_to_use_testing - mu)* coeff(:,1:summary_config.number_of_pcs);
    responses_st = (responses_st - mu)* coeff(:,1:summary_config.number_of_pcs);
    responses_ot_stimulus = (responses_ot_stimulus - mu)* coeff(:,1:summary_config.number_of_pcs);
    responses_priming = (responses_priming - mu)* coeff(:,1:summary_config.number_of_pcs);
    responses_dominant_binocular = (responses_dominant_binocular - mu)* coeff(:,1:summary_config.number_of_pcs);
    responses_suppressed_binocular = (responses_suppressed_binocular - mu)* coeff(:,1:summary_config.number_of_pcs);

elseif summary_config.number_of_cells_to_select %Use number of cells
    selected_cell_indices = shuffle_array(1:size(responses_to_use_training,2));
    selected_cell_indices_constrained = selected_cell_indices(1:summary_config.number_of_cells_to_select);
    responses_to_use_training=responses_to_use_training(:,selected_cell_indices_constrained);
    responses_to_use_testing=responses_to_use_testing(:,selected_cell_indices_constrained);
    responses_st=responses_st(:,selected_cell_indices_constrained);
    responses_ot_stimulus=responses_ot_stimulus(:,selected_cell_indices_constrained);
    responses_priming=responses_priming(:,selected_cell_indices_constrained);
    responses_dominant_binocular=responses_dominant_binocular(:,selected_cell_indices_constrained);
    responses_suppressed_binocular=responses_suppressed_binocular(:,selected_cell_indices_constrained);
end


%% Compute weights and predict responses
[weights_predicting_features,weights_predicting_responses,predicted_features,predicted_features_cv,predicted_features_st,predicted_features_st_loto,predicted_responses,predicted_responses_cv] = flash_suppression_axes_predict_responses(config,features,responses_to_use_training,responses_to_use_testing,responses_st,responses_ot_stimulus,unique_stimulus_index_other_list);
