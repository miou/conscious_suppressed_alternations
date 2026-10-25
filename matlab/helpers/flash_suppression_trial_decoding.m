decoding_scheme.b_hyperparameter_optimization = false;
decoding_scheme.kfold = 8;
decoding_scheme.stratify = true;
decoding_scheme.learners = 'svm'; %Takes hours for 'svm'
for probe_index=-2:session.number_of_probes
    if probe_index ==-2
        probe_string = 'PFC';
        b_selected_neurons = ismember(session.regions(session.unit_probes_index),{'PO','PVL'}); %All
    elseif probe_index ==-1
        probe_string = 'IT';
        b_selected_neurons = ismember(session.regions(session.unit_probes_index),{'ML','AM'}); %All
    elseif probe_index ==0
        probe_string = 'all';
        b_selected_neurons = true(size(session.unit_probes_index)); %All

    else
        probe_string = session.regions{probe_index};
        b_selected_neurons = session.unit_probes_index == probe_index; %AM
    end

    %For inference schemes that only use half of the neurons, use the other
    %neurons for computing axes.
    if isfield(config,'states_to_use') && ~isempty(config.states_to_use)
        inference_schemes_index = find(strcmp({session.inference_schemes.name},config.states_to_use.inference_scheme));
        if isfield(session.inference_results{paradigm_index,inference_schemes_index},'selected_indices_for_state_inference')
            b_neuron_is_not_for_state_inference = (~ismember(1:length(b_selected_neurons),session.inference_results{paradigm_index,inference_schemes_index}.selected_indices_for_state_inference));
            b_selected_neurons = b_selected_neurons & b_neuron_is_not_for_state_inference;
            flash_suppression_results.b_neuron_is_not_for_state_inference = b_neuron_is_not_for_state_inference;
        end
    end


    if any(b_selected_neurons)

        if isfield(config,'states_to_use') && ~isempty(config.states_to_use)
            states_string =[filesep 'states_' config.states_to_use.inference_scheme '_' num2str(config.states_to_use.state_value) '_' num2str(config.states_to_use.only_apply_to_testing) '_avgdim_' num2str(config.avg_first_dimension) filesep];
        else
            states_string ='';
        end

        trial_context_name = 'priming';
        get_context_trial_labels
        start_index = find(peri_stimulus_range == config.time_window_priming(1));
        end_index = find(peri_stimulus_range == config.time_window_priming(end));
        training_feature_matrix = squeeze(nanmean(raster(trial_is_context,start_index:end_index,b_selected_neurons),2));
        training_label_vector = double(categorical(context_trial_labels_dominant,labels_list));

        % Train the decoder ONCE on priming. The training set is identical across all test
        % windows/contexts below, so reuse mdl.predict rather than retraining each window.
        % This is numerically identical to calling switches_decoder_aux with test data each
        % time (its test path is exactly fitcecoc once + predict), but ~1000x fewer trainings.
        % Coding/learners match switches_decoder_aux's test path ('onevsall', svm).
        mdl_trained = fitcecoc(training_feature_matrix,training_label_vector,'Coding','onevsall','Learners',decoding_scheme.learners);

        trial_context_list = {'unambiguous','binocular','transparent'};

        binocular_duration = median(on_durations_in_range(trial_is_binocular));

        time_window_length = 200;
        time_window_starts = [-200:10:(peri_stimulus_range(end) - time_window_length)];

        for trial_context_index = 1:length(trial_context_list)
            trial_context_name = trial_context_list{trial_context_index};
            get_context_trial_labels;

            decoding_accuracy_testing_dominant.(trial_context_name) = nan(1,length(time_window_starts));
            decoding_accuracy_testing_suppressed.(trial_context_name) = nan(1,length(time_window_starts));
            decoding_accuracy_testing_dominant_state.(trial_context_name) = nan(1,length(time_window_starts));
            decoding_accuracy_testing_suppressed_state.(trial_context_name) = nan(1,length(time_window_starts));

            for time_window_index = 1:length(time_window_starts)
                start_index = find(peri_stimulus_range == time_window_starts(time_window_index));
                end_index = find(peri_stimulus_range == (time_window_starts(time_window_index)+time_window_length));


                testing_label_vector_dominant = double(categorical(context_trial_labels_dominant,labels_list));
                testing_label_vector_suppressed = double(categorical(context_trial_labels_suppressed,labels_list));
                testing_feature_matrix = squeeze(nanmean(raster(trial_is_context,start_index:end_index,b_selected_neurons),2));
                pred = mdl_trained.predict(testing_feature_matrix);   % one trained model, reused
                decoding_accuracy_testing_dominant.(trial_context_name)(time_window_index) = mean(pred(:)==testing_label_vector_dominant(:));
                decoding_accuracy_testing_suppressed.(trial_context_name)(time_window_index) = mean(pred(:)==testing_label_vector_suppressed(:));

                testing_feature_matrix_state = squeeze(nanmean(raster_state(trial_is_context,start_index:end_index,b_selected_neurons),2));
                nan_rows = all(isnan(testing_feature_matrix_state),2);
                if ~all(nan_rows)
                pred_state = mdl_trained.predict(testing_feature_matrix_state(~nan_rows,:));
                dom = testing_label_vector_dominant(~nan_rows); sup = testing_label_vector_suppressed(~nan_rows);
                decoding_accuracy_testing_dominant_state.(trial_context_name)(time_window_index) = mean(pred_state(:)==dom(:));
                decoding_accuracy_testing_suppressed_state.(trial_context_name)(time_window_index) = mean(pred_state(:)==sup(:));
                end
            end
            start_index = find(peri_stimulus_range == trial_time_window(1));
            end_index = find(peri_stimulus_range == (trial_time_window(end)));


            testing_label_vector_dominant = double(categorical(context_trial_labels_dominant,labels_list));
            testing_label_vector_suppressed = double(categorical(context_trial_labels_suppressed,labels_list));
            testing_feature_matrix = squeeze(nanmean(raster(trial_is_context,start_index:end_index,b_selected_neurons),2));
            pred = mdl_trained.predict(testing_feature_matrix);
            decoding_accuracy_testing_dominant_full_trial.(trial_context_name) = mean(pred(:)==testing_label_vector_dominant(:));
            decoding_accuracy_testing_suppressed_full_trial.(trial_context_name) = mean(pred(:)==testing_label_vector_suppressed(:));

            testing_feature_matrix_state = squeeze(nanmean(raster_state(trial_is_context,start_index:end_index,b_selected_neurons),2));
            nan_rows = all(isnan(testing_feature_matrix_state),2);
            pred_state = mdl_trained.predict(testing_feature_matrix_state(~nan_rows,:));
            dom = testing_label_vector_dominant(~nan_rows); sup = testing_label_vector_suppressed(~nan_rows);
            decoding_accuracy_testing_dominant_state_full_trial.(trial_context_name) = mean(pred_state(:)==dom(:));
            decoding_accuracy_testing_suppressed_state_full_trial.(trial_context_name) = mean(pred_state(:)==sup(:));

        end
        % (per-session debug PNGs of the time-resolved decoding curves were written here;
        % removed for the release -- the paper panels are produced by generate_fig_2/3/6.)

        flash_suppression_results.time_window_starts = time_window_starts;
        flash_suppression_results.time_window_length = time_window_length;

        flash_suppression_results.trial_decoding.(probe_string).decoding_accuracy_testing_dominant = decoding_accuracy_testing_dominant;
        flash_suppression_results.trial_decoding.(probe_string).decoding_accuracy_testing_suppressed = decoding_accuracy_testing_suppressed;
        flash_suppression_results.trial_decoding.(probe_string).decoding_accuracy_testing_dominant_state = decoding_accuracy_testing_dominant_state;
        flash_suppression_results.trial_decoding.(probe_string).decoding_accuracy_testing_suppressed_state = decoding_accuracy_testing_suppressed_state;

        flash_suppression_results.trial_decoding.(probe_string).decoding_accuracy_testing_dominant_full_trial = decoding_accuracy_testing_dominant_full_trial;
        flash_suppression_results.trial_decoding.(probe_string).decoding_accuracy_testing_suppressed_full_trial = decoding_accuracy_testing_suppressed_full_trial;
        flash_suppression_results.trial_decoding.(probe_string).decoding_accuracy_testing_dominant_state_full_trial = decoding_accuracy_testing_dominant_state_full_trial;
        flash_suppression_results.trial_decoding.(probe_string).decoding_accuracy_testing_suppressed_state_full_trial = decoding_accuracy_testing_suppressed_state_full_trial;
    end

end