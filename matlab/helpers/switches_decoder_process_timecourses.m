function [training_timecourse_processed, testing_timecourse_processed,decoding_scheme] = switches_decoder_process_timecourses(training_timecourse,testing_timecourse,decoding_scheme)
%% Select neurons
training_timecourse_processed = training_timecourse(:,decoding_scheme.b_selected_features);
if ~isempty(testing_timecourse)
    testing_timecourse_processed = testing_timecourse(:,decoding_scheme.b_selected_features);
else
    testing_timecourse_processed = testing_timecourse;
end

%% Smooth

training_timecourse_processed = smoothdata(training_timecourse_processed,1,'movmean',decoding_scheme.bin_size);
testing_timecourse_processed = smoothdata(testing_timecourse_processed,1,'movmean',decoding_scheme.bin_size);


%% Standardize
training_feature_matrix = training_timecourse_processed;
if decoding_scheme.b_standardize
    training_timecourse_processed = normalize_neurons(training_timecourse_processed,training_timecourse_processed,2,3);
    b_nan_neuron =any(isnan(training_timecourse_processed),1) | any(isinf(training_timecourse_processed),1);
    training_timecourse_processed(:,b_nan_neuron) = 0;
    if ~isempty(testing_timecourse_processed)
        testing_timecourse_processed = normalize_neurons(testing_timecourse_processed,training_timecourse_processed,2,3);
        testing_timecourse_processed(:,b_nan_neuron) = 0;
    end
else
    training_timecourse_processed = training_timecourse_processed;
    testing_timecourse_processed = testing_timecourse_processed;
end

%% PCA
if isfield(decoding_scheme,'number_of_dims') && ~isempty(decoding_scheme.number_of_dims)
    training_timecourse_processed_pca = [];
    testing_timecourse_processed_pca = [];
    probe_indices = unique(decoding_scheme.unit_probes_index);
    for probe_index = probe_indices

        [coeff, ~, ~, ~, explained] = pca(training_timecourse_processed(:,decoding_scheme.unit_probes_index==probe_index));
        training_timecourse_processed_pca= [training_timecourse_processed_pca, training_timecourse_processed(:,decoding_scheme.unit_probes_index==probe_index) * coeff(:,1:decoding_scheme.number_of_dims)];
        if testing_timecourse_processed
            testing_timecourse_processed_pca= [testing_timecourse_processed_pca, testing_timecourse_processed(:,decoding_scheme.unit_probes_index==probe_index) * coeff(:,1:decoding_scheme.number_of_dims)];
        end
    end
    training_timecourse_processed = training_timecourse_processed_pca;
    testing_timecourse_processed = testing_timecourse_processed_pca;
    decoding_scheme.unit_probes_index = repelem(probe_indices,decoding_scheme.number_of_dims); %or use probe_indices_to_analyze?
    decoding_scheme.b_selected_features = true(size(decoding_scheme.unit_probes_index));
    decoding_scheme.b_selected_neurons = true(size(decoding_scheme.unit_probes_index));
end
if decoding_scheme.b_use_single_resolution
    training_timecourse_processed = single(training_timecourse_processed);
    testing_timecourse_processed = single(testing_timecourse_processed);
end
end
